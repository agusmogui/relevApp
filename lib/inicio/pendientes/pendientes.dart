import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pendientes_service.dart';
import '../../formularios/tanque_de_agua/interfaz_y_service/tanques_de_agua.dart';

class Pendientes extends StatefulWidget {
  final Map<String, dynamic> empresa;
  final VoidCallback onCancelar;

  const Pendientes({
    super.key,
    required this.empresa,
    required this.onCancelar,
  });

  @override
  State<Pendientes> createState() => _PendientesState();
}

class _PendientesState extends State<Pendientes> {
  bool _accesoPermitido = false;
  List<Map<String, dynamic>> _relevamientos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarAcceso();
  }

  Future<void> _verificarAcceso() async {
    final prefs = await SharedPreferences.getInstance();
    final String clave = 'acceso_permitido_${widget.empresa['id_empresa']}';
    final yaPermitido = prefs.getBool(clave) ?? false;

    if (yaPermitido) {
      setState(() => _accesoPermitido = true);
      _cargarRelevamientos();
    } else {
      Future.delayed(Duration.zero, _mostrarDialogoContrasena);
    }
  }

  Future<void> _mostrarDialogoContrasena() async {
    final TextEditingController _controller = TextEditingController();
    final String contrasenaCorrecta = widget.empresa['clave_dueno'] ?? '';
    final String clavePrefs = 'acceso_permitido_${widget.empresa['id_empresa']}';

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('Contraseña'),
          content: TextField(
            controller: _controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Ingrese la contraseña'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final ingreso = _controller.text;
                if (ingreso == contrasenaCorrecta) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contraseña incorrecta')),
                  );
                }
              },
              child: const Text('Ingresar'),
            ),
          ],
        );
      },
    );

    if (resultado == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(clavePrefs, true);
      setState(() => _accesoPermitido = true);
      _cargarRelevamientos();
    } else {
      widget.onCancelar();
    }
  }

  Future<void> _cargarRelevamientos() async {
    setState(() => _cargando = true);
    final idEmpresa = widget.empresa['id_empresa'];
    final data = await PendientesService().obtenerRelevamientosDeEmpresa(idEmpresa);
    setState(() {
      _relevamientos = data;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_accesoPermitido) return const SizedBox();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(16),
        child: _cargando
            ? const CircularProgressIndicator()
            : _relevamientos.isEmpty
                ? Text(
                    'Aún no hay pendientes asignados para ${widget.empresa['nombre'] ?? 'esta empresa'}.',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  )
                : _buildListaAgrupada(),
      ),
    );
  }

  Widget _buildListaAgrupada() {
    final Map<String, List<Map<String, dynamic>>> agrupado = {};

    for (final r in _relevamientos) {
      final descripcion = r['descripcion_formulario'] ?? 'Otro';
      if (!agrupado.containsKey(descripcion)) {
        agrupado[descripcion] = [];
      }
      agrupado[descripcion]!.add(r);
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      children: agrupado.entries.map((entry) {
        final titulo = entry.key;
        final relevamientos = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Center(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            ...relevamientos.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Card(
                    child: InkWell(
                      onTap: () async {
                        final idFormulario = r['id_formulario'];

                        if (idFormulario == 1) {
                          final idRelevamiento = r['id_relevamiento'];

                          final service = PendientesService();
                          final relevamientoCompleto = await service.obtenerRelevamientoCompleto(idRelevamiento);

                          if (relevamientoCompleto == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo cargar el relevamiento completo')),
                            );
                            return;
                          }

                          try {
                            final datosPlano = await service.transformarRelevamientoConFotos(relevamientoCompleto);
                            if (!mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TanquesDeAguaScreen(
                                  empresa: widget.empresa,
                                  datosPrevios: datosPlano,
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error procesando las fotos: $e')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Este formulario aún no está implementado')),
                          );
                        }
                      },

                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['direccion'] ?? 'Dirección desconocida',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Fecha: ${r['fecha'] ?? 'sin fecha'}'),
                                  Text('Técnico: ${r['tecnico'] ?? 'sin técnico'}'),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }
}
