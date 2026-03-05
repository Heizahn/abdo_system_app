import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system; // Por defecto, Sistema

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Carga la preferencia guardada al iniciar la app
  Future<void> _loadTheme() async {
    final savedTheme = await _storage.read(key: _themeKey);
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // Cambia el tema y lo guarda
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // Avisa a toda la app que se repinte

    String saveValue = 'system';
    if (mode == ThemeMode.light) saveValue = 'light';
    if (mode == ThemeMode.dark) saveValue = 'dark';

    await _storage.write(key: _themeKey, value: saveValue);
  }
}
