import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class TanqueAguaService {
  final Map<String, dynamic> formulario;
  final SupabaseClient supabase = Supabase.instance.client;

  TanqueAguaService(this.formulario);

  Future<int?> insertarRelevamiento() async {
    try {
      final Map<String, dynamic> relevamientoMap = {
        'id_formulario': 1,
        'encargado': formulario['encargado'],
        'administracion': formulario['administracion'],
        'direccion': formulario['direccion'],
        'contacto': formulario['contacto'],
        'tecnico':formulario['tecnico'],
        'id_empresa': formulario['id_empresa']
      };

      final response = await supabase
          .from('relevamientos')
          .insert(relevamientoMap)
          .select('id_relevamiento')
          .single();

      return response['id_relevamiento'] as int;
    } catch (e) {
      print('Error insertando relevamiento: $e');
      return null;
    }
  }

  Future<int?> insertarDetalleCisterna() async {
    try {
      final String tipoCisterna = formulario['tipo_cisterna'];

      if (tipoCisterna == 'cilindrico') {
        final data = {
          'cantidad': formulario['cisterna_cantidad'],
          'litros': formulario['cisterna_litros'],
          'observaciones': formulario['cisterna_observaciones'],
        };

        final response = await supabase
            .from('tanque_cilindrico')
            .insert(data)
            .select('id_detalle')
            .single();

        return response['id_detalle'] as int;
      } else if (tipoCisterna == 'concreto') {
        final data = {
          'largo': formulario['cisterna_largo'],
          'ancho': formulario['cisterna_ancho'],
          'alto': formulario['cisterna_alto'],
          'medida_flotante': formulario['cisterna_medida_flotante'],
          'pozo_achique': formulario['cisterna_pozo_achique'],
          'bomba_achique': formulario['cisterna_bomba_achique'],
          'llave_cierre': formulario['cisterna_llave_cierre'],
          'observaciones': formulario['cisterna_observaciones'],
        };

        final response = await supabase
            .from('cisterna_concreto')
            .insert(data)
            .select('id_detalle')
            .single();

        return response['id_detalle'] as int;
      } else {
        print('Tipo de cisterna no reconocido');
        return null;
      }
    } catch (e) {
      print('Error insertando detalle de cisterna: $e');
      return null;
    }
  }

  Future<int?> insertarDetalleReserva() async {
    try {
      final String tipoReserva = formulario['tipo_reserva'];

      if (tipoReserva == 'cilindrico') {
        final data = {
          'cantidad': formulario['reserva_cantidad'],
          'litros': formulario['reserva_litros'],
          'observaciones': formulario['reserva_observaciones'],
        };

        final response = await supabase
            .from('tanque_cilindrico')
            .insert(data)
            .select('id_detalle')
            .single();

        return response['id_detalle'] as int;
      } else if (tipoReserva == 'concreto') {
        final data = {
          'largo': formulario['reserva_largo'],
          'ancho': formulario['reserva_ancho'],
          'alto': formulario['reserva_alto'],
          'automatico': formulario['reserva_automaticos'],
          'observaciones': formulario['reserva_observaciones'],
        };

        final response = await supabase
            .from('reserva_concreto')
            .insert(data)
            .select('id_detalle')
            .single();

        return response['id_detalle'] as int;
      } else {
        print('Tipo de reserva no reconocido');
        return null;
      }
    } catch (e) {
      print('Error insertando detalle de reserva: $e');
      return null;
    }
  }

  Future<int?> insertarTanque({
    required int idRelevamiento,
    int? idDetalle,
    required String tipoTanque, // 'cisterna' o 'reserva'
    required String keyTipoEstructura, // 'tipo_cisterna' o 'tipo_reserva'
  }) async {
    try {
      final data = {
        'id_relevamiento': idRelevamiento,
        'tipo_tanque': tipoTanque,
        'tipo_estructura': formulario[keyTipoEstructura],
        if (idDetalle != null) 'id_formulario_detalle': idDetalle,
      };

      final response = await supabase
          .from('tanques')
          .insert(data)
          .select('id_tanque')
          .single();

      return response['id_tanque'] as int;
    } catch (e) {
      print('⛔ Error insertando tanque: $e');
      return null;
    }
  }


  Future<void> subirFotosDeCampo({
    required List<XFile> fotos,
    required String campoAsociado,
    required int idTanque,
  }) async {
    final storage = Supabase.instance.client.storage;
    final bucket = storage.from('tanques');

    for (final foto in fotos) {
      try {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${foto.name}';
        final String storagePath = '$idTanque/$fileName';

        await bucket.upload(storagePath, File(foto.path));

        final String urlPublica = bucket.getPublicUrl(storagePath);

        final Map<String, dynamic> fotoMap = {
          'id_tanque': idTanque,
          'campo_asociado': campoAsociado,
          'url_foto': urlPublica,
        };

        await supabase.from('fotos').insert(fotoMap);
        print('📤 Subiendo ${fotos.length} fotos para campo: "$campoAsociado", idTanque: $idTanque');
      } catch (e) {
        print('Error subiendo foto "$campoAsociado": $e');
      }
    }
    print('✅ Subida de fotos completada para "$campoAsociado".');
  }
  
  Future<void> subirFirmaDeRelevamiento({
  required int idRelevamiento,
  required String pathLocalFirma,
}) async {
  final storage = Supabase.instance.client.storage.from('firmas');
  print('🟢 Llamando a subirFirmaDeRelevamiento...');


  try {
    print('🖼️ Path de firma recibido: $pathLocalFirma');
    final file = File(pathLocalFirma);

    if (!file.existsSync()) {
      print('⛔ El archivo de firma no existe en el path proporcionado.');
      return;
    }

    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_firma.png';
    final String storagePath = '$idRelevamiento/$fileName';
    print('📂 Ruta de storage generada: $storagePath');

    // Subir la firma al bucket
    await storage.upload(storagePath, file);
    print('✅ Firma subida al bucket correctamente');

    // Obtener URL pública
    final String url = storage.getPublicUrl(storagePath);
    print('🌐 URL pública de firma: $url');

    // Validaciones previas al insert
    if (url.isEmpty) {
      print('⚠️ URL vacía. No se puede insertar la firma.');
      return;
    }

    if (idRelevamiento == 0) {
      print('⚠️ ID de relevamiento inválido (0). No se insertará.');
      return;
    }

    // Insertar en la tabla firmas
    print('📥 Insertando firma en la tabla "firmas"...');
    await Supabase.instance.client.from('firmas').insert({
      'id_relevamiento': idRelevamiento,
      'url_firma': url,
    });
    print('✅ Firma insertada en tabla correctamente');

  } catch (e) {
    print('⛔ Error subiendo o insertando firma: $e');
    rethrow;
  }
}

  Future<void> cargarRelevamientoCompleto() async {
    // Paso 1: Insertar relevamiento general
    final idRelevamiento = await insertarRelevamiento();
    if (idRelevamiento == null) return;

    // === CISTERNA ===
    int? idDetalleCisterna;
    if (formulario['tipo_cisterna'] != 'no_tiene') {
      idDetalleCisterna = await insertarDetalleCisterna();
      if (idDetalleCisterna == null) return;
    }

    final idTanqueCisterna = await insertarTanque(
      idRelevamiento: idRelevamiento,
      idDetalle: idDetalleCisterna,
      tipoTanque: 'cisterna',
      keyTipoEstructura: 'tipo_cisterna',
    );
    if (idTanqueCisterna == null) return;

    final camposCisterna = [
      'cisterna_fotos_estado',
      'cisterna_fotos_colectora',
      'cisterna_marco_tapa_lateral',
      'cisterna_tapa_inspeccion',
      'cisterna_estado_paredes',
      'cisterna_colectora',
    ];

    for (final campo in camposCisterna) {
      final fotosRaw = formulario[campo];
      if (fotosRaw != null) {
        List<XFile> fotos = [];

        if (fotosRaw is List<String>) {
          fotos = fotosRaw.map((e) => XFile(e)).toList();
        } else if (fotosRaw is List<XFile>) {
          fotos = fotosRaw;
        }

        if (fotos.isNotEmpty) {
          print('subiendo foto de "$campo"...');
          await subirFotosDeCampo(
            fotos: fotos,
            campoAsociado: campo,
            idTanque: idTanqueCisterna,
          );
        }
      }
    }

    // === RESERVA ===
    int? idDetalleReserva;
    if (formulario['tipo_reserva'] != 'no_tiene') {
      idDetalleReserva = await insertarDetalleReserva();
      if (idDetalleReserva == null) return;
    }

    final idTanqueReserva = await insertarTanque(
      idRelevamiento: idRelevamiento,
      idDetalle: idDetalleReserva,
      tipoTanque: 'reserva',
      keyTipoEstructura: 'tipo_reserva',
    );
    if (idTanqueReserva == null) return;

    final camposReserva = [
      'reserva_fotos_estado',
      'reserva_fotos_colectora',
      'reserva_marco_tapa_primaria',
      'reserva_marco_tapa_secundaria',
      'reserva_tapa_inspeccion',
      'reserva_estado_paredes',
      'reserva_colectora',
    ];

    for (final campo in camposReserva) {
      final fotosRaw = formulario[campo];
      if (fotosRaw != null) {
        List<XFile> fotos = [];

        if (fotosRaw is List<String>) {
          fotos = fotosRaw.map((e) => XFile(e)).toList();
        } else if (fotosRaw is List<XFile>) {
          fotos = fotosRaw;
        }

        if (fotos.isNotEmpty) {
          print('subiendo foto de "$campo"...');
          await subirFotosDeCampo(
            fotos: fotos,
            campoAsociado: campo,
            idTanque: idTanqueReserva,
          );
        }
      }
    }

    // === FIRMA ===
    final pathFirma = formulario['url_firma'];
    print(pathFirma);
    if (pathFirma != null && pathFirma is String && pathFirma.isNotEmpty) {
      await subirFirmaDeRelevamiento(
        idRelevamiento: idRelevamiento,
        pathLocalFirma: pathFirma,
      );
    }

    print('✅ Relevamiento completo cargado con éxito.');
  }

Future<void> actualizarRelevamiento(Map<String, dynamic> datos) async {
  final supabase = Supabase.instance.client;

  if (datos['id_relevamiento'] == null) {
    throw Exception('El id_relevamiento es null y es necesario para actualizar');
  }

  try {
    final int idRelevamiento = datos['id_relevamiento'];

    // 🟠 1. Actualizar datos generales del relevamiento
    final mapaGenerico = {
      'direccion': datos['direccion'],
      'encargado': datos['encargado'],
      'administracion': datos['administracion'],
      'contacto': datos['contacto'],
      'tecnico': datos['tecnico'],
    };

    await supabase
        .from('relevamientos')
        .update(mapaGenerico)
        .eq('id_relevamiento', idRelevamiento);

    // 🟠 2. Obtener tanques relacionados
    final tanques = await supabase
        .from('tanques')
        .select()
        .eq('id_relevamiento', idRelevamiento);

    print('🔎 Tanques obtenidos: $tanques');

    for (final tanque in tanques) {
      final tipoTanque = tanque['tipo_tanque']; // 'cisterna' o 'reserva'
      final tipoEstructura = tanque['tipo_estructura']; // 'cilindrico', 'concreto', etc.

      if (tipoEstructura == 'no_tiene' || tanque['id_formulario_detalle'] == null) {
        print('⏩ Ignorando tanque sin estructura o sin id_formulario_detalle: $tipoTanque');
        continue;
      }

      final int idTanque = tanque['id_tanque'];
      final int idDetalle = tanque['id_formulario_detalle'];

      // 🟠 3. Actualizar datos del formulario correspondiente
      Map<String, dynamic> detalleMap = {};
      String tablaDetalle = '';

      if (tipoEstructura == 'cilindrico') {
        tablaDetalle = 'tanque_cilindrico';
        detalleMap = {
          'cantidad': datos['${tipoTanque}_cantidad'],
          'litros': datos['${tipoTanque}_litros'],
          'observaciones': datos['${tipoTanque}_observaciones'],
        };
      } else if (tipoEstructura == 'concreto') {
        tablaDetalle = tipoTanque == 'cisterna' ? 'cisterna_concreto' : 'reserva_concreto';
        detalleMap = {
          'largo': datos['${tipoTanque}_largo'],
          'ancho': datos['${tipoTanque}_ancho'],
          'alto': datos['${tipoTanque}_alto'],
          'observaciones': datos['${tipoTanque}_observaciones'],
        };

        if (tipoTanque == 'cisterna') {
          detalleMap.addAll({
            'medida_flotante': datos['${tipoTanque}_medida_flotante'],
            'pozo_achique': datos['${tipoTanque}_pozo_achique'],
            'bomba_achique': datos['${tipoTanque}_bomba_achique'],
            'llave_cierre': datos['${tipoTanque}_llave_cierre'],
          });
        } else if (tipoTanque == 'reserva') {
          detalleMap.addAll({
            'automatico': datos['${tipoTanque}_automatico'],
          });
        }
      }

      if (tablaDetalle.isNotEmpty) {
        await supabase.from(tablaDetalle).update(detalleMap).eq('id_detalle', idDetalle);
      }

      // 🟠 4. Eliminar fotos del tanque UNA SOLA VEZ
      await eliminarFotosDeTanque(idTanque);

      // 🟠 5. Subir nuevas fotos por campo usando función reutilizable
      for (final entry in datos.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key.startsWith('${tipoTanque}_')) {
          List<XFile> fotos = [];

          if (value is List<String>) {
            fotos = value.map((e) => XFile(e)).toList();
          } else if (value is List<XFile>) {
            fotos = value;
          }

          if (fotos.isNotEmpty) {
            await subirFotosDeCampo(
              fotos: fotos,
              campoAsociado: key,
              idTanque: idTanque,
            );
          }
        }
      }
    }
  } catch (e) {
    print('⚠️ Error actualizando relevamiento: $e');
    rethrow;
  }
}


Future<void> eliminarFotosDeTanque(int idTanque) async {
  final supabase = Supabase.instance.client;

  try {
    final fotos = await supabase
        .from('fotos')
        .select()
        .eq('id_tanque', idTanque);

    if (fotos.isEmpty) return;

    final List<String> paths = fotos.map<String>((foto) {
      final url = foto['url_foto'] as String;
      final bucketName = 'tanques';
      return url.split('$bucketName/').last;
    }).toList();

    await supabase.storage.from('tanques').remove(paths);
    await supabase.from('fotos').delete().eq('id_tanque', idTanque);

    print('🗑️ Fotos eliminadas para tanque $idTanque');
  } catch (e) {
    print('⚠️ Error eliminando fotos del tanque $idTanque: $e');
  }
}
}