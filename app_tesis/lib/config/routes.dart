import 'package:flutter/material.dart';
import '../pantallas/splash_screen.dart';
import '../pantallas/login_screen.dart';
import '../pantallas/registro_screen.dart';
import '../pantallas/home_screen.dart';
import '../modelos/usuario.dart';

class AppRoutes {
  // Nombres de las rutas
  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String home = '/home';

  // Mapa de rutas estáticas
  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      registro: (context) => const RegistroScreen(),
    };
  }

  // Generador de rutas dinámicas (para pasar argumentos)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        final usuario = settings.arguments as Usuario?;
        if (usuario == null) {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (context) => HomeScreen(usuario: usuario),
        );

      default:
        return null;
    }
  }

  // ========== MÉTODOS DE NAVEGACIÓN REUTILIZABLES ==========

  /// Navega a una ruta reemplazando la actual
  static Future<T?> pushReplacement<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, void>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navega a una ruta
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navega eliminando todas las rutas anteriores
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Regresa a la pantalla anterior
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  /// Verifica si se puede regresar
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }

  /// Navega al home según el rol del usuario
  static Future<void> navigateToHome(
    BuildContext context,
    Usuario usuario,
  ) {
    return pushAndRemoveUntil(context, home, arguments: usuario);
  }

  /// Navega al login limpiando el stack
  static Future<void> navigateToLogin(BuildContext context) {
    return pushAndRemoveUntil(context, login);
  }

  /// Navega a registro
  static Future<void> navigateToRegistro(BuildContext context) {
    return push(context, registro);
  }
}