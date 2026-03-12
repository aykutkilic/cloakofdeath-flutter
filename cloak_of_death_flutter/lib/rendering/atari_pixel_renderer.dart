import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'atari_bytecode_parser.dart';

/// A flat queue of plot(x, y, color) commands generated from room bytecode.
///
/// All drawing operations (lines, polygons, flood fills) are pre-expanded into
/// individual pixel plots. The queue can then be played back at any rate by
/// advancing a cursor and applying plots to a pixel buffer.
class PlotQueue {
  /// Packed pixel positions: y * canvasWidth + x
  final Int32List positions;

  /// ARGB color for each plot
  final Uint32List colors;

  /// Total number of plot operations
  final int length;

  /// Index into [positions]/[colors] where each bytecode command starts.
  /// commandBoundaries[i] is the first plot index for command i.
  /// An extra entry at the end equals [length] for easy range calculation.
  final List<int> commandBoundaries;

  /// The initial screen fill pixel buffer (before any commands).
  /// Used to initialize the playback buffer.
  final Uint32List screenFill;

  PlotQueue({
    required this.positions,
    required this.colors,
    required this.length,
    required this.commandBoundaries,
    required this.screenFill,
  });

  /// Apply plots from [startIndex] to [endIndex] (exclusive) onto [pixelBuffer].
  void applyRange(Uint32List pixelBuffer, int startIndex, int endIndex) {
    final end = endIndex.clamp(0, length);
    for (int i = startIndex; i < end; i++) {
      pixelBuffer[positions[i]] = colors[i];
    }
  }

  /// Create a fresh pixel buffer initialized with the screen fill pattern.
  Uint32List createBuffer() {
    return Uint32List.fromList(screenFill);
  }
}

/// Pixel-level renderer for Atari graphics.
///
/// Renders commands pixel-by-pixel using Bresenham's line algorithm
/// and scanline flood fill, matching the authentic Atari 65XE rendering.
class AtariPixelRenderer extends CustomPainter {
  final Uint32List? pixelBuffer;

  static const int canvasWidth = 160;
  static const int canvasHeight = 96;

  AtariPixelRenderer({
    this.pixelBuffer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelBuffer == null) return;

    final pixelWidth = size.width / canvasWidth;
    final pixelHeight = size.height / canvasHeight;

    // Group pixels by color for batch rendering
    final colorGroups = <int, List<Rect>>{};

    for (int y = 0; y < canvasHeight; y++) {
      for (int x = 0; x < canvasWidth; x++) {
        final argb = pixelBuffer![y * canvasWidth + x];
        colorGroups.putIfAbsent(argb, () => []);
        colorGroups[argb]!.add(
          Rect.fromLTWH(
            x * pixelWidth,
            y * pixelHeight,
            pixelWidth + 0.5,
            pixelHeight + 0.5,
          ),
        );
      }
    }

    for (final entry in colorGroups.entries) {
      final argb = entry.key;
      final rects = entry.value;

      final a = (argb >> 24) & 0xFF;
      final r = (argb >> 16) & 0xFF;
      final g = (argb >> 8) & 0xFF;
      final b = argb & 0xFF;

      final paint = Paint()
        ..color = Color.fromARGB(a, r, g, b)
        ..style = PaintingStyle.fill;

      for (final rect in rects) {
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(AtariPixelRenderer oldDelegate) {
    return oldDelegate.pixelBuffer != pixelBuffer;
  }

  // ---------------------------------------------------------------------------
  // Plot queue generation
  // ---------------------------------------------------------------------------

  /// Generate a complete plot queue from room bytecode.
  ///
  /// Walks all commands, expands each into individual plot(x, y, color) ops,
  /// and returns a [PlotQueue] that can be played back at any rate.
  static PlotQueue generatePlotQueue(AtariRoomBytecode roomData) {
    // Scratch buffer needed so flood fill can read boundary pixels
    final scratch = Uint32List(canvasWidth * canvasHeight);
    _fillScreenPattern(scratch, roomData.screenFillByte, roomData.palette);

    // Save the screen fill state
    final screenFill = Uint32List.fromList(scratch);

    // Accumulate plots in growable lists, then compact at the end
    final positionsList = <int>[];
    final colorsList = <int>[];
    final commandBoundaries = <int>[];

    Offset? lastPolyFirstPoint;
    Offset? lastPolyLastPoint;

    for (int cmdIdx = 0; cmdIdx < roomData.commands.length; cmdIdx++) {
      commandBoundaries.add(positionsList.length);
      final cmd = roomData.commands[cmdIdx];

      switch (cmd.type) {
        case BytecodeCommandType.polyline:
          final shouldClose = cmdIdx + 1 < roomData.commands.length &&
              roomData.commands[cmdIdx + 1].type ==
                  BytecodeCommandType.closedPolyline;
          final result = _genPolyline(
            scratch,
            positionsList,
            colorsList,
            cmd.points,
            roomData.palette[cmd.colorIndex ?? 0],
            shouldClose,
          );
          lastPolyFirstPoint = result.firstPoint;
          lastPolyLastPoint = result.lastPoint;
          break;

        case BytecodeCommandType.closedPolyline:
          if (cmd.points.isEmpty) {
            final fp = lastPolyFirstPoint;
            final lp = lastPolyLastPoint;
            if (fp != null && lp != null) {
              _genBresenhamLine(
                scratch,
                positionsList,
                colorsList,
                lp.dx.toInt(),
                lp.dy.toInt(),
                fp.dx.toInt(),
                fp.dy.toInt(),
                _colorToArgb(roomData.palette[cmd.colorIndex ?? 0]),
              );
            }
          } else {
            final result = _genPolyline(
              scratch,
              positionsList,
              colorsList,
              cmd.points,
              roomData.palette[cmd.colorIndex ?? 0],
              true,
            );
            lastPolyFirstPoint = result.firstPoint;
            lastPolyLastPoint = result.lastPoint;
          }
          break;

        case BytecodeCommandType.floodFill:
        case BytecodeCommandType.floodFillAt:
          final fillSeed = cmd.fillSeed;
          final fillPattern = cmd.fillPattern;
          if (fillSeed != null && fillPattern != null) {
            _genFloodFillAt(
              scratch,
              positionsList,
              colorsList,
              fillSeed,
              fillPattern,
              roomData.palette,
            );
          }
          break;
      }
    }

    // Sentinel boundary for easy range calculation
    commandBoundaries.add(positionsList.length);

    return PlotQueue(
      positions: Int32List.fromList(positionsList),
      colors: Uint32List.fromList(colorsList),
      length: positionsList.length,
      commandBoundaries: commandBoundaries,
      screenFill: screenFill,
    );
  }

  // ---------------------------------------------------------------------------
  // Plot-queue generation helpers (write to scratch buffer AND append to queue)
  // ---------------------------------------------------------------------------

  static _PolyPoints _genPolyline(
    Uint32List scratch,
    List<int> positions,
    List<int> colors,
    List<Offset> points,
    Color color,
    bool shouldClose,
  ) {
    if (points.isEmpty) return _PolyPoints(null, null);

    final argb = _colorToArgb(color);
    final segmentCount = shouldClose ? points.length : points.length - 1;

    for (int i = 0; i < segmentCount; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      _genBresenhamLine(
        scratch,
        positions,
        colors,
        p1.dx.toInt(),
        p1.dy.toInt(),
        p2.dx.toInt(),
        p2.dy.toInt(),
        argb,
      );
    }

    return _PolyPoints(points[0], points.last);
  }

  static void _genBresenhamLine(
    Uint32List scratch,
    List<int> positions,
    List<int> colors,
    int x0,
    int y0,
    int x1,
    int y1,
    int color,
  ) {
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;
    int x = x0;
    int y = y0;

    while (true) {
      if (x >= 0 && x < canvasWidth && y >= 0 && y < canvasHeight) {
        final pos = y * canvasWidth + x;
        scratch[pos] = color;
        positions.add(pos);
        colors.add(color);
      }

      if (x == x1 && y == y1) break;

      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
  }

  static void _genFloodFillAt(
    Uint32List scratch,
    List<int> positions,
    List<int> colors,
    Offset seed,
    int pattern,
    List<Color> palette,
  ) {
    final seedX = seed.dx.toInt();
    final seedY = seed.dy.toInt();

    if (seedX < 0 ||
        seedX >= canvasWidth ||
        seedY < 0 ||
        seedY >= canvasHeight) {
      return;
    }

    final targetColor = scratch[seedY * canvasWidth + seedX];

    int solidFillColor = 0;
    List<int>? patternColors;

    if (pattern <= 3) {
      solidFillColor = _colorToArgb(palette[pattern]);
    } else {
      patternColors = _decodePattern(pattern, palette);
    }

    if (patternColors == null && targetColor == solidFillColor) return;

    _genScanlineFill(
      scratch,
      positions,
      colors,
      seedX,
      seedY,
      targetColor,
      solidFillColor,
      patternColors,
    );
  }

  static void _genScanlineFill(
    Uint32List scratch,
    List<int> positions,
    List<int> colors,
    int startX,
    int startY,
    int targetColor,
    int fillColor,
    List<int>? patternColors,
  ) {
    if (startX < 0 ||
        startX >= canvasWidth ||
        startY < 0 ||
        startY >= canvasHeight) {
      return;
    }
    if (scratch[startY * canvasWidth + startX] != targetColor) return;

    for (int y = startY; y < canvasHeight; y++) {
      final rowBase = y * canvasWidth;
      if (scratch[rowBase + startX] != targetColor) break;

      int left = startX;
      while (left > 0 && scratch[rowBase + left - 1] == targetColor) {
        left--;
      }

      int right = startX;
      while (right < canvasWidth - 1 &&
          scratch[rowBase + right + 1] == targetColor) {
        right++;
      }

      for (int x = left; x <= right; x++) {
        final pos = rowBase + x;
        final c = patternColors != null ? patternColors[x % 4] : fillColor;
        scratch[pos] = c;
        positions.add(pos);
        colors.add(c);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Shared utilities
  // ---------------------------------------------------------------------------

  static void _fillScreenPattern(
    Uint32List pixelData,
    int fillByte,
    List<Color> palette,
  ) {
    final fillColors = [
      _colorToArgb(palette[(fillByte >> 6) & 0x03]),
      _colorToArgb(palette[(fillByte >> 4) & 0x03]),
      _colorToArgb(palette[(fillByte >> 2) & 0x03]),
      _colorToArgb(palette[fillByte & 0x03]),
    ];

    if (fillColors[0] == fillColors[1] &&
        fillColors[1] == fillColors[2] &&
        fillColors[2] == fillColors[3]) {
      pixelData.fillRange(0, pixelData.length, fillColors[0]);
    } else {
      for (int i = 0; i < pixelData.length; i++) {
        pixelData[i] = fillColors[i % 4];
      }
    }
  }

  static List<int> _decodePattern(int pattern, List<Color> palette) {
    return [
      _colorToArgb(palette[(pattern >> 6) & 0x03]),
      _colorToArgb(palette[(pattern >> 4) & 0x03]),
      _colorToArgb(palette[(pattern >> 2) & 0x03]),
      _colorToArgb(palette[pattern & 0x03]),
    ];
  }

  static int _colorToArgb(Color color) {
    return ((color.a * 255.0).round().clamp(0, 255) << 24) |
        ((color.r * 255.0).round().clamp(0, 255) << 16) |
        ((color.g * 255.0).round().clamp(0, 255) << 8) |
        (color.b * 255.0).round().clamp(0, 255);
  }
}

// ---------------------------------------------------------------------------
// Internal helper
// ---------------------------------------------------------------------------

class _PolyPoints {
  final Offset? firstPoint;
  final Offset? lastPoint;
  _PolyPoints(this.firstPoint, this.lastPoint);
}
