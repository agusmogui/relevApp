import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> insertarTanque({
    required int idRelevamiento,
    required int idDetalle,
    required String tipoTanque,
    required String keyTipoEstructura, // 'tipo_cisterna' o 'tipo_reserva'
  }) async {
    try {
      final data = {
        'id_relevamiento': idRelevamiento,
        'tipo_tanque': tipoTanque,
        'tipo_estructura': formulario[keyTipoEstructura],
        'id_formulario_detalle': idDetalle,
      };

      await supabase.from('tanques').insert(data);
    } catch (e) {
      print('Error insertando tanque: $e');
    }
  }
}
