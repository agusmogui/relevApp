import 'package:supabase_flutter/supabase_flutter.dart';

class LoginService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> loginConClave(String clave) async {
    try {
      final data = await supabase
          .from('empresas')
          .select('id_empresa, nombre_empresa, logo_empresa')
          .eq('clave_empresa', clave)
          .maybeSingle(); // devuelve null si no hay coincidencia

      if (data == null) return null;

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('Error en consulta login: $e');
      return null;
    }
  }
}
