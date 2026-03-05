// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Colores semánticos que no existen en ColorScheme (success).
/// Uso: `Theme.of(context).extension<AppColors>()!.success`
class AppColors extends ThemeExtension<AppColors> {
  final Color success;

  const AppColors({required this.success});

  @override
  AppColors copyWith({Color? success}) =>
      AppColors(success: success ?? this.success);

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(success: Color.lerp(success, other.success, t)!);
  }
}

class AppTheme {
  // Configuración de bordes moderna y compartida
  static final _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none, // Quitamos el borde visible
  );

  // --- TEMA CLARO ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),

      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: Color(0xFFEC6C03),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFDC2626),
        tertiary: Color(0xFF3B82F6), // info
        outline: Color(0xFFF59E0B), // warning
        onSurface: Color(0xFF1F2937),
        onSurfaceVariant: Color(0xFF6B7280),
      ),

      extensions: const [
        AppColors(success: Color(0xFF357C28)),
      ],

      // Refinamos los Inputs para un look más moderno
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.04), // Fondo muy tenue
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
        ),
        errorBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never, // Labels limpios
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
      ),

      // Estilo de botones moderno (sin sombras excesivas)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, // Planos, estilo Material 3
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  // --- TEMA OSCURO ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111827),

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF5A95F5),
        secondary: Color(0xFFF7557E),
        surface: Color(0xFF1F2937),
        error: Color(0xFFFF5252),
        tertiary: Color(0xFF3B82F6),
        outline: Color(0xFFF59E0B),
        onSurface: Color(0xFFF9FAFB),
        onSurfaceVariant: Color(0xFF9CA3AF),
      ),

      extensions: const [
        AppColors(success: Color(0xFF10B981)),
      ],

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder,
        enabledBorder: _inputBorder,
        focusedBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFF5A95F5), width: 1.5),
        ),
        errorBorder: _inputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
