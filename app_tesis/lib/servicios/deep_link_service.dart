// lib/servicios/deep_link_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../servicios/auth_service.dart';
import '../config/routes.dart';

class DeepLinkService {
  static const platform = MethodChannel('com.example.app_tesis/deeplink');
  static StreamController<String>? _streamController;
  
  /// Inicializa el servicio de deep links
  static Future<void> initialize() async {
    _streamController = StreamController<String>.broadcast();
    
    // Escuchar cuando la app se abre con un deep link
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final String? link = call.arguments;
        if (link != null) {
          _streamController?.add(link);
        }
      }
    });
  }

  /// Obtiene el stream de deep links
  static Stream<String>? get deepLinkStream => _streamController?.stream;

  /// Maneja deep links cuando la app ya está abierta
  static void handleDeepLink(BuildContext context, String link) {
    final uri = Uri.parse(link);
    
    print('📱 Deep link recibido: $link');
    print('📱 Scheme: ${uri.scheme}');
    print('📱 Host: ${uri.host}');
    print('📱 Path: ${uri.path}');
    print('📱 Segments: ${uri.pathSegments}');

    // myapp://confirm/{token}
    if (uri.host == 'confirm' && uri.pathSegments.isNotEmpty) {
      final token = uri.pathSegments[0];
      _handleConfirmAccount(context, token);
      return;
    }

    // myapp://reset-password/{token}
    if (uri.host == 'reset-password' && uri.pathSegments.isNotEmpty) {
      final token = uri.pathSegments[0];
      _handleResetPassword(context, token);
      return;
    }

    // Si no coincide con ningún patrón conocido
    print('⚠️ Deep link no reconocido: $link');
  }

  /// Confirma la cuenta del usuario
  static Future<void> _handleConfirmAccount(BuildContext context, String token) async {
    print('✅ Confirmando cuenta con token: $token');

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final resultado = await AuthService.confirmarEmail(token);

      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(context, resultado['error']);
      } else {
        _mostrarExito(
          context,
          '¡Cuenta activada exitosamente! Ya puedes iniciar sesión.',
        );
        
        // Navegar a login después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (!context.mounted) return;
        AppRoutes.navigateToLogin(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _mostrarError(context, 'Error al confirmar cuenta: $e');
    }
  }

  /// Maneja el restablecimiento de contraseña
  static Future<void> _handleResetPassword(BuildContext context, String token) async {
    print('🔐 Restableciendo contraseña con token: $token');

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final resultado = await AuthService.comprobarTokenPassword(token);

      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(context, resultado['error']);
      } else {
        // Token válido, navegar a pantalla de nueva contraseña
        Navigator.pushNamed(
          context,
          '/nueva-password',
          arguments: token,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _mostrarError(context, 'Error al validar token: $e');
    }
  }

  /// Muestra mensaje de error
  static void _mostrarError(BuildContext context, String mensaje) {
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Muestra mensaje de éxito
  static void _mostrarExito(BuildContext context, String mensaje) {
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Limpia recursos
  static void dispose() {
    _streamController?.close();
  }
}