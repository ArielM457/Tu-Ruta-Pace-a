import 'package:flutter/material.dart';

abstract final class CableCarLineColors {
  static const Color red = Color(0xFFD32F2F);
  static const Color yellow = Color(0xFFF9A825);
  static const Color green = Color(0xFF2E7D32);
  static const Color blue = Color(0xFF1565C0);
  static const Color skyBlue = Color(0xFF4FC3F7);
  static const Color orange = Color(0xFFEF6C00);
  static const Color white = Color(0xFFECEFF1);
  static const Color purple = Color(0xFF6A1B9A);
  static const Color brown = Color(0xFF5D4037);
  static const Color silver = Color(0xFF90A4AE);
}

abstract final class AppTheme {
  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: CableCarLineColors.red,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
