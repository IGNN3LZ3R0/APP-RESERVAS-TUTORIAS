import 'package:flutter/material.dart';
import '../modelos/usuario.dart';
import '../servicios/perfil_service.dart';

class CambiarPasswordScreen extends StatefulWidget {
  final Usuario usuario;

  const CambiarPasswordScreen({super.key, required this.usuario});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordActualController = TextEditingController();
  final _passwordNuevoController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  bool _obscurePasswordActual = true;
  bool _obscurePasswordNuevo = true;
  bool _obscurePasswordConfirmar = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevoController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que las contraseñas nuevas coincidan
    if (_passwordNuevoController.text != _passwordConfirmarController.text) {
      _mostrarError('Las contraseñas nuevas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic>? resultado;

    try {
      if (widget.usuario.esAdministrador) {
        resultado = await PerfilService.cambiarPasswordAdministrador(
          id: widget.usuario.id,
          passwordActual: _passwordActualController.text,
          passwordNuevo: _passwordNuevoController.text,
        );
      } else if (widget.usuario.esEstudiante) {
        resultado = await PerfilService.cambiarPasswordEstudiante(
          id: widget.usuario.id,
          passwordActual: _passwordActualController.text,
          passwordNuevo: _passwordNuevoController.text,
        );
      } else if (widget.usuario.esDocente) {
        // El backend de docente no tiene endpoint para cambiar contraseña
        resultado = {'error': 'Los docentes no pueden cambiar su contraseña desde aquí'};
      }
    } catch (e) {
      resultado = {'error': 'Error inesperado: $e'};
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Contraseña actualizada correctamente');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La contraseña debe tener al menos 6 caracteres',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contraseña actual
            TextFormField(
              controller: _passwordActualController,
              obscureText: _obscurePasswordActual,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasswordActual ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePasswordActual = !_obscurePasswordActual);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña actual';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nueva contraseña
            TextFormField(
              controller: _passwordNuevoController,
              obscureText: _obscurePasswordNuevo,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasswordNuevo ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePasswordNuevo = !_obscurePasswordNuevo);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una nueva contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirmar nueva contraseña
            TextFormField(
              controller: _passwordConfirmarController,
              obscureText: _obscurePasswordConfirmar,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasswordConfirmar ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePasswordConfirmar = !_obscurePasswordConfirmar);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor confirma tu nueva contraseña';
                }
                if (value != _passwordNuevoController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Botón cambiar contraseña
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _cambiarPassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Cambiar Contraseña',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}