import 'package:flutter/material.dart';
import 'package:abdo_system_app/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SYSTEM ADBO77',
      debugShowCheckedModeBanner: false,
      // Aquí conectamos tus temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Cambia automático según el celular
      
      home: const Scaffold(
        body: Center(
          child: Text('Preparando la UI...'),
        ),
      ),
    );
  }
}