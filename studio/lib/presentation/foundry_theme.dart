import 'package:flutter/material.dart';

abstract final class FoundryColors {
  static const Color ink = Color(0xFF18201F);
  static const Color paper = Color(0xFFF1EBDD);
  static const Color paperLight = Color(0xFFFAF7EE);
  static const Color line = Color(0xFFCDC4B1);
  static const Color orange = Color(0xFFFF5B36);
  static const Color blue = Color(0xFF1F55D5);
  static const Color muted = Color(0xFF696F69);
  static const Color success = Color(0xFF14764B);
}

ThemeData buildFoundryTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: FoundryColors.blue,
    brightness: Brightness.light,
    surface: FoundryColors.paperLight,
  );
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: FoundryColors.paper,
    colorScheme: scheme.copyWith(
      primary: FoundryColors.ink,
      secondary: FoundryColors.orange,
      outline: FoundryColors.line,
      outlineVariant: FoundryColors.line.withOpacity(0.7),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FoundryColors.paperLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: FoundryColors.ink, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: FoundryColors.ink, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: FoundryColors.blue, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FoundryColors.ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
