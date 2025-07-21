import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FormularioCisterna extends StatefulWidget {
  final Map<String, dynamic> formulario;

  const FormularioCisterna({
    Key? key,
    required this.formulario,
  }) : super(key: key);

  @override
  State<FormularioCisterna> createState() => _FormularioCisternaState();
}

class _FormularioCisternaState extends State<FormularioCisterna> {
  final _picker = ImagePicker();

  late final TextEditingController _anchoController;
  late final TextEditingController _largoController;
  late final TextEditingController _altoController;
  final TextEditingController _observacionesController = TextEditingController();

  String? _medidaFlotante;
  String? _pozoAchique;
  String? _bombaAchique;
  String? _llaveCierre;

  final List<XFile> _marcoYtapaLateral = [];
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
      widget.formulario['ancho'] = _anchoController.text;
    });
    _largoController.addListener(() {
      widget.formulario['largo'] = _largoController.text;
    });
    _altoController.addListener(() {
      widget.formulario['alto'] = _altoController.text;
    });
    _observacionesController.addListener(() {
      widget.formulario['observaciones'] = _observacionesController.text;
    });
  }

  Future<void> _agregarFoto(List<XFile> destino, int maxFotos) async {
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

    final XFile? foto = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (foto != null) {
      setState(() {
        destino.add(foto);
        _actualizarFormularioFotos(destino);
      });
    }
  }

  void _eliminarFoto(List<XFile> destino, int index) {
    setState(() {
      destino.removeAt(index);
      _actualizarFormularioFotos(destino);
    });
  }

  void _actualizarFormularioFotos(List<XFile> destino) {
    final rutas = destino.map((x) => x.path).toList();

    if (destino == _marcoYtapaLateral) {
      widget.formulario['marco_tapa_lateral'] = rutas;
    } else if (destino == _tapaInspeccion) {
      widget.formulario['tapa_inspeccion'] = rutas;
    } else if (destino == _estadoParedes) {
      widget.formulario['estado_paredes'] = rutas;
    } else if (destino == _colectora) {
      widget.formulario['colectora'] = rutas;
    }
  }

  Widget _buildGaleria({
    required String titulo,
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
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _eliminarFoto(fotos, i),
                    ),
                  )
                ],
              ),
            if (fotos.length < maxFotos)
              GestureDetector(
                onTap: () => _agregarFoto(fotos, maxFotos),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Formulario Cisterna',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildNumberField(_anchoController, 'Ancho'),
        const SizedBox(height: 16),
        _buildNumberField(_largoController, 'Largo'),
        const SizedBox(height: 16),
        _buildNumberField(_altoController, 'Alto'),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Medida del flotante',
          value: _medidaFlotante,
          items: ['3/4\'\'', '1\'\'', '1 1/4\'\'', '1 1/2\'\''],
          onChanged: (val) {
            setState(() => _medidaFlotante = val);
            widget.formulario['medida_flotante'] = val;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: '¿Tiene pozo de achique?',
          value: _pozoAchique,
          items: ['Sí', 'No'],
          onChanged: (val) {
            setState(() => _pozoAchique = val);
            widget.formulario['pozo_achique'] = val;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: '¿Tiene bomba de achique?',
          value: _bombaAchique,
          items: [
            'Sí',
            'Sí y no funciona',
            'Sí y no está conectada',
            'No',
          ],
          onChanged: (val) {
            setState(() => _bombaAchique = val);
            widget.formulario['bomba_achique'] = val;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: '¿Tiene llave de cierre?',
          value: _llaveCierre,
          items: ['Sí', 'No'],
          onChanged: (val) {
            setState(() => _llaveCierre = val);
            widget.formulario['llave_cierre'] = val;
          },
        ),
        const SizedBox(height: 24),
        _buildGaleria(titulo: 'Marco y tapa lateral (1 a 3 fotos)', fotos: _marcoYtapaLateral, maxFotos: 3),
        const SizedBox(height: 24),
        _buildGaleria(titulo: 'Tapa de inspección (1 a 2 fotos)', fotos: _tapaInspeccion, maxFotos: 2),
        const SizedBox(height: 24),
        _buildGaleria(titulo: 'Estado de paredes (1 a 2 fotos)', fotos: _estadoParedes, maxFotos: 2),
        const SizedBox(height: 24),
        _buildGaleria(titulo: 'Colectora (1 a 2 fotos)', fotos: _colectora, maxFotos: 2),
        const SizedBox(height: 30),
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
      validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
    );
  }
}
