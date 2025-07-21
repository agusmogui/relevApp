import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_service.dart';
import '../inicio/inicio.dart';

class PantallaIngreso extends StatefulWidget {
  const PantallaIngreso({super.key});

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  final TextEditingController _claveController = TextEditingController();
  bool _mantenerSesion = false;
  bool _mostrarClave = false;
  bool _isLoading = false;

  final LoginService _loginService = LoginService();

  @override
  void initState() {
    super.initState();
    _cargarSesionGuardada();
  }

  Future<void> _cargarSesionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final claveGuardada = prefs.getString('clave_empresa');
    if (claveGuardada != null) {
      _claveController.text = claveGuardada;
      _mantenerSesion = true;
      setState(() {});
      _intentarLogin(claveGuardada);
    }
  }

  Future<void> _intentarLogin(String clave) async {
    setState(() {
      _isLoading = true;
    });

    final empresa = await _loginService.loginConClave(clave);

    setState(() {
      _isLoading = false;
    });

    final prefs = await SharedPreferences.getInstance();

    if (empresa != null) {
      if (_mantenerSesion) {
        await prefs.setString('clave_empresa', clave);
        await prefs.setString('empresa_id', empresa['id_empresa'].toString());
        await prefs.setString('empresa_nombre', empresa['nombre_empresa'] ?? '');
        await prefs.setString('empresa_logo', empresa['logo_empresa'] ?? '');
      } else {
        await prefs.remove('clave_empresa');
        await prefs.remove('empresa_id');
        await prefs.remove('empresa_nombre');
        await prefs.remove('empresa_logo');
      }

      // ✅ NAVEGACIÓN a pantalla de inicio
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaInicio(empresa: empresa),
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clave incorrecta, intenta nuevamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Center(
              child: Image.asset(
                'images/logo.png',
                width: 280,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: TextField(
                              controller: _claveController,
                              obscureText: !_mostrarClave,
                              decoration: InputDecoration(
                                labelText: 'Clave de la empresa',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostrarClave ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _mostrarClave = !_mostrarClave;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Icon(Icons.arrow_forward, color: Colors.white),
                            onPressed: _isLoading
                                ? null
                                : () => _intentarLogin(_claveController.text.trim()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Checkbox(
                          value: _mantenerSesion,
                          onChanged: (bool? value) {
                            setState(() {
                              _mantenerSesion = value ?? false;
                            });
                          },
                        ),
                        const Text('Mantener sesión iniciada'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
