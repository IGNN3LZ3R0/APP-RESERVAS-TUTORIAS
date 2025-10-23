// lib/pantallas/login_screen.dart
import 'package:flutter/material.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _rolSeleccionado = 'Estudiante';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic>? resultado;

    switch (_rolSeleccionado) {
      case 'Administrador':
        resultado = await AuthService.loginAdministrador(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        break;
      case 'Docente':
        resultado = await AuthService.loginDocente(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        break;
      case 'Estudiante':
      default:
        resultado = await AuthService.loginEstudiante(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        break;
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
      return;
    }

    // Verificar si requiere confirmación de email
    if (resultado != null && resultado.containsKey('requiresConfirmation')) {
      _mostrarDialogoConfirmacion(resultado['email']);
      return;
    }

    if (resultado != null && resultado.containsKey('token')) {
      final usuario = await AuthService.getUsuarioActual();
      
      if (usuario != null) {
        AppRoutes.navigateToHome(context, usuario);
      } else {
        _mostrarError('Error al obtener datos del usuario');
      }
    } else {
      _mostrarError('Credenciales incorrectas');
    }
  }

  void _mostrarDialogoConfirmacion(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirma tu cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debes confirmar tu cuenta antes de iniciar sesión.\n\n'
              'Hemos enviado un correo a:\n$email',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '¿No recibiste el correo?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Revisa tu carpeta de spam\n'
              '• Haz clic en el botón del correo desde tu celular\n'
              '• O ingresa el código manualmente',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/confirmar-codigo');
            },
            icon: const Icon(Icons.vpn_key, size: 18),
            label: const Text('Ingresar Código'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRoutes.navigateToBienvenida(context),
        ),
        title: const Text('Iniciar Sesión'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icono
                  const Icon(
                    Icons.school,
                    size: 80,
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título
                  const Text(
                    'Bienvenido',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa tus credenciales',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Selector de rol
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _rolSeleccionado,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1565C0)),
                        items: const [
                          DropdownMenuItem(
                            value: 'Estudiante',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Color(0xFF1565C0), size: 20),
                                SizedBox(width: 12),
                                Text('Estudiante', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Docente',
                            child: Row(
                              children: [
                                Icon(Icons.school, color: Color(0xFF1565C0), size: 20),
                                SizedBox(width: 12),
                                Text('Docente', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Administrador',
                            child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Color(0xFF1565C0), size: 20),
                                SizedBox(width: 12),
                                Text('Administrador', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _rolSeleccionado = value!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Campo de email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'ejemplo@epn.edu.ec',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // ¿Olvidaste tu contraseña?
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        AppRoutes.navigateToRecuperarPassword(context);
                      },
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón de iniciar sesión
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ========== SECCIÓN NUEVA: PROBLEMAS DE ACCESO ==========
                  
                  // Separador
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '¿Problemas para acceder?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón para activar cuenta
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/confirmar-codigo');
                    },
                    icon: const Icon(Icons.verified_user, size: 20),
                    label: const Text('Activar mi cuenta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Texto informativo
                  Text(
                    '¿No recibiste el código? Revisa tu spam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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