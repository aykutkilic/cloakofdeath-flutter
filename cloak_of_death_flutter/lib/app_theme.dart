import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF30505b); // Dark teal
  static const Color panel = Color(0xFF243b44); // Darker teal for panels
  static const Color text = Color(0xFFe0f2f1); // Light cyan text
  static const Color highlight = Color(
    0xFF46768b,
  ); // Lighter teal for selection
  static const Color border = Color(0xFF30505b); // Invisible or matching border
  static const Color mutedColor = Color(0xFF6B9496); // Muted Cyan
  static const Color warningColor = Color(0xFFD06060); // Red warning

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: text,
      scaffoldBackgroundColor: background,
      fontFamily: 'Atari',
      colorScheme: const ColorScheme.dark(primary: text, surface: background),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Atari'),
        bodySmall: TextStyle(fontFamily: 'Atari'),
        displaySmall: TextStyle(fontFamily: 'Atari'),
        displayMedium: TextStyle(fontFamily: 'Atari'),
        displayLarge: TextStyle(fontFamily: 'Atari'),
      ).apply(bodyColor: text, displayColor: text),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highlight,
          foregroundColor: text,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: const BorderSide(color: panel, width: 2),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.zero,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.zero,
        ),
        filled: true,
        fillColor: panel,
      ),
    );
  }
}
