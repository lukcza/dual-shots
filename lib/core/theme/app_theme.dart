import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0F0F12);
  static const Color surfaceDark = Color(0xFF18181E);
  static const Color surfaceOverlay = Color(0x9918181E);
  static const Color accentGold = Color(0xFFFFB800);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentCoral = Color(0xFFFF5252);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B8);
  static const Color pipBorderColor = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentGold,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentCyan,
        surface: surfaceDark,
        background: background,
        error: accentCoral,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
