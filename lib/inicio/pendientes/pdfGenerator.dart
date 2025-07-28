import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';

class PdfGenerator {
  static const _channel = MethodChannel('app.channel.shared.data');

  static Future<void> generarPdf({
    required Map<String, dynamic> datos,
    required String logoPathLocal,
    required String nombreRelevamiento,
  }) async {
    final pdf = pw.Document();

    // Extraemos datos generales (los que no son de tanques)
    // Por ejemplo: fecha, hora, encargado, tecnico, administracion, contacto, direccion
    final fecha = datos['fecha'] ?? '';
    final hora = datos['hora'] ?? '';
    final encargado = datos['encargado'] ?? '';
    final tecnico = datos['tecnico'] ?? '';
    final administracion = datos['administracion'] ?? '';
    final contacto = datos['contacto'] ?? '';
    final direccion = datos['direccion'] ?? '';

    // Datos cisterna
    final tipoCisterna = datos['tipo_cisterna'] ?? 'N/D';
    final cisternaCantidad = datos['cisterna_cantidad']?.toString() ?? 'N/D';
    final cisternaLitros = datos['cisterna_litros']?.toString() ?? 'N/D';
    final cisternaObservaciones = datos['cisterna_observaciones'] ?? '';

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Título grande
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

              // Datos Generales (en un rectángulo con borde)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey800, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Datos Generales',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Divider(),
                    pw.Text('Encargado: $encargado', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Técnico: $tecnico', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Administración: $administracion', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Contacto: $contacto', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Dirección: $direccion', style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Cisterna (en otro rectángulo con borde)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey800, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Cisterna',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Divider(),
                    pw.Text('Tipo: $tipoCisterna', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Cantidad: $cisternaCantidad', style: pw.TextStyle(fontSize: 14)),
                    pw.Text('Litros: $cisternaLitros', style: pw.TextStyle(fontSize: 14)),
                    if (cisternaObservaciones.isNotEmpty)
                      pw.Text('Observaciones: $cisternaObservaciones', style: pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Guardar PDF en archivo temporal
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
}
