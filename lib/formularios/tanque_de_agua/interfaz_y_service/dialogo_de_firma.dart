import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'tanques_de_agua_service.dart';

class DialogoFirmaEncargado extends StatefulWidget {
  final Map<String, dynamic> formulario;

  const DialogoFirmaEncargado({super.key, required this.formulario});

  @override
  State<DialogoFirmaEncargado> createState() => _DialogoFirmaEncargadoState();
}

class _DialogoFirmaEncargadoState extends State<DialogoFirmaEncargado> {
  final SignatureController _firmaController =
      SignatureController(penStrokeWidth: 3, penColor: Colors.black);

  bool _subiendo = false;
  bool _procesandoTodo = false;

  Future<void> _subirYProcesar() async {
    if (_firmaController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La firma no puede estar vacía')),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    try {
      // Convertimos la firma a imagen PNG
      final Uint8List? firmaBytes = await _firmaController.toPngBytes();
      if (firmaBytes == null) throw Exception("Error generando imagen de firma");

      // Guardamos la imagen en archivo temporal
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_firma.png';
      final file = File(filePath);
      await file.writeAsBytes(firmaBytes);

      // Le pasamos el path local al formulario
      widget.formulario['url_firma'] = filePath;

      // Ejecutamos todo el proceso desde el Service
      setState(() {
        _subiendo = false;
        _procesandoTodo = true;
      });

      final service = TanqueAguaService(widget.formulario);
      await service.cargarRelevamientoCompleto();

      if (mounted) {
        Navigator.pop(context); // cierra el diálogo de firma
        Navigator.pop(context, true); // cierra la pantalla anterior (por ejemplo, el formulario)
      }
    } catch (e) {
      setState(() => _subiendo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Firma del encargado'),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: Column(
          children: [
            Expanded(
              child: Signature(
                controller: _firmaController,
                backgroundColor: Colors.grey[300]!,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                OutlinedButton(
                  onPressed: _firmaController.clear,
                  child: const Text('Reintentar'),
                ),
                ElevatedButton(
                  onPressed: _subiendo || _procesandoTodo ? null : _subirYProcesar,
                  child: _subiendo
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _subiendo || _procesandoTodo ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
