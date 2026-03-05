import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:abdo_system_app/config/env_config.dart';
import 'package:abdo_system_app/router/app_router.dart';
import 'package:abdo_system_app/theme/app_theme.dart';
import 'package:abdo_system_app/providers/auth_provider.dart';
import 'package:abdo_system_app/providers/theme_provider.dart';
import 'package:abdo_system_app/providers/provider_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProviderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'SYSTEM ABDO77',
      debugShowCheckedModeBanner: false,
      // Aquí conectamos tus temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // Cambia automático según el celular

      routerConfig: AppRouter.router,
    );
  }
}
