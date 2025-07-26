import 'package:flutter/material.dart';
import '../../formularios/tanque_de_agua/interfaz_y_service/tanques_de_agua.dart';
import 'nuevo_formulario_service.dart';

class NuevoFormulario extends StatefulWidget {
  final Map<String, dynamic> empresa;

  const NuevoFormulario({
    Key? key,
    required this.empresa,
  }) : super(key: key);

  @override
  State<NuevoFormulario> createState() => _NuevoFormularioState();
}

class _NuevoFormularioState extends State<NuevoFormulario> {
  List<int> formulariosDisponibles = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarFormularios();
  }

  Future<void> _cargarFormularios() async {
    final idEmpresa = widget.empresa['id_empresa'] as int;
    final service = NuevosFormulariosService();
    final formularios = await service.obtenerFormulariosDeEmpresa(idEmpresa);

    setState(() {
      formulariosDisponibles = formularios;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? logoUrl = widget.empresa['logo_empresa'];

    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Center(
          child: logoUrl != null && logoUrl.isNotEmpty
              ? Image.network(
                  logoUrl,
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 100);
                  },
                )
              : const Icon(Icons.business, size: 100),
        ),
        const SizedBox(height: 20),
        if (formulariosDisponibles.contains(1)) // 1 = tanque de agua
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TanquesDeAguaScreen(empresa: widget.empresa),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Relevamiento tanque de agua',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Este formulario no está habilitado para tu empresa.'),
          ),
      ],
    );
  }
}