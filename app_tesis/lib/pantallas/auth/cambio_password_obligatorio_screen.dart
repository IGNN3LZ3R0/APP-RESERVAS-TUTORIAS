// lib/pantallas/cambio_password_obligatorio_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/auth_service.dart';
import '../../config/routes.dart';

class CambioPasswordObligatorioScreen extends StatefulWidget {
  final Usuario usuario;
  final String email;

  const CambioPasswordObligatorioScreen({
    super.key,
    required this.usuario,
    required this.email,
  });

  @override
  State<CambioPasswordObligatorioScreen> createState() =>
      _CambioPasswordObligatorioScreenState();
}

class _CambioPasswordObligatorioScreenState
    extends State<CambioPasswordObligatorioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePasswordActual = true;
  bool _obscurePasswordNueva = true;
  bool _obscurePasswordConfirmar = true;

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  String? _validarPasswordNueva(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'Debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe incluir al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Debe incluir al menos un carácter especial';
    }
    return null;
  }

  String? _validarPasswordConfirmar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordNuevaController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final resultado = await AuthService.cambiarPasswordObligatorio(
      email: widget.email,
      passwordActual: _passwordActualController.text,
      passwordNueva: _passwordNuevaController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Contraseña actualizada exitosamente');
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      // Navegar al home después del cambio exitoso
      AppRoutes.navigateToHome(context, widget.usuario);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevenir que el usuario regrese sin cambiar la contraseña
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cambio de Contraseña Obligatorio'),
          automaticallyImplyLeading: false, // Sin botón de retroceso
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono de advertencia
                  const Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Color(0xFFFF6B35),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  const Text(
                    'Cambio de Contraseña Requerido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    'Por seguridad, debes cambiar tu contraseña temporal antes de continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Información del usuario
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuario: ${widget.usuario.nombre}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Correo: ${widget.email}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo de contraseña actual
                  TextFormField(
                    controller: _passwordActualController,
                    obscureText: _obscurePasswordActual,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Temporal',
                      hintText: 'Ingresa la contraseña enviada por correo',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordActual
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() =>
                              _obscurePasswordActual = !_obscurePasswordActual);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña temporal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de nueva contraseña
                  TextFormField(
                    controller: _passwordNuevaController,
                    obscureText: _obscurePasswordNueva,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      hintText: 'Mínimo 8 caracteres',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordNueva
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() =>
                              _obscurePasswordNueva = !_obscurePasswordNueva);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _validarPasswordNueva,
                  ),
                  const SizedBox(height: 16),

                  // Campo de confirmar contraseña
                  TextFormField(
                    controller: _passwordConfirmarController,
                    obscureText: _obscurePasswordConfirmar,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Nueva Contraseña',
                      hintText: 'Repite la contraseña',
                      prefixIcon: const Icon(Icons.lock_clock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordConfirmar
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePasswordConfirmar =
                              !_obscurePasswordConfirmar);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: _validarPasswordConfirmar,
                  ),
                  const SizedBox(height: 24),

                  // Requisitos de la contraseña
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Requisitos de la contraseña:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RequisitoItem(
                          texto: 'Mínimo 8 caracteres',
                          cumple: _passwordNuevaController.text.length >= 8,
                        ),
                        _RequisitoItem(
                          texto: 'Al menos una mayúscula (A-Z)',
                          cumple: RegExp(r'[A-Z]')
                              .hasMatch(_passwordNuevaController.text),
                        ),
                        _RequisitoItem(
                          texto: 'Al menos una minúscula (a-z)',
                          cumple: RegExp(r'[a-z]')
                              .hasMatch(_passwordNuevaController.text),
                        ),
                        _RequisitoItem(
                          texto: 'Al menos un número (0-9)',
                          cumple: RegExp(r'[0-9]')
                              .hasMatch(_passwordNuevaController.text),
                        ),
                        _RequisitoItem(
                          texto: 'Al menos un carácter especial (!@#\$%)',
                          cumple: RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                              .hasMatch(_passwordNuevaController.text),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón de cambiar contraseña
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _cambiarPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Cambiar Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advertencia
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No podrás acceder al sistema sin cambiar tu contraseña',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para mostrar requisitos
class _RequisitoItem extends StatelessWidget {
  final String texto;
  final bool cumple;

  const _RequisitoItem({
    required this.texto,
    required this.cumple,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: cumple ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: cumple ? Colors.green[700] : Colors.grey[600],
                fontWeight: cumple ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}