import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'atari_bytecode_parser.dart';

/// Pixel-level renderer for Atari graphics (Synchronous version)
///
/// Renders commands pixel-by-pixel using Bresenham's line algorithm
/// and scanline flood fill, matching the authentic Atari 65XE rendering.
class AtariPixelRendererFixed extends CustomPainter {
  final AtariRoomBytecode roomData;
  final int? maxCommandIndex; // null = render all
  final int? maxPixelCount; // null = render all pixels
  final ui.Image? cachedImage; // Pre-rendered image
  final Uint32List? pixelBuffer; // Direct pixel buffer for fast rendering

  // 160-pixel wide canvas (Atari resolution)
  static const int canvasWidth = 160;
  static const int canvasHeight = 96; // Typical Atari graphics height

  AtariPixelRendererFixed({
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
          colorGroups[argb]!.add(Rect.fromLTWH(
            x * pixelWidth,
            y * pixelHeight,
            pixelWidth + 0.5, // slight overlap to avoid visual seams
            pixelHeight + 0.5,
          ));
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
      // Fallback: draw background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = roomData.palette[1], // Background is palette[1]
      );
    }
  }

  @override
  bool shouldRepaint(AtariPixelRendererFixed oldDelegate) {
    return oldDelegate.cachedImage != cachedImage ||
        oldDelegate.pixelBuffer != pixelBuffer ||
        oldDelegate.maxCommandIndex != maxCommandIndex ||
        oldDelegate.maxPixelCount != maxPixelCount;
  }

  /// Fast synchronous rendering - returns pixel buffer directly (no image conversion)
  static _PixelRenderResult renderToPixelBuffer(
    AtariRoomBytecode roomData, {
    int? maxCommandIndex,
    int? maxPixelCount,
  }) {
    // Create pixel buffer (160x96)
    final pixelData = Uint32List(canvasWidth * canvasHeight);

    // Create boundary mask to track polyline pixels
    final boundaryMask = Uint8List(canvasWidth * canvasHeight);

    // Fill with background color (palette[1])
    final bgColor = roomData.palette[1];
    final bgArgb = _colorToArgb(bgColor);
    pixelData.fillRange(0, pixelData.length, bgArgb);

    // Track pixels drawn for animation
    int pixelsDrawn = 0;
    final pixelLimit = maxPixelCount ?? 0x7FFFFFFFFFFFFFFF; // Max int64 value

    // Render commands up to maxCommandIndex
    final commandLimit = maxCommandIndex ?? roomData.commands.length - 1;
    Path? lastPolyline; // For flood fill operations
    Offset? lastPolylineFirstPoint; // First point of last polyline for flood fill seed
    Offset? lastPolylineLastPoint; // Last point of the polyline for closing
    int lastRenderedCmd = 0;

    for (int cmdIdx = 0;
        cmdIdx <= commandLimit && cmdIdx < roomData.commands.length;
        cmdIdx++) {
      lastRenderedCmd = cmdIdx;
      final cmd = roomData.commands[cmdIdx];

      switch (cmd.type) {
        case BytecodeCommandType.polyline:
          // Check if next command is a close+fill (C9/CA) - closedPolyline type
          final bool shouldClose = cmdIdx + 1 < roomData.commands.length &&
              roomData.commands[cmdIdx + 1].type == BytecodeCommandType.closedPolyline;

          final result = _drawPolyline(
            pixelData,
            boundaryMask,
            cmd.points,
            roomData.palette[cmd.colorIndex ?? 0],
            pixelsDrawn,
            pixelLimit,
            shouldClose, // Only close if followed by closedPolyline (C9/CA)
          );
          pixelsDrawn = result.pixelsDrawn;
          lastPolyline = result.path;
          lastPolylineFirstPoint = result.firstPoint; // Store first point
          lastPolylineLastPoint = result.lastPoint; // Store last point
          break;

        case BytecodeCommandType.closedPolyline:
          // C9/CA command: Close the last polyline
          if (cmd.points.isEmpty && lastPolyline != null && lastPolylineFirstPoint != null && lastPolylineLastPoint != null) {
            // Draw just the closing segment (last point to first point)
            final closePixels = _bresenhamLine(
              pixelData,
              boundaryMask,
              lastPolylineLastPoint!.dx.toInt(),
              lastPolylineLastPoint!.dy.toInt(),
              lastPolylineFirstPoint!.dx.toInt(),
              lastPolylineFirstPoint!.dy.toInt(),
              _colorToArgb(roomData.palette[cmd.colorIndex ?? 0]), // Use current color
              pixelsDrawn,
              pixelLimit,
            );
            pixelsDrawn = closePixels;

            // Update path to be closed
            lastPolyline!.close();
          } else if (cmd.points.isNotEmpty) {
            // CB command with explicit points: Always close the polygon
            final result = _drawPolyline(
              pixelData,
              boundaryMask,
              cmd.points,
              roomData.palette[cmd.colorIndex ?? 0],
              pixelsDrawn,
              pixelLimit,
              true, // Always close for CB command
            );
            pixelsDrawn = result.pixelsDrawn;
            lastPolyline = result.path;
            lastPolylineFirstPoint = result.firstPoint;
            lastPolylineLastPoint = result.lastPoint;
          }
          break;

        case BytecodeCommandType.floodFill:
          if (cmd.fillSeed != null && cmd.fillPattern != null && lastPolyline != null) {
            final result = _floodFillPath(
              pixelData,
              boundaryMask,
              lastPolyline,
              cmd.fillSeed!,
              cmd.fillPattern!,
              roomData.palette,
              pixelsDrawn,
              pixelLimit,
            );
            pixelsDrawn = result.pixelsDrawn;
          }
          break;

        case BytecodeCommandType.floodFillAt:
          if (cmd.fillSeed != null && cmd.fillPattern != null) {
            // All fills use target color matching to prevent leaking
            // Boundary mask is cleared before each filled polygon
            final result = _floodFillAt(
              pixelData,
              boundaryMask,
              cmd.fillSeed!,
              cmd.fillPattern!,
              roomData.palette,
              pixelsDrawn,
              pixelLimit,
              false, // Use target color matching
            );
            pixelsDrawn = result.pixelsDrawn;
          }
          break;
      }

      // Check pixel budget AFTER completing command (so commands always finish)
      if (pixelsDrawn >= pixelLimit) break;
    }

    return _PixelRenderResult(pixelData, lastRenderedCmd, pixelsDrawn < pixelLimit);
  }

  /// Create pixel buffer and render it to an image
  static Future<_RenderResult> renderToImage(
    AtariRoomBytecode roomData, {
    int? maxCommandIndex,
    int? maxPixelCount,
  }) async {
    // Create pixel buffer (160x96)
    final pixelData = Uint32List(canvasWidth * canvasHeight);

    // Create boundary mask to track polyline pixels
    final boundaryMask = Uint8List(canvasWidth * canvasHeight);

    // Fill with background color (palette[1])
    final bgColor = roomData.palette[1];
    final bgArgb = _colorToArgb(bgColor);
    pixelData.fillRange(0, pixelData.length, bgArgb);

    // Track pixels drawn for animation
    int pixelsDrawn = 0;
    final pixelLimit = maxPixelCount ?? 0x7FFFFFFFFFFFFFFF; // Max int64 value

    // Render commands up to maxCommandIndex
    final commandLimit = maxCommandIndex ?? roomData.commands.length - 1;
    Path? lastPolyline; // For flood fill operations
    Offset? lastPolylineFirstPoint; // First point of last polyline for flood fill seed
    Offset? lastPolylineLastPoint; // Last point of the polyline for closing
    int lastRenderedCmd = 0;

    for (int cmdIdx = 0;
        cmdIdx <= commandLimit && cmdIdx < roomData.commands.length;
        cmdIdx++) {
      lastRenderedCmd = cmdIdx;
      final cmd = roomData.commands[cmdIdx];

      switch (cmd.type) {
        case BytecodeCommandType.polyline:
          // Check if next command is a close+fill (C9/CA) - closedPolyline type
          final bool shouldClose = cmdIdx + 1 < roomData.commands.length &&
              roomData.commands[cmdIdx + 1].type == BytecodeCommandType.closedPolyline;

          final result = _drawPolyline(
            pixelData,
            boundaryMask,
            cmd.points,
            roomData.palette[cmd.colorIndex ?? 0],
            pixelsDrawn,
            pixelLimit,
            shouldClose, // Only close if followed by closedPolyline (C9/CA)
          );
          pixelsDrawn = result.pixelsDrawn;
          lastPolyline = result.path;
          lastPolylineFirstPoint = result.firstPoint; // Store first point
          lastPolylineLastPoint = result.lastPoint; // Store last point
          break;

        case BytecodeCommandType.closedPolyline:
          // C9/CA command: Close the last polyline
          if (cmd.points.isEmpty && lastPolyline != null && lastPolylineFirstPoint != null && lastPolylineLastPoint != null) {
            // Draw just the closing segment (last point to first point)
            final closePixels = _bresenhamLine(
              pixelData,
              boundaryMask,
              lastPolylineLastPoint!.dx.toInt(),
              lastPolylineLastPoint!.dy.toInt(),
              lastPolylineFirstPoint!.dx.toInt(),
              lastPolylineFirstPoint!.dy.toInt(),
              _colorToArgb(roomData.palette[cmd.colorIndex ?? 0]), // Use current color
              pixelsDrawn,
              pixelLimit,
            );
            pixelsDrawn = closePixels;

            // Update path to be closed
            lastPolyline!.close();
          } else if (cmd.points.isNotEmpty) {
            // CB command with explicit points: Always close the polygon
            final result = _drawPolyline(
              pixelData,
              boundaryMask,
              cmd.points,
              roomData.palette[cmd.colorIndex ?? 0],
              pixelsDrawn,
              pixelLimit,
              true, // Always close for CB command
            );
            pixelsDrawn = result.pixelsDrawn;
            lastPolyline = result.path;
            lastPolylineFirstPoint = result.firstPoint;
            lastPolylineLastPoint = result.lastPoint;
          }
          break;

        case BytecodeCommandType.floodFill:
          if (cmd.fillSeed != null && cmd.fillPattern != null && lastPolyline != null) {
            final result = _floodFillPath(
              pixelData,
              boundaryMask,
              lastPolyline,
              cmd.fillSeed!,
              cmd.fillPattern!,
              roomData.palette,
              pixelsDrawn,
              pixelLimit,
            );
            pixelsDrawn = result.pixelsDrawn;
          }
          break;

        case BytecodeCommandType.floodFillAt:
          if (cmd.fillSeed != null && cmd.fillPattern != null) {
            // All fills use target color matching to prevent leaking
            // Boundary mask is cleared before each filled polygon
            final result = _floodFillAt(
              pixelData,
              boundaryMask,
              cmd.fillSeed!,
              cmd.fillPattern!,
              roomData.palette,
              pixelsDrawn,
              pixelLimit,
              false, // Use target color matching
            );
            pixelsDrawn = result.pixelsDrawn;
          }
          break;
      }
    }

    // Convert pixel buffer to image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixelData.buffer.asUint8List(),
      canvasWidth,
      canvasHeight,
      ui.PixelFormat.bgra8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    final image = await completer.future;
    return _RenderResult(image, lastRenderedCmd);
  }

  /// Draw polyline using Bresenham's algorithm
  static _PolylineResult _drawPolyline(
    Uint32List pixels,
    Uint8List boundaryMask,
    List<Offset> points,
    Color color,
    int startPixelCount,
    int pixelLimit,
    bool shouldClose, // Whether to draw closing line back to first point
  ) {
    if (points.isEmpty) {
      return _PolylineResult(Path(), startPixelCount, null, null);
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    final firstPoint = points[0]; // Store first point for flood fill seed

    int pixelsDrawn = startPixelCount;
    final argb = _colorToArgb(color);

    // Determine how many segments to draw
    final segmentCount = shouldClose ? points.length : points.length - 1;

    // Draw all segments (and optionally closing segment back to first point)
    for (int i = 0; i < segmentCount; i++) {
      if (pixelsDrawn >= pixelLimit) break;

      final p1 = points[i];
      final p2 = points[(i + 1) % points.length]; // Wrap for closing segment
      path.lineTo(p2.dx, p2.dy);

      // Draw line with Bresenham
      final linePixels = _bresenhamLine(
        pixels,
        boundaryMask,
        p1.dx.toInt(),
        p1.dy.toInt(),
        p2.dx.toInt(),
        p2.dy.toInt(),
        argb,
        pixelsDrawn,
        pixelLimit,
      );
      pixelsDrawn = linePixels;
    }

    // Only close the path if we drew the closing segment
    if (shouldClose) {
      path.close();
    }

    return _PolylineResult(path, pixelsDrawn, firstPoint, points.last);
  }

  /// Bresenham's line algorithm
  static int _bresenhamLine(
    Uint32List pixels,
    Uint8List boundaryMask,
    int x0,
    int y0,
    int x1,
    int y1,
    int color,
    int startPixelCount,
    int pixelLimit,
  ) {
    int pixelsDrawn = startPixelCount;

    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    int x = x0;
    int y = y0;

    while (true) {
      if (pixelsDrawn >= pixelLimit) break;

      // Set pixel and mark as boundary
      if (x >= 0 && x < canvasWidth && y >= 0 && y < canvasHeight) {
        final idx = y * canvasWidth + x;
        pixels[idx] = color;
        boundaryMask[idx] = 1; // Mark as boundary
        pixelsDrawn++;
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

    return pixelsDrawn;
  }

  /// Flood fill a closed path (C9/CA commands)
  ///
  /// Uses boundary-only fill (respect only polygon edges in boundaryMask)
  /// Seed position from vertex0 + offset
  static _FloodFillResult _floodFillPath(
    Uint32List pixels,
    Uint8List boundaryMask,
    Path path,
    Offset seedPoint,
    int pattern,
    List<Color> palette,
    int startPixelCount,
    int pixelLimit,
  ) {
    int seedX = seedPoint.dx.toInt();
    int seedY = seedPoint.dy.toInt();

    if (seedX < 0 ||
        seedX >= canvasWidth ||
        seedY < 0 ||
        seedY >= canvasHeight) {
      return _FloodFillResult(startPixelCount);
    }

    // Ensure we start filling from an interior point
    int seedIdx = seedY * canvasWidth + seedX;
    if (boundaryMask[seedIdx] == 1) {
      bool foundInterior = false;
      const maxRadius = 15;
      for (int radius = 1; radius <= maxRadius && !foundInterior; radius++) {
        for (int dy = -radius; dy <= radius && !foundInterior; dy++) {
          for (int dx = -radius; dx <= radius && !foundInterior; dx++) {
            if (dy.abs() == radius || dx.abs() == radius) {
              final testX = seedX + dx;
              final testY = seedY + dy;
              if (testX >= 0 && testX < canvasWidth && testY >= 0 && testY < canvasHeight) {
                final testIdx = testY * canvasWidth + testX;
                // Pick a non-boundary pixel that is inside the mathematical path
                if (boundaryMask[testIdx] == 0 && path.contains(Offset(testX + 0.5, testY + 0.5))) {
                  seedX = testX;
                  seedY = testY;
                  foundInterior = true;
                }
              }
            }
          }
        }
      }
      if (!foundInterior) return _FloodFillResult(startPixelCount);
    }

    int pixelsDrawn = startPixelCount;

    if (pattern <= 3) {
      final fillArgb = _colorToArgb(palette[pattern]);
      // Polygon fills (C9/CA) always use boundary-only mode
      pixelsDrawn = _scanlineFill(
        pixels,
        boundaryMask,
        seedX,
        seedY,
        0, // targetColor ignored in boundary-only mode
        fillArgb,
        pixelsDrawn,
        pixelLimit,
        null,
        true, // boundaryOnly = true for polygon fills
      );
    } else {
      final patternColors = _decodePattern(pattern, palette);
      pixelsDrawn = _scanlineFill(
        pixels,
        boundaryMask,
        seedX,
        seedY,
        0, // targetColor ignored in boundary-only mode
        0,
        pixelsDrawn,
        pixelLimit,
        patternColors,
        true, // boundaryOnly = true for polygon fills
      );
    }

    return _FloodFillResult(pixelsDrawn);
  }

  /// Flood fill at specific point with pattern or solid color (CC command)
  /// This is for region fill commands, not polygon fills
  static _FloodFillResult _floodFillAt(
    Uint32List pixels,
    Uint8List boundaryMask,
    Offset seed,
    int pattern,
    List<Color> palette,
    int startPixelCount,
    int pixelLimit,
    bool boundaryOnly,
  ) {
    int seedX = seed.dx.toInt();
    int seedY = seed.dy.toInt();

    if (seedX < 0 ||
        seedX >= canvasWidth ||
        seedY < 0 ||
        seedY >= canvasHeight) {
      return _FloodFillResult(startPixelCount);
    }

    int seedIdx = seedY * canvasWidth + seedX;

    // If seed point lands on a boundary pixel, search for an interior point nearby
    // This handles cases where the seed lands on the polygon edge
    if (boundaryMask[seedIdx] == 1) {
      bool foundInterior = false;

      // Search in concentric rings around the seed point
      // This ensures we check nearby points first before expanding outward
      const maxRadius = 20;
      for (int radius = 0; radius <= maxRadius && !foundInterior; radius++) {
        // Check points at the current radius in a spiral pattern
        for (int dy = 0; dy <= radius && !foundInterior; dy++) {
          for (int dx = 0; dx <= radius && !foundInterior; dx++) {
            if (dy == radius || dx == radius) { // Only check perimeter of current radius
              // Check all 4 quadrants
              for (final offset in [
                (dx, dy),   // bottom-right
                (-dx, dy),  // bottom-left
                (dx, -dy),  // top-right
                (-dx, -dy), // top-left
              ]) {
                final testX = seedX + offset.$1;
                final testY = seedY + offset.$2;

                if (testX >= 0 && testX < canvasWidth && testY >= 0 && testY < canvasHeight) {
                  final testIdx = testY * canvasWidth + testX;
                  if (boundaryMask[testIdx] == 0) {
                    seedX = testX;
                    seedY = testY;
                    seedIdx = testIdx;
                    foundInterior = true;
                    break;
                  }
                }
              }
            }
          }
        }
      }

      if (!foundInterior) {
        return _FloodFillResult(startPixelCount);
      }
    }

    final targetColor = pixels[seedIdx];
    int pixelsDrawn = startPixelCount;

    if (pattern <= 3) {
      // Solid fill with palette color
      final fillColor = _colorToArgb(palette[pattern]);
      // Flood fills (CC) always use region fill mode (stop at color changes)
      pixelsDrawn = _scanlineFill(
        pixels,
        boundaryMask,
        seedX,
        seedY,
        targetColor,
        fillColor,
        pixelsDrawn,
        pixelLimit,
        null,
        false, // Region fill mode for CC commands
      );
    } else {
      // Pattern fill (4-column, 2-bit pattern)
      final patternColors = _decodePattern(pattern, palette);
      // Pattern fills are always region fills (stop at color changes)
      pixelsDrawn = _scanlineFill(
        pixels,
        boundaryMask,
        seedX,
        seedY,
        targetColor,
        0,
        pixelsDrawn,
        pixelLimit,
        patternColors,
        false, // Pattern fills always use region fill mode
      );
    }

    return _FloodFillResult(pixelsDrawn);
  }

  /// Standard scanline flood fill algorithm (Bidirectional)
  static int _scanlineFill(
    Uint32List pixels,
    Uint8List boundaryMask,
    int startX,
    int startY,
    int targetColor,
    int fillColor,
    int startPixelCount,
    int pixelLimit,
    List<int>? patternColors,
    bool boundaryOnly,
  ) {
    if (startX < 0 || startX >= canvasWidth || startY < 0 || startY >= canvasHeight) {
      return startPixelCount;
    }

    final seedIdx = startY * canvasWidth + startX;
    if (boundaryMask[seedIdx] == 1) return startPixelCount;
    if (!boundaryOnly && pixels[seedIdx] != targetColor) return startPixelCount;

    int pixelsDrawn = startPixelCount;
    final stack = [_ScanlineSpan(startY, startX, startX, 1), _ScanlineSpan(startY, startX, startX, -1)];
    final visited = Uint8List(canvasWidth * canvasHeight);
    
    // First line expansion
    int x1 = startX;
    int x2 = startX;
    while (x1 > 0 && boundaryMask[startY * canvasWidth + (x1 - 1)] == 0 && 
           (boundaryOnly || pixels[startY * canvasWidth + (x1 - 1)] == targetColor)) {
      x1--;
    }
    while (x2 < canvasWidth - 1 && boundaryMask[startY * canvasWidth + (x2 + 1)] == 0 && 
           (boundaryOnly || pixels[startY * canvasWidth + (x2 + 1)] == targetColor)) {
      x2++;
    }

    // Process first line
    for (int x = x1; x <= x2; x++) {
      final idx = startY * canvasWidth + x;
      if (visited[idx] == 0) {
        visited[idx] = 1;
        pixels[idx] = patternColors != null ? patternColors[x % 4] : fillColor;
        pixelsDrawn++;
      }
    }

    // Seed neighbors
    if (startY > 0) {
      _addSpansForLine(pixels, boundaryMask, visited, startY - 1, x1, x2, targetColor, boundaryOnly, stack, -1);
    }
    if (startY < canvasHeight - 1) {
      _addSpansForLine(pixels, boundaryMask, visited, startY + 1, x1, x2, targetColor, boundaryOnly, stack, 1);
    }

    int iterations = 0;
    const maxIterations = 50000;

    while (stack.isNotEmpty && pixelsDrawn < pixelLimit && iterations < maxIterations) {
      iterations++;
      final span = stack.removeLast();
      final y = span.y;
      if (y < 0 || y >= canvasHeight) continue;

      int curX1 = span.x1;
      int curX2 = span.x2;

      // Fill and expand horizontally
      while (curX1 > 0 && boundaryMask[y * canvasWidth + (curX1 - 1)] == 0 && 
             (boundaryOnly || pixels[y * canvasWidth + (curX1 - 1)] == targetColor)) {
        curX1--;
      }
      while (curX2 < canvasWidth - 1 && boundaryMask[y * canvasWidth + (curX2 + 1)] == 0 && 
             (boundaryOnly || pixels[y * canvasWidth + (curX2 + 1)] == targetColor)) {
        curX2++;
      }

      bool filledAny = false;
      for (int x = curX1; x <= curX2; x++) {
        final idx = y * canvasWidth + x;
        if (visited[idx] == 0) {
          visited[idx] = 1;
          pixels[idx] = patternColors != null ? patternColors[x % 4] : fillColor;
          pixelsDrawn++;
          filledAny = true;
        }
      }

      if (filledAny) {
        if (y + span.direction >= 0 && y + span.direction < canvasHeight) {
          _addSpansForLine(pixels, boundaryMask, visited, y + span.direction, curX1, curX2, targetColor, boundaryOnly, stack, span.direction);
        }
        // Also check opposite direction for complex shapes
        if (y - span.direction >= 0 && y - span.direction < canvasHeight) {
          _addSpansForLine(pixels, boundaryMask, visited, y - span.direction, curX1, curX2, targetColor, boundaryOnly, stack, -span.direction);
        }
      }
    }

    return pixelsDrawn;
  }

  /// Find and add spans in a line that need filling
  static void _addSpansForLine(
    Uint32List pixels,
    Uint8List boundaryMask,
    Uint8List visited,
    int y,
    int x1,
    int x2,
    int targetColor,
    bool boundaryOnly,
    List<_ScanlineSpan> stack,
    int direction,
  ) {
    bool inSpan = false;
    int spanStart = 0;

    for (int x = x1; x <= x2; x++) {
      final idx = y * canvasWidth + x;
      final isFillable = boundaryMask[idx] == 0 && visited[idx] == 0 && 
                         (boundaryOnly || pixels[idx] == targetColor);

      if (isFillable && !inSpan) {
        inSpan = true;
        spanStart = x;
      } else if (!isFillable && inSpan) {
        stack.add(_ScanlineSpan(y, spanStart, x - 1, direction));
        inSpan = false;
      }
    }

    if (inSpan) {
      stack.add(_ScanlineSpan(y, spanStart, x2, direction));
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
class _PolylineResult {
  final Path path;
  final int pixelsDrawn;
  final Offset? firstPoint; // First point of the polyline for flood fill seed
  final Offset? lastPoint; // Last point to close the polygon
  _PolylineResult(this.path, this.pixelsDrawn, [this.firstPoint, this.lastPoint]);
}

class _FloodFillResult {
  final int pixelsDrawn;
  _FloodFillResult(this.pixelsDrawn);
}

class _ScanlineSpan {
  final int y;
  final int x1;
  final int x2;
  final int direction; // 1 = down, -1 = up
  _ScanlineSpan(this.y, this.x1, this.x2, this.direction);
}

class _RenderResult {
  final ui.Image image;
  final int lastCommandIndex;
  _RenderResult(this.image, this.lastCommandIndex);
}

class _PixelRenderResult {
  final Uint32List pixelBuffer;
  final int lastCommandIndex;
  final bool isComplete;
  _PixelRenderResult(this.pixelBuffer, this.lastCommandIndex, this.isComplete);
}
