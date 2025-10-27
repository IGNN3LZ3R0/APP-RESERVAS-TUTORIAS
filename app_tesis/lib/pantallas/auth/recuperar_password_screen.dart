// lib/pantallas/recuperar_password_screen.dart
import 'package:flutter/material.dart';
import '../servicios/auth_service.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ===========================
  // MÉTODOS DE LÓGICA
  // ===========================

  Future<void> _recuperarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final resultado = await AuthService.recuperarPassword(
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado?['error'] != null) {
      _mostrarSnackBar(resultado!['error'], isError: true);
    } else if (resultado?['msg'] != null) {
      _mostrarSnackBar(resultado!['msg'], isError: false);
      _emailController.clear();

      // Espera breve antes de regresar al login
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    }
  }

  void _mostrarSnackBar(String mensaje, {required bool isError}) {
    final color = isError ? Colors.red : Colors.green;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ===========================
  // WIDGETS DE UI
  // ===========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIconHeader(),
                  const SizedBox(height: 32),
                  _buildTituloYDescripcion(),
                  const SizedBox(height: 32),
                  _buildCampoEmail(),
                  const SizedBox(height: 24),
                  _buildInfoBox(),
                  const SizedBox(height: 32),
                  _buildBotonEnviar(),
                  const SizedBox(height: 24),
                  _buildSeparador(),
                  const SizedBox(height: 16),
                  _buildBotonCodigoManual(),
                  _buildVolverLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // COMPONENTES DE UI
  // ===========================

  Widget _buildIconHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_reset,
        size: 80,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildTituloYDescripcion() {
    return Column(
      children: [
        const Text(
          '¿Olvidaste tu Contraseña?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No te preocupes. Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCampoEmail() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Correo Electrónico',
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
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recibirás un correo con un enlace que abrirá automáticamente la aplicación.',
              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonEnviar() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _recuperarPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
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
                'Enviar Enlace',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSeparador() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '¿No recibiste el enlace?',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildBotonCodigoManual() {
    return OutlinedButton.icon(
      onPressed: () => Navigator.pushNamed(context, '/ingresar-codigo'),
      icon: const Icon(Icons.vpn_key, size: 20),
      label: const Text('Ingresar código manualmente'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1565C0),
        side: const BorderSide(color: Color(0xFF1565C0)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildVolverLoginButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Volver al inicio de sesión'),
    );
  }
}
