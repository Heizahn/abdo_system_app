import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:abdo_system_app/config/env_config.dart';
import 'package:abdo_system_app/router/app_router.dart';
import 'package:abdo_system_app/theme/app_theme.dart';
import 'package:abdo_system_app/providers/auth_provider.dart';
import 'package:abdo_system_app/providers/theme_provider.dart';
import 'package:abdo_system_app/providers/provider_provider.dart';
import 'package:abdo_system_app/providers/client_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProviderProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
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

    // Determinar el brillo real (respetando tema del sistema si es auto)
    final brightness =
        themeProvider.themeMode == ThemeMode.dark ||
            (themeProvider.themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark)
        ? Brightness.dark
        : Brightness.light;

    // Aplicar el estilo del status bar globalmente para que cubra
    // todas las pantallas, incluso las que no tienen AppBar (ej. login)
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Íconos oscuros en tema claro, claros en tema oscuro
        statusBarIconBrightness: brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        // iOS: el valor es inverso (describe el fondo, no los íconos)
        statusBarBrightness: brightness,
      ),
    );

    return MaterialApp.router(
      title: 'SISTEMA ABDO77',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
