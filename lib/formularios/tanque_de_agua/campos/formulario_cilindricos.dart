import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FormularioCilindrico extends StatefulWidget {
  final Map<String, dynamic> data;
  final String prefijo; // ej: "cisterna" o "reserva"

  const FormularioCilindrico({
    Key? key,
    required this.data,
    required this.prefijo,
  }) : super(key: key);

  @override
  State<FormularioCilindrico> createState() => _FormularioCilindricoState();
}

class _FormularioCilindricoState extends State<FormularioCilindrico> {
  final ImagePicker _picker = ImagePicker();

  List<XFile> _fotosColectora = [];
  List<XFile> _fotosEstado = [];

  @override
  void initState() {
    super.initState();

    final List<String> rutasEstado = (widget.data['${widget.prefijo}_fotos_estado'] ?? []).cast<String>();
    final List<String> rutasColectora = (widget.data['${widget.prefijo}_fotos_colectora'] ?? []).cast<String>();

    _fotosEstado = rutasEstado.map((ruta) => XFile(ruta)).toList();
    _fotosColectora = rutasColectora.map((ruta) => XFile(ruta)).toList();
  }

  Future<void> _agregarFoto(String campo, List<XFile> destino, int maxFotos) async {
    if (destino.length >= maxFotos) return;

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccioná una opción'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final foto = await _picker.pickImage(source: source, imageQuality: 85);
    if (foto != null) {
      setState(() {
        destino.add(foto);
        widget.data[campo] = destino.map((f) => f.path).toList();
      });
    }
  }

  void _eliminarFoto(String campo, List<XFile> destino, int index) {
    setState(() {
      destino.removeAt(index);
      widget.data[campo] = destino.map((f) => f.path).toList();
    });
  }

  Widget _buildGaleria({
    required String titulo,
    required String campo,
    required List<XFile> fotos,
    required int maxFotos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < fotos.length; i++)
              Stack(
                children: [
                  Image.file(File(fotos[i].path), width: 100, height: 100, fit: BoxFit.cover),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _eliminarFoto(campo, fotos, i),
                    ),
                  )
                ],
              ),
            if (fotos.length < maxFotos)
              GestureDetector(
                onTap: () => _agregarFoto(campo, fotos, maxFotos),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prefijo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Formulario Cilíndrico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildNumberField('${p}_cantidad', 'Cantidad de tanques'),
        const SizedBox(height: 16),
        _buildNumberField('${p}_litros', 'Litros por tanque'),
        const SizedBox(height: 24),
        _buildGaleria(
          titulo: 'Estado del tanque (1 a 6 fotos)',
          campo: '${p}_fotos_estado',
          fotos: _fotosEstado,
          maxFotos: 6,
        ),
        const SizedBox(height: 24),
        _buildGaleria(
          titulo: 'Colectora (1 a 3 fotos)',
          campo: '${p}_fotos_colectora',
          fotos: _fotosColectora,
          maxFotos: 3,
        ),
        const SizedBox(height: 24),
        _buildTextField('${p}_observaciones', 'Observaciones', obligatorio: false),
      ],
    );
  }

  Widget _buildNumberField(String key, String label) {
    return TextFormField(
      initialValue: widget.data[key]?.toString() ?? '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (val) => widget.data[key] = val,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        if (int.tryParse(value) == null) return 'Debe ser un número válido';
        return null;
      },
    );
  }

  Widget _buildTextField(String key, String label, {bool obligatorio = true}) {
    return TextFormField(
      initialValue: widget.data[key]?.toString() ?? '',
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (val) => widget.data[key] = val,
      validator: obligatorio
          ? (value) => value == null || value.isEmpty ? 'Este campo es obligatorio' : null
          : null,
    );
  }
}
