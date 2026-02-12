import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatrixTheme {
  static const Color background = Color(0xFF0D0208);
  static const Color primaryGreen = Color(0xFF00FF41);
  static const Color dimGreen = Color(0xFF00994D);
  static const Color darkGreen = Color(0xFF003B00);
  static const Color surfaceColor = Color(0xFF0A1A0F);

  static const List<Color> cardColors = [
    Color(0xFF0A2E2A), // dark teal
    Color(0xFF1A0A2E), // dark purple
    Color(0xFF0A1A2E), // dark blue
    Color(0xFF2E1A0A), // dark amber
    Color(0xFF0A2E1A), // dark emerald
    Color(0xFF2E0A1A), // dark magenta
  ];

  static List<Shadow> glowShadow({Color? color, double blurRadius = 8}) {
    final c = color ?? primaryGreen;
    return [
      Shadow(color: c.withValues(alpha: 0.7), blurRadius: blurRadius),
    ];
  }

  static TextTheme _textTheme() {
    return GoogleFonts.shareTechMonoTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: primaryGreen),
        displayMedium: TextStyle(color: primaryGreen),
        displaySmall: TextStyle(color: primaryGreen),
        headlineLarge: TextStyle(color: primaryGreen),
        headlineMedium: TextStyle(color: primaryGreen),
        headlineSmall: TextStyle(color: primaryGreen),
        titleLarge: TextStyle(color: primaryGreen),
        titleMedium: TextStyle(color: primaryGreen),
        titleSmall: TextStyle(color: primaryGreen),
        bodyLarge: TextStyle(color: primaryGreen),
        bodyMedium: TextStyle(color: primaryGreen),
        bodySmall: TextStyle(color: dimGreen),
        labelLarge: TextStyle(color: primaryGreen),
        labelMedium: TextStyle(color: primaryGreen),
        labelSmall: TextStyle(color: dimGreen),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(),
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        onPrimary: background,
        surface: surfaceColor,
        onSurface: primaryGreen,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryGreen,
        elevation: 0,
        titleTextStyle: GoogleFonts.shareTechMono(
          color: primaryGreen,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: glowShadow(blurRadius: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: background,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryGreen.withValues(alpha: 0.2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        labelStyle: const TextStyle(color: dimGreen),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryGreen.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
