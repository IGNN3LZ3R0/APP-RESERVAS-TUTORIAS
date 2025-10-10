import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';

void main() {
  runApp(const TutoriasApp());
}

class TutoriasApp extends StatelessWidget {
  const TutoriasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESFOT Tutorías',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}