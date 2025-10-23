// lib/main.dart
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'servicios/deep_link_service.dart';
import 'pantallas/nueva_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar servicio de deep links
  await DeepLinkService.initialize();
  
  runApp(const TutoriasApp());
}

class TutoriasApp extends StatefulWidget {
  const TutoriasApp({super.key});

  @override
  State<TutoriasApp> createState() => _TutoriasAppState();
}

class _TutoriasAppState extends State<TutoriasApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
  }

  void _listenToDeepLinks() {
    DeepLinkService.deepLinkStream?.listen((String link) {
      print('🔗 Deep link detectado en app: $link');
      
      // Esperar un momento para que el navigator esté listo
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          DeepLinkService.handleDeepLink(context, link);
        }
      });
    });
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESFOT Tutorías',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      routes: {
        ...AppRoutes.routes,
        '/nueva-password': (context) => const NuevaPasswordScreen(),
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}