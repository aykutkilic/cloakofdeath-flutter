import 'dart:ui';

/// Atari 8-bit color palette conversion
///
/// Atari color byte format: [HHHH][LLLL]
///   - Hue (upper 4 bits): 0-15 (color type)
///   - Luminance (lower 4 bits): 0-14 (brightness)
///   - Formula: Color = Hue × 16 + Luminance
///   - Hex: $HL where H=hue, L=luminance
///
/// Reference: https://atariwiki.org/wiki/Wiki.jsp?page=Color%20names
class AtariColors {
  /// Convert Atari color byte (0-255) to Flutter Color (RGB)
  static Color atariColorToRgb(int atariColor) {
    if (atariColor < 0 || atariColor > 255) {
      return const Color(0xFF000000); // Black for invalid colors
    }

    final hue = (atariColor >> 4) & 0x0F; // Upper 4 bits
    final luminance = atariColor & 0x0F;  // Lower 4 bits

    return _atariPalette[atariColor] ?? _generateColor(hue, luminance);
  }

  /// Alias for atariColorToRgb for backwards compatibility
  static Color fromAtariByte(int atariColor) => atariColorToRgb(atariColor);

  /// Generate RGB color from hue and luminance
  static Color _generateColor(int hue, int lum) {
    // Luminance scale: 0 = darkest, 14 = brightest
    final brightness = (lum / 14.0).clamp(0.0, 1.0);

    // Base colors for each hue
    switch (hue) {
      case 0x0: // Grays (black to white)
        final gray = (brightness * 255).round();
        return Color.fromARGB(255, gray, gray, gray);

      case 0x1: // Brown to gold (Rust)
        return Color.fromARGB(
          255,
          (139 * brightness).round(),
          (90 * brightness).round(),
          (43 * brightness).round(),
        );

      case 0x2: // Orange to yellow (Red-orange)
        return Color.fromARGB(
          255,
          (255 * brightness).round(),
          (140 * brightness).round(),
          (0 * brightness).round(),
        );

      case 0x3: // Terracotta to pink (Dark Orange)
        return Color.fromARGB(
          255,
          (205 * brightness).round(),
          (92 * brightness).round(),
          (92 * brightness).round(),
        );

      case 0x4: // Dark red to magenta (Red)
        return Color.fromARGB(
          255,
          (139 * brightness).round(),
          (0 * brightness).round(),
          (0 * brightness).round(),
        );

      case 0x5: // Violet to light blue (Dark lavender)
        return Color.fromARGB(
          255,
          (138 * brightness).round(),
          (43 * brightness).round(),
          (226 * brightness).round(),
        );

      case 0x6: // Blue
        return Color.fromARGB(
          255,
          (0 * brightness).round(),
          (0 * brightness).round(),
          (139 * brightness).round(),
        );

      case 0x7: // Blue (lighter variant)
        return Color.fromARGB(
          255,
          (65 * brightness).round(),
          (105 * brightness).round(),
          (225 * brightness).round(),
        );

      case 0x8: // Blue (medium variant)
        return Color.fromARGB(
          255,
          (0 * brightness).round(),
          (139 * brightness).round(),
          (139 * brightness).round(),
        );

      case 0x9: // Cyan/Blue
        return Color.fromARGB(
          255,
          (0 * brightness).round(),
          (180 * brightness).round(),
          (180 * brightness).round(),
        );

      case 0xA: // Green-cyan
        return Color.fromARGB(
          255,
          (0 * brightness).round(),
          (128 * brightness).round(),
          (128 * brightness).round(),
        );

      case 0xB: // Green
        return Color.fromARGB(
          255,
          (0 * brightness).round(),
          (139 * brightness).round(),
          (0 * brightness).round(),
        );

      case 0xC: // Yellow-green
        return Color.fromARGB(
          255,
          (154 * brightness).round(),
          (205 * brightness).round(),
          (50 * brightness).round(),
        );

      case 0xD: // Orange-green
        return Color.fromARGB(
          255,
          (218 * brightness).round(),
          (165 * brightness).round(),
          (32 * brightness).round(),
        );

      case 0xE: // Orange
        return Color.fromARGB(
          255,
          (255 * brightness).round(),
          (165 * brightness).round(),
          (0 * brightness).round(),
        );

      case 0xF: // Light orange/gold
        return Color.fromARGB(
          255,
          (255 * brightness).round(),
          (215 * brightness).round(),
          (0 * brightness).round(),
        );

      default:
        return const Color(0xFF000000);
    }
  }

  /// Pre-computed Atari palette for common colors
  /// This can be expanded with exact Atari color values
  static final Map<int, Color> _atariPalette = {
    // Hue 0 - Grays
    0x00: const Color(0xFF000000), // Black
    0x0F: const Color(0xFFFFFFFF), // White
    0x04: const Color(0xFF404040), // Dark gray
    0x08: const Color(0xFF808080), // Medium gray
    0x0C: const Color(0xFFC0C0C0), // Light gray

    // Common browns (Hue 1)
    0x14: const Color(0xFF3B2414), // Dark brown
    0x18: const Color(0xFF5A3A1A), // Brown
    0x1C: const Color(0xFF8B5A2B), // Light brown

    // Common reds (Hue 4)
    0x44: const Color(0xFF8B0000), // Dark red
    0x48: const Color(0xFFB22222), // Firebrick
    0x4C: const Color(0xFFDC143C), // Crimson

    // Common blues (Hue 9)
    0x94: const Color(0xFF4169E1), // Royal blue
    0x98: const Color(0xFF5F9EA0), // Cadet blue
    0x9C: const Color(0xFF87CEEB), // Sky blue

    // Specific known colors from analysis
    0x55: const Color(0xFF8B43E1), // Violet/lavender (Room 1)
    0xE2: const Color(0xFFFFA500), // Orange (Room 1)
    0xF5: const Color(0xFFFFD700), // Gold (Room 2)
  };

  /// Get color name for debugging
  static String getColorName(int atariColor) {
    final hue = (atariColor >> 4) & 0x0F;
    final lum = atariColor & 0x0F;

    final hueName = _hueNames[hue] ?? 'Unknown';
    final lumName = _getLuminanceName(lum);

    return '$hueName ($lumName) [\$${atariColor.toRadixString(16).padLeft(2, '0').toUpperCase()}]';
  }

  static const Map<int, String> _hueNames = {
    0x0: 'Gray',
    0x1: 'Brown/Rust',
    0x2: 'Red-Orange',
    0x3: 'Dark Orange',
    0x4: 'Red',
    0x5: 'Violet/Lavender',
    0x6: 'Blue',
    0x7: 'Light Blue',
    0x8: 'Blue-Cyan',
    0x9: 'Cyan',
    0xA: 'Green-Cyan',
    0xB: 'Green',
    0xC: 'Yellow-Green',
    0xD: 'Orange-Green',
    0xE: 'Orange',
    0xF: 'Gold',
  };

  static String _getLuminanceName(int lum) {
    if (lum == 0) return 'Black';
    if (lum <= 4) return 'Very Dark';
    if (lum <= 8) return 'Dark';
    if (lum <= 12) return 'Bright';
    return 'Very Bright';
  }
}
