import 'package:flutter/material.dart';
import 'package:app_tesis/config/theme.dart';
import 'package:app_tesis/servicios/auth_service.dart';
import 'package:app_tesis/config/routes.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isLoading = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;
  bool _emailEsInstitucional = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  /// Valida si el email es institucional (EPN)
  bool _esEmailInstitucional(String email) {
    return email.toLowerCase().contains('@epn.edu.ec');
  }

  /// Muestra un diálogo advirtiendo si el email es institucional
  Future<bool> _validarEmailInstitucional(String email) async {
    if (_esEmailInstitucional(email)) {
      final confirmacion = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Email Institucional Detectado'),
          content: const Text(
            '¿Eres docente?\n\n'
            'Si eres docente, debes contactar al administrador de tu institución para que te registre en el sistema. Los docentes no pueden auto-registrarse.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, soy estudiante'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Soy docente'),
            ),
          ],
        ),
      );

      if (confirmacion == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Para registrarte como docente, contacta al administrador de tu institución.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return false; // No permitir registro
      }
      return true; // Permitir registro como estudiante
    }
    return true; // Email no institucional, permitir
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  String? _validarConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  String? _validarRequerido(String? value, String campo) {
    if (value == null || value.isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 10) {
        return 'El teléfono debe tener al menos 10 dígitos';
      }
    }
    return null;
  }

  Future<void> _registrarEstudiante() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar email institucional
    final emailValido = await _validarEmailInstitucional(_emailController.text.trim());
    if (!emailValido) {
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService.registrarEstudiante(
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (resultado != null && !resultado.containsKey('error')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registro exitoso. Verifica tu correo para confirmar tu cuenta',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Limpiar formulario
        _formKey.currentState!.reset();
        _nombreController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _telefonoController.clear();

        // Redirigir a login después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            AppRoutes.navigateToLogin(context);
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado?['error'] ?? 'Error en el registro',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Registro de Estudiante',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Completa el formulario para crear tu cuenta',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Aviso para docentes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¿Eres docente? Contacta al administrador de tu institución.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Campo de nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.person),
                  hintText: 'Juan Pérez',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => _validarRequerido(value, 'El nombre'),
              ),
              const SizedBox(height: 16),

              // Campo de email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  hintText: 'tu@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validarEmail,
                onChanged: (value) {
                  setState(
                    () => _emailEsInstitucional = _esEmailInstitucional(value),
                  );
                },
              ),
              if (_emailEsInstitucional)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Email institucional detectado',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Campo de teléfono
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono (Opcional)',
                  prefixIcon: const Icon(Icons.phone),
                  hintText: '0987654321',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: _validarTelefono,
              ),
              const SizedBox(height: 16),

              // Campo de contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: !_mostrarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  hintText: '••••••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _mostrarPassword = !_mostrarPassword),
                  ),
                ),
                validator: _validarPassword,
              ),
              const SizedBox(height: 8),
              Text(
                'Mínimo 8 caracteres',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Campo de confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_mostrarConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  hintText: '••••••••',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () =>
                          _mostrarConfirmPassword = !_mostrarConfirmPassword,
                    ),
                  ),
                ),
                validator: (value) => _validarConfirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
              const SizedBox(height: 28),

              // Botón de registro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarEstudiante,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Ir a login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes cuenta? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => AppRoutes.push(context, AppRoutes.login),
                    child: const Text('Inicia sesión'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}