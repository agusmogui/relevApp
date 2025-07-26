import 'package:supabase_flutter/supabase_flutter.dart';

class PendientesService {
  final SupabaseClient supabase = Supabase.instance.client;

  // 🔹 Obtener relevamientos por empresa + firma del encargado + descripción del formulario
  Future<List<Map<String, dynamic>>> obtenerRelevamientosDeEmpresa(int idEmpresa) async {
    try {
      final data = await supabase
          .from('relevamientos')
          .select('*, formularios (descripcion)')
          .eq('id_empresa', idEmpresa);

      List<Map<String, dynamic>> relevamientos = List<Map<String, dynamic>>.from(data);

      for (var relevamiento in relevamientos) {
        // Agregar descripción del formulario de forma plana
        final descripcionFormulario = relevamiento['formularios']?['descripcion'] ?? 'Sin descripción';
        relevamiento['descripcion_formulario'] = descripcionFormulario;
        relevamiento.remove('formularios'); // opcional: para no tener estructura anidada innecesaria

        // Agregar firma
        final firma = await obtenerFirmaEncargado(relevamiento['id_relevamiento']);
        relevamiento['firma_encargado'] = firma?['url_firma']; // puede ser null
      }

      return relevamientos;
    } catch (e) {
      print('⛔ Error al obtener relevamientos pendientes: $e');
      return [];
    }
  }

  // 🔹 Obtener firma del encargado según el relevamiento
  Future<Map<String, dynamic>?> obtenerFirmaEncargado(int idRelevamiento) async {
    try {
      final data = await supabase
          .from('firmas')
          .select()
          .eq('id_relevamiento', idRelevamiento)
          .maybeSingle();

      return data;
    } catch (e) {
      print('⛔ Error al obtener firma del encargado: $e');
      return null;
    }
  }

  // 🔹 Obtener tanques + detalles + fotos
  Future<List<Map<String, dynamic>>> obtenerTanquesConDetalles(int idRelevamiento) async {
    try {
      final tanques = await supabase
          .from('tanques')
          .select()
          .eq('id_relevamiento', idRelevamiento);

      final List<Map<String, dynamic>> resultado = [];

      for (final tanque in tanques) {
        final tanqueMapeado = await _mapearTanque(tanque);
        resultado.add(tanqueMapeado);
      }

      return resultado;
    } catch (e) {
      print('⛔ Error al obtener tanques con detalles: $e');
      return [];
    }
  }

  // 🔹 Obtener todo el relevamiento completo con tanques y firma
  Future<Map<String, dynamic>?> obtenerRelevamientoCompleto(int idRelevamiento) async {
    try {
      final relevamiento = await supabase
          .from('relevamientos')
          .select()
          .eq('id_relevamiento', idRelevamiento)
          .maybeSingle();

      if (relevamiento == null) return null;

      final firma = await obtenerFirmaEncargado(idRelevamiento);
      relevamiento['firma_encargado'] = firma?['url_firma'];

      final tanques = await supabase
          .from('tanques')
          .select()
          .eq('id_relevamiento', idRelevamiento);

      final List<Map<String, dynamic>> listaTanques = [];

      for (final tanque in tanques) {
        final tanqueMapeado = await _mapearTanque(tanque);
        listaTanques.add(tanqueMapeado);
      }

      relevamiento['tanques'] = listaTanques;
      return relevamiento;
    } catch (e) {
      print('⛔ Error al obtener relevamiento completo: $e');
      return null;
    }
  }

  // 🔹 Función interna para mapear un tanque completo
  Future<Map<String, dynamic>> _mapearTanque(Map<String, dynamic> tanque) async {
    final String tipoTanque = tanque['tipo_tanque'];
    final String tipoEstructura = tanque['tipo_estructura'];
    final int idDetalle = tanque['id_formulario_detalle'];

    String? tabla;
    if (tipoEstructura == 'cilindrico') {
      tabla = 'tanque_cilindrico';
    } else if (tipoEstructura == 'concreto' && tipoTanque == 'cisterna') {
      tabla = 'cisterna_concreto';
    } else if (tipoEstructura == 'concreto' && tipoTanque == 'reserva') {
      tabla = 'reserva_concreto';
    } else {
      print('⛔ Tipo no reconocido: $tipoTanque / $tipoEstructura');
      return {};
    }

    final detalle = await supabase
        .from(tabla)
        .select()
        .eq('id_detalle', idDetalle)
        .maybeSingle();

    final fotos = await supabase
        .from('fotos')
        .select()
        .eq('id_tanque', tanque['id_tanque']);

    final Map<String, List<String>> fotosPorCampo = {};
    for (final foto in fotos) {
      final String campo = foto['campo_asociado'] ?? 'desconocido';
      final String? url = foto['url_foto'];
      if (url != null) {
        fotosPorCampo.putIfAbsent(campo, () => []).add(url);
      }
    }

    return {
      'id_tanque': tanque['id_tanque'],
      'tipo_tanque': tipoTanque,
      'tipo_estructura': tipoEstructura,
      'detalle': detalle,
      'fotos_por_campo': fotosPorCampo,
    };
  }

  static Map<String, dynamic> transformarRelevamientoAFormulario(Map<String, dynamic> relevamiento) {
    final Map<String, dynamic> datos = {};

    // Datos generales
    datos['direccion'] = relevamiento['direccion'];
    datos['tecnico'] = relevamiento['tecnico'];
    datos['encargado'] = relevamiento['encargado'];
    datos['administracion'] = relevamiento['administracion'];
    datos['contacto'] = relevamiento['contacto'];

    final tanques = relevamiento['tanques'] as List;

    for (final tanque in tanques) {
      final tipo = tanque['tipo_tanque'];             // 'cisterna' o 'reserva'
      final estructura = tanque['tipo_estructura'];   // 'cilindrico' o 'concreto'
      final detalle = tanque['detalle'] as Map<String, dynamic>;
      final fotos = tanque['fotos_por_campo'] as Map<String, dynamic>;

      String prefijo;
      if (tipo == 'cisterna') {
        prefijo = 'cisterna';
        datos['tipo_cisterna'] = estructura;
      } else if (tipo == 'reserva') {
        prefijo = 'reserva';
        datos['tipo_reserva'] = estructura;
      } else {
        continue; // salta si es un tipo desconocido
      }

      // Agregar detalles con prefijo
      detalle.forEach((clave, valor) {
        datos['${prefijo}_$clave'] = valor;
      });

      // Agregar fotos con prefijo
      fotos.forEach((campo, urls) {
        datos['${prefijo}_$campo'] = List<String>.from(urls);
      });
    }

    return datos;
  }

}
