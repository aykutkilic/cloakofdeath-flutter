import 'package:flutter/material.dart';

/// Shared visual tokens: warm paper, candle brass, and a dark green interior.
class AppTheme {
  static const background = Color(0xFF101716);
  static const panel = Color(0xFF192320);
  static const text = Color(0xFFECE7DB);
  static const highlight = Color(0xFF2A4038);
  static const border = Color(0xFF34473E);
  static const mutedColor = Color(0xFFAFB9AE);
  static const warningColor = Color(0xFFEB9B8D);
  static const accent = Color(0xFFE0BB7A);

  static const label = TextStyle(
    fontSize: 11,
    letterSpacing: 1.7,
    fontWeight: FontWeight.w600,
    color: mutedColor,
  );

  static BoxDecoration get panelDecoration => BoxDecoration(
    color: panel,
    border: Border.all(color: border),
    borderRadius: BorderRadius.circular(16),
  );

  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      onPrimary: background,
      surface: panel,
      onSurface: text,
      secondary: mutedColor,
      error: warningColor,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: text),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: mutedColor),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: text,
      ),
    ),
    dividerColor: border,
    iconTheme: const IconThemeData(color: mutedColor, size: 22),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: highlight,
        foregroundColor: text,
        elevation: 0,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent),
      ),
    ),
  );
}
