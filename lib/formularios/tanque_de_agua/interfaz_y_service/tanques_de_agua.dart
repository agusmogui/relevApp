import 'package:flutter/material.dart';
import '../campos/formulario_cilindricos.dart';
import '../campos/formulario_concreto_cisterna.dart';
import '../campos/formulario_concreto_reserva.dart';
import 'dialogo_de_firma.dart';

class TanquesDeAguaScreen extends StatefulWidget {
  final Map<String, dynamic> empresa;

  const TanquesDeAguaScreen({Key? key, required this.empresa}) : super(key: key);

  @override
  State<TanquesDeAguaScreen> createState() => _TanquesDeAguaScreenState();
}

class _TanquesDeAguaScreenState extends State<TanquesDeAguaScreen> {
  final _formKey = GlobalKey<FormState>();
  // Formulario acumulador
  final Map<String, dynamic> datosFormulario = {};
  
  // Datos generales
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _administracionController = TextEditingController();
  final TextEditingController _encargadoController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  final TextEditingController _tecnicoController = TextEditingController();

  bool _cisternaExpandida = true;
  bool _reservaExpandida = true;

  String? _tipoCisterna;
  String? _tipoReserva;

  final Map<String, String> opcionesTanque = {
    'cilindrico': 'Cilíndrico',
    'concreto': 'Concreto',
    'no_tiene': 'No tiene',
  };

  void limpiarCamposFormularioConPrefijo(Map<String, dynamic> formulario, String prefijo) {
    final clavesABorrar = formulario.keys.where((key) => key.startsWith(prefijo)).toList();
    for (final key in clavesABorrar) {
      formulario.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relevamiento'),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(_tecnicoController, 'Técnico responsable', obligatorio: true),
                  const SizedBox(height: 16),
                  _buildTextField(_direccionController, 'Dirección', obligatorio: true),
                  const SizedBox(height: 16),
                  _buildTextField(_administracionController, 'Administración'),
                  const SizedBox(height: 16),
                  _buildTextField(_encargadoController, 'Encargado', obligatorio: true),
                  const SizedBox(height: 16),
                  _buildTextField(_contactoController, 'Contacto'),
                  const SizedBox(height: 30),

                  // Acordeón CISTERNA
                  _buildAcordeon(
                    titulo: 'Cisterna',
                    expandido: _cisternaExpandida,
                    onTap: () => setState(() => _cisternaExpandida = !_cisternaExpandida),
                    contenido: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDropdown(
                          label: 'Tipo de cisterna',
                          value: _tipoCisterna,
                          onChanged: (value) {
                            setState(() {
                              _tipoCisterna = value;
                              limpiarCamposFormularioConPrefijo(datosFormulario, 'cisterna_');
                            });
                          },
                          obligatorio: true,
                        ),
                        const SizedBox(height: 10),
                        if (_tipoCisterna == 'cilindrico')
                          FormularioCilindrico(
                            data: datosFormulario,
                            prefijo: 'cisterna',
                          )
                        else if (_tipoCisterna == 'concreto')
                          FormularioCisterna(
                            formulario: datosFormulario,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Acordeón RESERVA
                  _buildAcordeon(
                    titulo: 'Reserva',
                    expandido: _reservaExpandida,
                    onTap: () => setState(() => _reservaExpandida = !_reservaExpandida),
                    contenido: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDropdown(
                          label: 'Tipo de reserva',
                          value: _tipoReserva,
                          onChanged: (value) {
                            setState(() {
                              _tipoReserva = value;
                              limpiarCamposFormularioConPrefijo(datosFormulario, 'reserva_');
                            });
                          },
                          obligatorio: true,
                        ),
                        const SizedBox(height: 10),
                        if (_tipoReserva == 'cilindrico')
                          FormularioCilindrico(
                            data: datosFormulario,
                            prefijo: 'reserva',
                          )
                        else if (_tipoReserva == 'concreto')
                          FormularioReservaConcreto(
                            formulario: datosFormulario,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.navigate_next, color: Colors.white),
                        label: const Text(
                          'Continuar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            datosFormulario['tecnico'] = _tecnicoController.text;
                            datosFormulario['direccion'] = _direccionController.text;
                            datosFormulario['administracion'] = _administracionController.text;
                            datosFormulario['encargado'] = _encargadoController.text;
                            datosFormulario['contacto'] = _contactoController.text;
                            datosFormulario['tipo_cisterna'] = _tipoCisterna;
                            datosFormulario['tipo_reserva'] = _tipoReserva;

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return DialogoFirmaEncargado(formulario: datosFormulario);
                              },
                            );
                          }
                        }
                      ),
                      SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obligatorio = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: obligatorio
          ? (value) => value == null || value.isEmpty ? 'Este campo es obligatorio' : null
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Function(String?) onChanged,
    bool obligatorio = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF1F1F1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: opcionesTanque.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: obligatorio
          ? (val) => val == null ? 'Este campo es obligatorio' : null
          : null,
    );
  }


  Widget _buildAcordeon({
    required String titulo,
    required bool expandido,
    required VoidCallback onTap,
    required Widget contenido,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(expandido ? Icons.expand_less : Icons.expand_more),
            onTap: onTap,
          ),
          if (expandido)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: contenido,
            ),
        ],
      ),
    );
  }
}
