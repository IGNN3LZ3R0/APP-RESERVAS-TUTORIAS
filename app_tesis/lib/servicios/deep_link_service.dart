import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../servicios/auth_service.dart';
import '../config/routes.dart';

class DeepLinkService {
  static const platform = MethodChannel('com.example.app_tesis/deeplink');
  static StreamController<String>? _streamController;
  
  static Future<void> initialize() async {
    _streamController = StreamController<String>.broadcast();
    
    platform.setMethodCallHandler((call) async {
      print('📱 [DeepLink] Method call: ${call.method}');
      if (call.method == 'onDeepLink') {
        final String? link = call.arguments;
        print('📱 [DeepLink] Link recibido: $link');
        if (link != null) {
          _streamController?.add(link);
        }
      }
    });
    
    try {
      final String? initialLink = await platform.invokeMethod('getInitialLink');
      if (initialLink != null) {
        print('📱 [DeepLink] Link inicial: $initialLink');
        _streamController?.add(initialLink);
      }
    } catch (e) {
      print('❌ [DeepLink] Error obteniendo link inicial: $e');
    }
  }

  static Stream<String>? get deepLinkStream => _streamController?.stream;

  static void handleDeepLink(BuildContext context, String link) {
    print('🔗 [DeepLink] Procesando: $link');
    
    final uri = Uri.parse(link);
    
    print('📱 [DeepLink] Host: ${uri.host}');
    print('📱 [DeepLink] PathSegments: ${uri.pathSegments}');

    if (uri.host == 'confirm') {
      String? token;
      
      if (uri.pathSegments.isNotEmpty) {
        token = uri.pathSegments[0];
      } else if (uri.path.isNotEmpty && uri.path != '/') {
        token = uri.path.replaceFirst('/', '');
      }
      
      if (token != null && token.isNotEmpty) {
        print('✅ [DeepLink] Token confirmación: $token');
        _handleConfirmAccount(context, token);
      } else {
        print('❌ [DeepLink] Token no encontrado');
        _mostrarError(context, 'Link de confirmación inválido');
      }
      return;
    }

    if (uri.host == 'reset-password') {
      String? token;
      
      if (uri.pathSegments.isNotEmpty) {
        token = uri.pathSegments[0];
      } else if (uri.path.isNotEmpty && uri.path != '/') {
        token = uri.path.replaceFirst('/', '');
      }
      
      if (token != null && token.isNotEmpty) {
        print('✅ [DeepLink] Token reset: $token');
        _handleResetPassword(context, token);
      } else {
        print('❌ [DeepLink] Token reset no encontrado');
        _mostrarError(context, 'Link de recuperación inválido');
      }
      return;
    }

    print('⚠️ [DeepLink] Link no reconocido: $link');
  }

  static Future<void> _handleConfirmAccount(BuildContext context, String token) async {
    print('✅ [DeepLink] Confirmando cuenta...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Activando tu cuenta...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final resultado = await AuthService.confirmarEmail(token);

      if (!context.mounted) return;
      Navigator.pop(context);

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(context, resultado['error']);
      } else {
        _mostrarExito(context, '¡Cuenta activada exitosamente!\nYa puedes iniciar sesión.');
        
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

  static Future<void> _handleResetPassword(BuildContext context, String token) async {
    print('🔐 [DeepLink] Restableciendo contraseña...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Validando token...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final resultado = await AuthService.comprobarTokenPassword(token);

      if (!context.mounted) return;
      Navigator.pop(context);

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(context, resultado['error']);
      } else {
        Navigator.pushNamed(context, '/nueva-password', arguments: token);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _mostrarError(context, 'Error al validar token: $e');
    }
  }

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

  static void dispose() {
    _streamController?.close();
  }
}