import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FotoProvider extends ChangeNotifier {
  Map<String, dynamic>? _formularioConvertido;
  bool _cargando = false;
  String? _error;

  Map<String, dynamic>? get formulario => _formularioConvertido;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar(Map<String, dynamic> formularioOriginal) async {
    _cargando = true;
    _error = null;
    _formularioConvertido = null;
    notifyListeners();

    try {
      final Map<String, dynamic> resultado = {};

      for (final entry in formularioOriginal.entries) {
        final key = entry.key;
        final value = entry.value;

        if (_esListaDeUrls(value)) {
          final List<XFile> archivos = [];

          for (final url in value) {
            try {
              final xfile = await _descargarComoXFile(url);
              archivos.add(xfile);
            } catch (e) {
              print('⚠️ Error descargando $url: $e');
            }
          }

          // ✅ Guardar solo los paths como strings
          resultado[key] = archivos.map((x) => x.path).toList();
        } else {
          resultado[key] = value;
        }
      }

      _formularioConvertido = resultado;
    } catch (e) {
      _error = e.toString();
    }

    _cargando = false;
    notifyListeners();
  }

  static bool _esListaDeUrls(dynamic valor) {
    return valor is List &&
        valor.isNotEmpty &&
        valor.every((v) => v is String && (v.startsWith('http://') || v.startsWith('https://')));
  }

  static Future<XFile> _descargarComoXFile(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${url.split('/').last}';
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);
      return XFile(file.path);
    } else {
      throw Exception('No se pudo descargar la imagen: $url');
    }
  }
}
