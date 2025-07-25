import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    } else {
      widget.onCancelar(); // <- 🔁 Cambia de pantalla/tab
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_accesoPermitido) return const SizedBox();

    return Center(
      child: Text(
        'Aún no hay pendientes asignados para ${widget.empresa['nombre'] ?? 'esta empresa'}.',
        style: const TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }
}
