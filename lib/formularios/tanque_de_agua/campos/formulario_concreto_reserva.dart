import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FormularioReservaConcreto extends StatefulWidget {
  final Map<String, dynamic> formulario;

  const FormularioReservaConcreto({
    Key? key,
    required this.formulario,
  }) : super(key: key);

  @override
  State<FormularioReservaConcreto> createState() => _FormularioReservaConcretoState();
}

class _FormularioReservaConcretoState extends State<FormularioReservaConcreto> {
  final _picker = ImagePicker();

  late final TextEditingController _anchoController;
  late final TextEditingController _largoController;
  late final TextEditingController _altoController;
  final _observacionesController = TextEditingController();

  String? _automaticos;

  final List<XFile> _marcoYtapaPrimaria = [];
  final List<XFile> _marcoYtapaSecundaria = [];
  final List<XFile> _tapaInspeccion = [];
  final List<XFile> _estadoParedes = [];
  final List<XFile> _colectora = [];

  @override
  void initState() {
    super.initState();

    _anchoController = TextEditingController();
    _largoController = TextEditingController();
    _altoController = TextEditingController();

    _anchoController.addListener(() {
      widget.formulario['reserva_ancho'] = _anchoController.text;
    });
    _largoController.addListener(() {
      widget.formulario['reserva_largo'] = _largoController.text;
    });
    _altoController.addListener(() {
      widget.formulario['reserva_alto'] = _altoController.text;
    });
    _observacionesController.addListener(() {
      widget.formulario['reserva_observaciones'] = _observacionesController.text;
    });
  }

  Future<void> _agregarFoto(List<XFile> destino, int maxFotos, String key) async {
    if (destino.length >= maxFotos) return;

    final ImageSource? source = await showDialog<ImageSource>(
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

    final XFile? foto = await _picker.pickImage(source: source);
    if (foto != null) {
      setState(() {
        destino.add(foto);
        widget.formulario['reserva_$key'] = destino.map((f) => f.path).toList();
      });
    }
  }

  void _eliminarFoto(List<XFile> destino, int index, String key) {
    setState(() {
      destino.removeAt(index);
      widget.formulario['reserva_$key'] = destino.map((f) => f.path).toList();
    });
  }

  Widget _buildGaleria({
    required String titulo,
    required List<XFile> fotos,
    required int maxFotos,
    required String keyFormulario,
    bool obligatorio = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (!obligatorio)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('(opcional)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              )
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < fotos.length; i++)
              Stack(
                children: [
                  Image.file(
                    File(fotos[i].path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Color.fromARGB(255, 17, 39, 0)),
                      onPressed: () => _eliminarFoto(fotos, i, keyFormulario),
                    ),
                  )
                ],
              ),
            if (fotos.length < maxFotos)
              GestureDetector(
                onTap: () => _agregarFoto(fotos, maxFotos, keyFormulario),
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
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Formulario Reserva Concreto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildNumberField(_anchoController, 'Ancho'),
        const SizedBox(height: 16),
        _buildNumberField(_largoController, 'Largo'),
        const SizedBox(height: 16),
        _buildNumberField(_altoController, 'Alto'),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Automáticos',
          value: _automaticos,
          items: ['Tanza', 'Unidad sellada'],
          onChanged: (val) {
            setState(() => _automaticos = val);
            widget.formulario['reserva_automaticos'] = val;
          },
        ),
        const SizedBox(height: 24),
        _buildGaleria(
          titulo: 'Marco y tapa lateral primaria (1 a 3 fotos)',
          fotos: _marcoYtapaPrimaria,
          maxFotos: 3,
          keyFormulario: 'marco_tapa_primaria',
        ),
        _buildGaleria(
          titulo: 'Marco y tapa lateral secundaria (1 a 3 fotos)',
          fotos: _marcoYtapaSecundaria,
          maxFotos: 3,
          keyFormulario: 'marco_tapa_secundaria',
          obligatorio: false,
        ),
        _buildGaleria(
          titulo: 'Tapa de inspección (1 a 2 fotos)',
          fotos: _tapaInspeccion,
          maxFotos: 2,
          keyFormulario: 'tapa_inspeccion',
        ),
        _buildGaleria(
          titulo: 'Estado de paredes (1 a 6 fotos)',
          fotos: _estadoParedes,
          maxFotos: 6,
          keyFormulario: 'estado_paredes',
        ),
        _buildGaleria(
          titulo: 'Colectora (1 a 4 fotos)',
          fotos: _colectora,
          maxFotos: 4,
          keyFormulario: 'colectora',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacionesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            filled: true,
            fillColor: const Color(0xFFF1F1F1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        if (double.tryParse(value) == null) return 'Debe ser un número válido';
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Campo obligatorio' : null,
    );
  }
}
