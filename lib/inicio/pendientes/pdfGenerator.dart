import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class PdfGenerator {
  static const _channel = MethodChannel('app.channel.shared.data');

  static Future<void> generarPdf({
    required Map<String, dynamic> datos,
    required Uint8List? logoBytes,
    required String nombreRelevamiento,
    required String nombreEmpresa,

  }) async {
    final pdf = pw.Document();

    final fecha = datos['fecha'] ?? '';
final hora = datos['hora'] ?? '';
final encargado = datos['encargado'] ?? '';
final tecnico = datos['tecnico'] ?? '';
final administracion = datos['administracion'] ?? '';
final contacto = datos['contacto'] ?? '';
final direccion = datos['direccion'] ?? '';

pdf.addPage(
  pw.MultiPage(
    margin: const pw.EdgeInsets.all(32),
    header: (context) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Container(
                  width: 65, // más grande
                  height: 65,
                  margin: const pw.EdgeInsets.only(right: 16),
                  child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1), // línea divisoria
        ],
      );
    },
    build: (context) => [
      pw.Center(
        child: pw.Text(
          nombreRelevamiento,
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),

      pw.SizedBox(height: 16),

      // Fecha y hora centrados debajo del título
      pw.Center(
        child: pw.Text(
          'Fecha: $fecha    Hora: $hora',
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800),
        ),
      ),

      pw.SizedBox(height: 32),

      // Contenedor datos generales estilizado
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          border: pw.Border.all(color: PdfColors.grey500, width: 1),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'DATOS GENERALES',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.green800),
            pw.SizedBox(height: 6),
            pw.Text('Encargado: $encargado', style: const pw.TextStyle(fontSize: 14)),
            pw.Text('Técnico: $tecnico', style: const pw.TextStyle(fontSize: 14)),
            pw.Text('Administración: $administracion', style: const pw.TextStyle(fontSize: 14)),
            pw.Text('Contacto: $contacto', style: const pw.TextStyle(fontSize: 14)),
            pw.Text('Dirección: $direccion', style: const pw.TextStyle(fontSize: 14)),
          ],
        ),
      ),

      pw.SizedBox(height: 24),

          // ===========================
          // DATOS CISTERNA (si tiene)
          // ===========================
          if (datos['tipo_cisterna'] != 'no tiene' && datos['tipo_cisterna'] != null)
            ..._seccionTanque(
              titulo: "CISTERNA",
              tipo: datos['tipo_cisterna'],
              prefijo: "cisterna",
              datos: datos,
            ),

          pw.SizedBox(height: 20),

          // ===========================
          // DATOS RESERVA (si tiene)
          // ===========================
          if (datos['tipo_reserva'] != 'no tiene' && datos['tipo_reserva'] != null)
            ..._seccionTanque(
              titulo: "RESERVA",
              tipo: datos['tipo_reserva'],
              prefijo: "reserva",
              datos: datos,
            ),
        ],
      ),
    );

    // ===========================
    // GUARDAR Y COMPARTIR PDF
    // ===========================
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/relevamiento.pdf';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(bytes);

    // Compartir archivo (solo Android implementado)
    if (UniversalPlatform.isAndroid) {
      try {
        await _channel.invokeMethod(
          'shareFile',
          {'path': tempPath, 'text': nombreRelevamiento},
        );
      } catch (e) {
        print('Error al compartir en Android: $e');
      }
    } else if (UniversalPlatform.isIOS) {
      print('Función para compartir en iOS no implementada aún');
    } else {
      print('Esta función solo está diseñada para Android e iOS.');
    }
  }

  // ===========================
  // CAMPOS DINÁMICOS POR TIPO
  // ===========================

  static List<pw.Widget> _seccionTanque({
  required String titulo,
  required String tipo,
  required String prefijo,
  required Map<String, dynamic> datos,
}) {
  final camposPorTipo = {
    'concreto': [
      {'key': 'largo', 'label': 'Largo'},
      {'key': 'ancho', 'label': 'Ancho'},
      {'key': 'alto', 'label': 'Alto'},
      if (prefijo == 'cisterna') ...[
        {'key': 'medida_flotante', 'label': 'Medida flotante'},
        {'key': 'pozo_achique', 'label': 'Pozo de achique'},
        {'key': 'bomba_achique', 'label': 'Bomba de achique'},
        {'key': 'llave_cierre', 'label': 'Llave de cierre'},
      ],
      {'key': 'observaciones', 'label': 'Observaciones'},
    ],
    'cilindrico': [
      {'key': 'cantidad', 'label': 'Cantidad'},
      {'key': 'litros', 'label': 'Litros'},
      {'key': 'observaciones', 'label': 'Observaciones'},
    ],
  };

  final campos = camposPorTipo[tipo] ?? [];

  return [
    pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.grey500, width: 1),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.Divider(thickness: 1.5, color: PdfColors.green800),
          pw.SizedBox(height: 6),
          for (final campo in campos)
            if (datos.containsKey('${prefijo}_${campo['key']}'))
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  "${campo['label']}: ${datos['${prefijo}_${campo['key']}']}",
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ),
          pw.SizedBox(height: 12),
          ..._renderFotos(prefijo, datos),
        ],
      ),
    )
  ];
}

static List<pw.Widget> _renderFotos(String prefijo, Map<String, dynamic> datos) {
  final List<pw.Widget> imagenes = [];

  final claves = datos.keys.where((k) => k.startsWith(prefijo) && datos[k] is List).toList();

  for (final clave in claves) {
    final List paths = datos[clave];
    if (paths.isEmpty) continue;

    // Título de la sección de fotos
    imagenes.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          clave.replaceAll('${prefijo}_', '').replaceAll('_', ' ').toUpperCase(),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
        ),
      ),
    );

    // Dividir paths en grupos de 3
    for (var i = 0; i < paths.length; i += 3) {
      final grupo = paths.sublist(i, (i + 3 > paths.length) ? paths.length : i + 3);

      imagenes.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: grupo.map<pw.Widget>((path) {
            final file = File(path);
            if (file.existsSync()) {
              final image = pw.MemoryImage(file.readAsBytesSync());
              return pw.Container(
                margin: const pw.EdgeInsets.only(right: 8, bottom: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Image(image, width: 100, height: 100, fit: pw.BoxFit.cover),
              );
            } else {
              return pw.Container(); // foto no existe, no agrego nada
            }
          }).toList(),
        ),
      );
    }
  }

  return imagenes;
}

static Future<Uint8List?> descargarLogo(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error descargando logo: $e');
    }
    return null;
  }

  static Future<void> generarPdfDesdeUrlLogo({
    required Map<String, dynamic> datos,
    required String logoUrl,
    required String nombreEmpresa,
    required String nombreRelevamiento,
  }) async {
    final logoBytes = await descargarLogo(logoUrl);
    await generarPdf(
      datos: datos,
      logoBytes: logoBytes,
      nombreEmpresa: nombreEmpresa,
      nombreRelevamiento: nombreRelevamiento,
    );
  }
 
}
