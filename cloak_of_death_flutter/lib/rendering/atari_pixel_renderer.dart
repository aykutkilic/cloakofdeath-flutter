import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'atari_bytecode_parser.dart';

/// Pixel-level renderer for Atari graphics (Synchronous version)
///
/// Renders commands pixel-by-pixel using Bresenham's line algorithm
/// and scanline flood fill, matching the authentic Atari 65XE rendering.
///
/// Fill algorithm: Pure target-color matching (no boundary mask).
/// On the real Atari, fills work by replacing pixels that match the color
/// at the seed point, stopping at any pixel of a different color (polygon edges).
class AtariPixelRenderer extends CustomPainter {
  final AtariRoomBytecode roomData;
  final int? maxCommandIndex; // null = render all
  final int? maxPixelCount; // null = render all pixels
  final ui.Image? cachedImage; // Pre-rendered image
  final Uint32List? pixelBuffer; // Direct pixel buffer for fast rendering

  // 160-pixel wide canvas (Atari resolution)
  static const int canvasWidth = 160;
  static const int canvasHeight = 96; // Typical Atari graphics height

  AtariPixelRenderer({
    required this.roomData,
    this.maxCommandIndex,
    this.maxPixelCount,
    this.cachedImage,
    this.pixelBuffer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pixelBuffer != null) {
      // Fast path: draw pixel buffer stretched to canvas size
      final pixelWidth = size.width / canvasWidth;
      final pixelHeight = size.height / canvasHeight;

      // Group pixels by color for batch rendering
      final colorGroups = <int, List<Rect>>{};

      for (int y = 0; y < canvasHeight; y++) {
        for (int x = 0; x < canvasWidth; x++) {
          final argb = pixelBuffer![y * canvasWidth + x];
          colorGroups.putIfAbsent(argb, () => []);
          // Create pixel rectangles matching the aspect ratio
          colorGroups[argb]!.add(
            Rect.fromLTWH(
              x * pixelWidth,
              y * pixelHeight,
              pixelWidth + 0.5, // slight overlap to avoid visual seams
              pixelHeight + 0.5,
            ),
          );
        }
      }

      // Draw each color group with a single paint operation
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

        // Draw all rects for this color
        for (final rect in rects) {
          canvas.drawRect(rect, paint);
        }
      }
    } else if (cachedImage != null) {
      // Cached image path (for completed rendering)
      canvas.drawImageRect(
        cachedImage!,
        Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      // Fallback: draw background using screen fill dominant color
      final fillPixelValue = (roomData.screenFillByte >> 6) & 0x03;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = roomData.palette[fillPixelValue],
      );
    }
  }

  @override
  bool shouldRepaint(AtariPixelRenderer oldDelegate) {
    return oldDelegate.cachedImage != cachedImage ||
        oldDelegate.pixelBuffer != pixelBuffer ||
        oldDelegate.maxCommandIndex != maxCommandIndex ||
        oldDelegate.maxPixelCount != maxPixelCount;
  }

  /// Fast synchronous rendering - returns pixel buffer directly (no image conversion)
  static PixelRenderResult renderToPixelBuffer(
    AtariRoomBytecode roomData, {
    int? maxCommandIndex,
    int pixelBudget = 0x7FFFFFFFFFFFFFFF,
    Uint32List? existingPixelBuffer,
    int startCommandIndex = 0,
    Offset? lastPolyFirstPoint,
    Offset? lastPolyLastPoint,
  }) {
    // Reuse existing buffer or create a fresh one with screen fill
    final pixelData = existingPixelBuffer ??
        (() {
          final buf = Uint32List(canvasWidth * canvasHeight);
          _fillScreenPattern(buf, roomData.screenFillByte, roomData.palette);
          return buf;
        })();

    int remaining = pixelBudget;

    // Render commands from startCommandIndex up to maxCommandIndex
    final commandLimit = maxCommandIndex ?? roomData.commands.length - 1;
    Offset? lastPolylineFirstPoint = lastPolyFirstPoint;
    Offset? lastPolylineLastPoint = lastPolyLastPoint;
    int lastRenderedCmd = startCommandIndex;

    for (
      int cmdIdx = startCommandIndex;
      cmdIdx <= commandLimit && cmdIdx < roomData.commands.length;
      cmdIdx++
    ) {
      // Check budget BEFORE starting a command — each command runs to completion
      if (remaining <= 0) break;

      lastRenderedCmd = cmdIdx;
      final cmd = roomData.commands[cmdIdx];
      int drawn = 0;

      switch (cmd.type) {
        case BytecodeCommandType.polyline:
          final bool shouldClose =
              cmdIdx + 1 < roomData.commands.length &&
              roomData.commands[cmdIdx + 1].type ==
                  BytecodeCommandType.closedPolyline;

          final result = _drawPolyline(
            pixelData,
            cmd.points,
            roomData.palette[cmd.colorIndex ?? 0],
            shouldClose,
          );
          drawn = result.pixelsDrawn;
          lastPolylineFirstPoint = result.firstPoint;
          lastPolylineLastPoint = result.lastPoint;
          break;

        case BytecodeCommandType.closedPolyline:
          if (cmd.points.isEmpty) {
            final fp = lastPolylineFirstPoint;
            final lp = lastPolylineLastPoint;
            if (fp != null && lp != null) {
              drawn = _bresenhamLine(
                pixelData,
                lp.dx.toInt(),
                lp.dy.toInt(),
                fp.dx.toInt(),
                fp.dy.toInt(),
                _colorToArgb(roomData.palette[cmd.colorIndex ?? 0]),
              );
            }
          } else {
            final result = _drawPolyline(
              pixelData,
              cmd.points,
              roomData.palette[cmd.colorIndex ?? 0],
              true,
            );
            drawn = result.pixelsDrawn;
            lastPolylineFirstPoint = result.firstPoint;
            lastPolylineLastPoint = result.lastPoint;
          }
          break;

        case BytecodeCommandType.floodFill:
        case BytecodeCommandType.floodFillAt:
          final fillSeed = cmd.fillSeed;
          final fillPattern = cmd.fillPattern;
          if (fillSeed != null && fillPattern != null) {
            drawn = _floodFillAt(
              pixelData,
              fillSeed,
              fillPattern,
              roomData.palette,
            );
          }
          break;
      }

      remaining -= drawn;
    }

    return PixelRenderResult(
      pixelData,
      lastRenderedCmd,
      remaining > 0,
      lastPolylineFirstPoint,
      lastPolylineLastPoint,
    );
  }

  /// Create pixel buffer and render it to an image
  static Future<RenderResult> renderToImage(
    AtariRoomBytecode roomData, {
    int? maxCommandIndex,
  }) async {
    final result = renderToPixelBuffer(
      roomData,
      maxCommandIndex: maxCommandIndex,
    );

    // Convert pixel buffer to image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      result.pixelBuffer.buffer.asUint8List(),
      canvasWidth,
      canvasHeight,
      ui.PixelFormat.bgra8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    final image = await completer.future;
    return RenderResult(image, result.lastCommandIndex);
  }

  /// Draw polyline using Bresenham's algorithm
  static PolylineResult _drawPolyline(
    Uint32List pixels,
    List<Offset> points,
    Color color,
    bool shouldClose,
  ) {
    if (points.isEmpty) {
      return PolylineResult(0, null, null);
    }

    final firstPoint = points[0];
    int totalDrawn = 0;
    final argb = _colorToArgb(color);

    final segmentCount = shouldClose ? points.length : points.length - 1;

    for (int i = 0; i < segmentCount; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      totalDrawn += _bresenhamLine(
        pixels,
        p1.dx.toInt(),
        p1.dy.toInt(),
        p2.dx.toInt(),
        p2.dy.toInt(),
        argb,
      );
    }

    return PolylineResult(totalDrawn, firstPoint, points.last);
  }

  /// Bresenham's line algorithm. Returns number of pixels drawn.
  static int _bresenhamLine(
    Uint32List pixels,
    int x0,
    int y0,
    int x1,
    int y1,
    int color,
  ) {
    int drawn = 0;

    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    int x = x0;
    int y = y0;

    while (true) {
      if (x >= 0 && x < canvasWidth && y >= 0 && y < canvasHeight) {
        pixels[y * canvasWidth + x] = color;
        drawn++;
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

    return drawn;
  }

  /// Flood fill at a seed point using target-color matching.
  ///
  /// This matches the real Atari fill behavior: the fill replaces all pixels
  /// that match the color at the seed point, stopping at any pixel of a
  /// different color (e.g. polygon edges drawn in a different color).
  /// Flood fill at a seed point. Returns number of pixels drawn.
  static int _floodFillAt(
    Uint32List pixels,
    Offset seed,
    int pattern,
    List<Color> palette,
  ) {
    int seedX = seed.dx.toInt();
    int seedY = seed.dy.toInt();

    if (seedX < 0 ||
        seedX >= canvasWidth ||
        seedY < 0 ||
        seedY >= canvasHeight) {
      return 0;
    }

    final targetColor = pixels[seedY * canvasWidth + seedX];

    // Determine fill color(s)
    int solidFillColor = 0;
    List<int>? patternColors;

    if (pattern <= 3) {
      solidFillColor = _colorToArgb(palette[pattern]);
    } else {
      patternColors = _decodePattern(pattern, palette);
    }

    if (patternColors == null && targetColor == solidFillColor) {
      return 0;
    }

    return _scanlineFill(
      pixels,
      seedX,
      seedY,
      targetColor,
      solidFillColor,
      patternColors,
    );
  }

  /// Scanline flood fill using target-color matching.
  ///
  /// Fills all connected pixels matching targetColor, replacing them with
  /// fillColor (or patternColors if non-null). Stops at any pixel that
  /// doesn't match targetColor.
  /// Simple downward scanline fill matching the Atari FILL routine.
  /// Starts at seed point, scans left/right on each row, fills, moves down.
  /// Returns number of pixels drawn.
  static int _scanlineFill(
    Uint32List pixels,
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
      return 0;
    }

    if (pixels[startY * canvasWidth + startX] != targetColor) {
      return 0;
    }

    int drawn = 0;

    for (int y = startY; y < canvasHeight; y++) {
      final rowBase = y * canvasWidth;

      // Stop if the seed column is no longer fillable
      if (pixels[rowBase + startX] != targetColor) break;

      // Scan left from seed column
      int left = startX;
      while (left > 0 && pixels[rowBase + left - 1] == targetColor) {
        left--;
      }

      // Scan right from seed column
      int right = startX;
      while (right < canvasWidth - 1 &&
          pixels[rowBase + right + 1] == targetColor) {
        right++;
      }

      // Fill the row
      for (int x = left; x <= right; x++) {
        pixels[rowBase + x] =
            patternColors != null ? patternColors[x % 4] : fillColor;
        drawn++;
      }
    }

    return drawn;
  }

  /// Fill pixel buffer with the screen fill byte pattern
  /// On the Atari, the DRAW routine fills every byte of screen memory with this value.
  /// Each byte = 4 pixels (2 bits each), so the pattern repeats every 4 pixels.
  static void _fillScreenPattern(
    Uint32List pixelData,
    int fillByte,
    List<Color> palette,
  ) {
    // Decode fill byte into 4 pixel color indices (2 bits each, MSB first)
    final fillColors = [
      _colorToArgb(palette[(fillByte >> 6) & 0x03]),
      _colorToArgb(palette[(fillByte >> 4) & 0x03]),
      _colorToArgb(palette[(fillByte >> 2) & 0x03]),
      _colorToArgb(palette[fillByte & 0x03]),
    ];

    // Check if all 4 pixels are the same (uniform fill, common case)
    if (fillColors[0] == fillColors[1] &&
        fillColors[1] == fillColors[2] &&
        fillColors[2] == fillColors[3]) {
      pixelData.fillRange(0, pixelData.length, fillColors[0]);
    } else {
      // Pattern fill: repeat 4-pixel pattern across canvas
      for (int i = 0; i < pixelData.length; i++) {
        pixelData[i] = fillColors[i % 4];
      }
    }
  }

  /// Decode 4-column pattern byte to ARGB colors
  static List<int> _decodePattern(int pattern, List<Color> palette) {
    return [
      _colorToArgb(palette[(pattern >> 6) & 0x03]),
      _colorToArgb(palette[(pattern >> 4) & 0x03]),
      _colorToArgb(palette[(pattern >> 2) & 0x03]),
      _colorToArgb(palette[pattern & 0x03]),
    ];
  }

  /// Convert Color to ARGB int
  static int _colorToArgb(Color color) {
    return ((color.a * 255.0).round().clamp(0, 255) << 24) |
        ((color.r * 255.0).round().clamp(0, 255) << 16) |
        ((color.g * 255.0).round().clamp(0, 255) << 8) |
        (color.b * 255.0).round().clamp(0, 255);
  }
}

// Helper classes
class PolylineResult {
  final int pixelsDrawn;
  final Offset? firstPoint;
  final Offset? lastPoint;
  PolylineResult(this.pixelsDrawn, [this.firstPoint, this.lastPoint]);
}


class RenderResult {
  final ui.Image image;
  final int lastCommandIndex;
  RenderResult(this.image, this.lastCommandIndex);
}

class PixelRenderResult {
  final Uint32List pixelBuffer;
  final int lastCommandIndex;
  final bool isComplete;
  final Offset? lastPolyFirstPoint;
  final Offset? lastPolyLastPoint;
  PixelRenderResult(
    this.pixelBuffer,
    this.lastCommandIndex,
    this.isComplete,
    this.lastPolyFirstPoint,
    this.lastPolyLastPoint,
  );
}
