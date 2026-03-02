import 'package:flutter/material.dart';

class AppTheme {
  // --- TEMA CLARO ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB), // background.default
      
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: Color(0xFFEC6C03),
        surface: Color(0xFFFFFFFF), // background.paper
        error: Color(0xFFDC2626),
        // Colores de estado equivalentes a info, success, warning
        tertiary: Color(0xFF3B82F6), // info
        outline: Color(0xFFF59E0B), // warning (usado como outline o custom)
        onSurface: Color(0xFF1F2937), // text.primary
        onSurfaceVariant: Color(0xFF6B7280), // text.secondary
      ),

      // Equivalente a tu MuiTextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6B7280)),
        ),
      ),

      // Equivalente al scrollbar global en MuiCssBaseline
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6.0),
        radius: const Radius.circular(10),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0x4D000000); // rgba(0,0,0,0.3)
          }
          return const Color(0x26000000); // rgba(0,0,0,0.15)
        }),
        trackColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  // --- TEMA OSCURO ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111827), // background.default
      
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF5A95F5),
        secondary: Color(0xFFF7557E),
        surface: Color(0xFF1F2937), // background.paper
        error: Color(0xFFFF5252),
        tertiary: Color(0xFF3B82F6), // info
        outline: Color(0xFFF59E0B), // warning
        onSurface: Color(0xFFF9FAFB), // text.primary
        onSurfaceVariant: Color(0xFF9CA3AF), // text.secondary
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9CA3AF)),
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6.0),
        radius: const Radius.circular(10),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0x4DFFFFFF); // rgba(255,255,255,0.3)
          }
          return const Color(0x26FFFFFF); // rgba(255,255,255,0.15)
        }),
        trackColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}