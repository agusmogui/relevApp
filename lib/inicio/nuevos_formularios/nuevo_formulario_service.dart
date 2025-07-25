import 'package:supabase_flutter/supabase_flutter.dart';

class NuevosFormulariosService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<int>> obtenerFormulariosDeEmpresa(int idEmpresa) async {
    try {
      final data = await supabase
          .from('formularios_por_empresa')
          .select('id_formulario')
          .eq('id_empresa', idEmpresa);

      return data.map<int>((row) => row['id_formulario'] as int).toList();
    } catch (e) {
      print('⛔ Error al obtener formularios disponibles: $e');
      return [];
    }
  }
}
