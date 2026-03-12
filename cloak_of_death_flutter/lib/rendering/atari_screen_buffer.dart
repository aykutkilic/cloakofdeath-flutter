import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Self-contained Atari pixel surface with queued plot playback.
///
/// Drawing code calls [plot] and [peek]. Plots are queued internally and
/// played back progressively via [drainPending]. The painter reads [pixels]
/// which reflects only the plots that have been drained so far.
class AtariScreenBuffer extends ChangeNotifier {
  static const int width = 160;
  static const int height = 96;
  static const int _pixelCount = width * height;

  /// Truth buffer — [plot] writes here immediately so [peek] returns correct
  /// values during drawing (needed for flood fill boundary detection).
  final Uint32List _truthPixels = Uint32List(_pixelCount);

  /// Display buffer — only updated when plots are drained. The painter reads
  /// this via [pixels].
  final Uint32List _displayPixels = Uint32List(_pixelCount);

  /// Queued plot positions and colors.
  final List<int> _queuedPositions = [];
  final List<int> _queuedColors = [];
  int _cursor = 0;

  /// Plot index where each bytecode command starts.
  final List<int> _commandBoundaries = [];

  /// The painter reads this.
  Uint32List get pixels => _displayPixels;

  int get pendingCount => _queuedPositions.length - _cursor;
  int get totalPlots => _queuedPositions.length;
  int get cursor => _cursor;

  /// Which command the playback cursor is currently within.
  int get currentCommandIndex {
    for (int i = _commandBoundaries.length - 1; i >= 0; i--) {
      if (_cursor >= _commandBoundaries[i]) return i;
    }
    return 0;
  }

  int get totalCommands => _commandBoundaries.length;

  // ---------------------------------------------------------------------------
  // Pixel operations
  // ---------------------------------------------------------------------------

  /// Queue a pixel plot. Writes to the truth buffer immediately (so [peek]
  /// is correct) and appends to the playback queue.
  void plot(int x, int y, int color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      final pos = y * width + x;
      _truthPixels[pos] = color;
      _queuedPositions.add(pos);
      _queuedColors.add(color);
    }
  }

  /// Read a pixel from the truth buffer.
  int peek(int x, int y) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      return _truthPixels[y * width + x];
    }
    return 0;
  }

  /// Mark the start of a new bytecode command in the queue.
  void markCommandBoundary() {
    _commandBoundaries.add(_queuedPositions.length);
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Make up to [count] queued pixels visible. Returns actual count drained.
  int drainPending(int count) {
    final end = (_cursor + count).clamp(0, _queuedPositions.length);
    for (int i = _cursor; i < end; i++) {
      _displayPixels[_queuedPositions[i]] = _queuedColors[i];
    }
    final drained = end - _cursor;
    _cursor = end;
    if (drained > 0) notifyListeners();
    return drained;
  }

  /// Drain until the next command boundary (or end of queue).
  void drainToNextCommand() {
    for (final boundary in _commandBoundaries) {
      if (boundary > _cursor) {
        drainPending(boundary - _cursor);
        return;
      }
    }
    // Past all boundaries — drain everything remaining.
    flushAllPending();
  }

  /// Make all queued pixels visible at once.
  void flushAllPending() {
    drainPending(_queuedPositions.length - _cursor);
  }

  // ---------------------------------------------------------------------------
  // Screen initialization
  // ---------------------------------------------------------------------------

  /// Initialize the screen fill pattern. Writes to both truth and display
  /// buffers immediately (background is visible before animation starts).
  /// Clears any pending queue.
  void fillScreenPattern(int fillByte, List<Color> palette) {
    final c = [
      colorToArgb(palette[(fillByte >> 6) & 0x03]),
      colorToArgb(palette[(fillByte >> 4) & 0x03]),
      colorToArgb(palette[(fillByte >> 2) & 0x03]),
      colorToArgb(palette[fillByte & 0x03]),
    ];

    if (c[0] == c[1] && c[1] == c[2] && c[2] == c[3]) {
      _truthPixels.fillRange(0, _pixelCount, c[0]);
      _displayPixels.fillRange(0, _pixelCount, c[0]);
    } else {
      for (int i = 0; i < _pixelCount; i++) {
        _truthPixels[i] = c[i % 4];
        _displayPixels[i] = c[i % 4];
      }
    }
    _resetQueue();
  }

  /// Clear to solid black.
  void clear() {
    _truthPixels.fillRange(0, _pixelCount, 0xFF000000);
    _displayPixels.fillRange(0, _pixelCount, 0xFF000000);
    _resetQueue();
    notifyListeners();
  }

  void _resetQueue() {
    _queuedPositions.clear();
    _queuedColors.clear();
    _cursor = 0;
    _commandBoundaries.clear();
  }

  /// Trigger a repaint without changing pixel data.
  void forceFlush() {
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Color utilities
  // ---------------------------------------------------------------------------

  /// Convert a Flutter [Color] to packed ARGB int.
  static int colorToArgb(Color color) {
    return ((color.a * 255.0).round().clamp(0, 255) << 24) |
        ((color.r * 255.0).round().clamp(0, 255) << 16) |
        ((color.g * 255.0).round().clamp(0, 255) << 8) |
        (color.b * 255.0).round().clamp(0, 255);
  }

  /// Decode a 4-pixel pattern byte into ARGB colors.
  static List<int> decodePattern(int pattern, List<Color> palette) {
    return [
      colorToArgb(palette[(pattern >> 6) & 0x03]),
      colorToArgb(palette[(pattern >> 4) & 0x03]),
      colorToArgb(palette[(pattern >> 2) & 0x03]),
      colorToArgb(palette[pattern & 0x03]),
    ];
  }
}
