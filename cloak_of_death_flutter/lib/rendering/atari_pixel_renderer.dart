import 'package:flutter/material.dart';
import 'atari_bytecode_parser.dart';
import 'atari_screen_buffer.dart';

/// CustomPainter that renders an [AtariScreenBuffer] to a Flutter canvas.
class AtariPixelRenderer extends CustomPainter {
  final AtariScreenBuffer? screenBuffer;

  AtariPixelRenderer({this.screenBuffer});

  @override
  void paint(Canvas canvas, Size size) {
    if (screenBuffer == null) return;

    final pixels = screenBuffer!.pixels;
    final pixelWidth = size.width / AtariScreenBuffer.width;
    final pixelHeight = size.height / AtariScreenBuffer.height;

    // Group pixels by color for batch rendering
    final colorGroups = <int, List<Rect>>{};

    for (int y = 0; y < AtariScreenBuffer.height; y++) {
      for (int x = 0; x < AtariScreenBuffer.width; x++) {
        final argb = pixels[y * AtariScreenBuffer.width + x];
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
  bool shouldRepaint(AtariPixelRenderer oldDelegate) => true;

  // ---------------------------------------------------------------------------
  // Immediate-mode rendering: draw commands directly to an AtariScreenBuffer
  // ---------------------------------------------------------------------------

  /// Render a range of bytecode commands [startCmd, endCmd) directly onto
  /// [buffer]. Returns polyline state for continuity across calls.
  static PolylineState renderCommands(
    AtariScreenBuffer buffer,
    AtariRoomBytecode roomData,
    int startCmd,
    int endCmd, {
    PolylineState? state,
  }) {
    var polyState = state ?? PolylineState();

    final cmdEnd = endCmd.clamp(0, roomData.commands.length);
    for (int i = startCmd; i < cmdEnd; i++) {
      buffer.markCommandBoundary();
      final cmd = roomData.commands[i];

      switch (cmd.type) {
        case BytecodeCommandType.polyline:
          final shouldClose =
              i + 1 < roomData.commands.length &&
              roomData.commands[i + 1].type ==
                  BytecodeCommandType.closedPolyline;
          polyState = _drawPolyline(
            buffer,
            cmd.points,
            roomData.palette[cmd.colorIndex ?? 0],
            shouldClose,
          );
          break;

        case BytecodeCommandType.closedPolyline:
          // Close the polygon (draw closing line segment)
          if (cmd.points.isEmpty) {
            final fp = polyState.firstPoint;
            final lp = polyState.lastPoint;
            if (fp != null && lp != null) {
              _drawBresenhamLine(
                buffer,
                lp.dx.toInt(),
                lp.dy.toInt(),
                fp.dx.toInt(),
                fp.dy.toInt(),
                AtariScreenBuffer.colorToArgb(
                  roomData.palette[cmd.colorIndex ?? 0],
                ),
              );
            }
          } else {
            polyState = _drawPolyline(
              buffer,
              cmd.points,
              roomData.palette[cmd.colorIndex ?? 0],
              true,
            );
          }
          // Polygon fill: border color = polyline color, fill color from pattern byte
          if (cmd.fillSeed != null && cmd.fillPattern != null) {
            final borderColor = AtariScreenBuffer.colorToArgb(
              roomData.palette[cmd.colorIndex ?? 0],
            );
            final fillColor = AtariScreenBuffer.colorToArgb(
              roomData.palette[cmd.fillPattern!],
            );
            _drawPolygonFill(buffer, cmd.fillSeed!, borderColor, fillColor);
          }
          break;

        case BytecodeCommandType.floodFillAt:
          final fillSeed = cmd.fillSeed;
          final fillPattern = cmd.fillPattern;
          if (fillSeed != null && fillPattern != null) {
            _drawFillAtXY(buffer, fillSeed, fillPattern, roomData.palette);
          }
          break;
      }
    }

    return polyState;
  }

  /// Render all commands in one call.
  static void renderAll(AtariScreenBuffer buffer, AtariRoomBytecode roomData) {
    buffer.fillScreenPattern(roomData.screenFillByte, roomData.palette);
    renderCommands(buffer, roomData, 0, roomData.commands.length);
  }

  // ---------------------------------------------------------------------------
  // Drawing primitives
  // ---------------------------------------------------------------------------

  static PolylineState _drawPolyline(
    AtariScreenBuffer buffer,
    List<Offset> points,
    Color color,
    bool shouldClose,
  ) {
    if (points.isEmpty) return PolylineState();

    final argb = AtariScreenBuffer.colorToArgb(color);
    final segmentCount = shouldClose ? points.length : points.length - 1;

    for (int i = 0; i < segmentCount; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      _drawBresenhamLine(
        buffer,
        p1.dx.toInt(),
        p1.dy.toInt(),
        p2.dx.toInt(),
        p2.dy.toInt(),
        argb,
      );
    }

    return PolylineState(firstPoint: points[0], lastPoint: points.last);
  }

  static void _drawBresenhamLine(
    AtariScreenBuffer buffer,
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
      buffer.plot(x, y, color);

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

  /// C9/CA polygon fill: stop at [borderColor] boundaries, fill with [fillColor].
  static void _drawPolygonFill(
    AtariScreenBuffer buffer,
    Offset seed,
    int borderColor,
    int fillColor,
  ) {
    _drawScanlineFillSolid(
      buffer,
      seed.dx.toInt(),
      seed.dy.toInt(),
      borderColor,
      fillColor,
    );
  }

  /// CB/CC fill at x,y: compare against the empty (background) color.
  /// Solid fill replaces empty pixels with fill color.
  /// Pattern fill replaces empty pixels with the pattern.
  static void _drawFillAtXY(
    AtariScreenBuffer buffer,
    Offset seed,
    int pattern,
    List<Color> palette,
  ) {
    final seedX = seed.dx.toInt();
    final seedY = seed.dy.toInt();
    final emptyColor = buffer.peek(seedX, seedY);
    if (emptyColor == 0) return;

    if (pattern <= 3) {
      final fillColor = AtariScreenBuffer.colorToArgb(palette[pattern]);
      if (emptyColor == fillColor) return;
      _drawScanlineFillEmpty(buffer, seedX, seedY, emptyColor, fillColor, null);
    } else {
      final patternColors = AtariScreenBuffer.decodePattern(pattern, palette);
      _drawScanlineFillEmpty(
        buffer,
        seedX,
        seedY,
        emptyColor,
        0,
        patternColors,
      );
    }
  }

  /// Fill at x,y: replace [emptyColor] pixels with [fillColor] or [patternColors].
  /// Stops at non-empty (boundary) pixels.
  static void _drawScanlineFillEmpty(
    AtariScreenBuffer buffer,
    int startX,
    int startY,
    int emptyColor,
    int fillColor,
    List<int>? patternColors,
  ) {
    bool shouldScanLeft = false;
    int left = startX;
    for (int y = startY; y < AtariScreenBuffer.height; y++) {
      if (shouldScanLeft) {
        while (left > 0 && buffer.peek(left - 1, y) == emptyColor) {
          left--;
        }
      }

      shouldScanLeft = true;
      int? nextLeft;
      for (
        int x = left;
        x < AtariScreenBuffer.width && buffer.peek(x, y) == emptyColor;
        x++
      ) {
        final c = patternColors != null ? patternColors[x % 4] : fillColor;
        buffer.plot(x, y, c);
        if (nextLeft == null && y < AtariScreenBuffer.height - 1) {
          if (buffer.peek(x, y + 1) == emptyColor) {
            nextLeft = x;
          } else {
            shouldScanLeft = false;
          }
        }
      }

      if (nextLeft == null) break;
      left = nextLeft;
    }
  }

  /// Polygon fill: stop at [borderColor] boundaries, fill with [fillColor].
  static void _drawScanlineFillSolid(
    AtariScreenBuffer buffer,
    int startX,
    int startY,
    int borderColor,
    int fillColor,
  ) {
    bool shouldScanLeft = false;
    int left = startX;
    for (int y = startY; y < AtariScreenBuffer.height; y++) {
      if (shouldScanLeft) {
        while (left > 0 && buffer.peek(left - 1, y) != borderColor) {
          left--;
        }
      }

      shouldScanLeft = true;
      int? nextLeft;
      for (
        int x = left;
        x < AtariScreenBuffer.width && buffer.peek(x, y) != borderColor;
        x++
      ) {
        buffer.plot(x, y, fillColor);
        if (nextLeft == null && y < AtariScreenBuffer.height - 1) {
          if (buffer.peek(x, y + 1) != borderColor) {
            nextLeft = x;
          } else {
            shouldScanLeft = false;
          }
        }
      }

      if (nextLeft == null) break;
      left = nextLeft;
    }
  }
}

/// Tracks polyline state across command rendering calls.
class PolylineState {
  final Offset? firstPoint;
  final Offset? lastPoint;
  PolylineState({this.firstPoint, this.lastPoint});
}
