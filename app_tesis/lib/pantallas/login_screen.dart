import 'package:flutter/material.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _rolSeleccionado = 'Estudiante'; // Por defecto

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

    // Llamar al servicio según el rol seleccionado
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

    // Verificar si hay error
    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
      return;
    }

    // Login exitoso
    if (resultado != null && resultado.containsKey('token')) {
      final usuario = await AuthService.getUsuarioActual();
      
      if (usuario != null) {
        // Navegar al home
        AppRoutes.navigateToHome(context, usuario);
      } else {
        _mostrarError('Error al obtener datos del usuario');
      }
    } else {
      _mostrarError('Credenciales incorrectas');
    }
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
                    'ESFOT Tutorías',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escuela de Formación de Tecnólogos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
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
                        // TODO: Navegar a recuperar contraseña
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de recuperar contraseña próximamente'),
                          ),
                        );
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
                  
                  // Registro para estudiantes
                  if (_rolSeleccionado == 'Estudiante')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {
                            AppRoutes.navigateToRegistro(context);
                          },
                          child: const Text('Regístrate'),
                        ),
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
}