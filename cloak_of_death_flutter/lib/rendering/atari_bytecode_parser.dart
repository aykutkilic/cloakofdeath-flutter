import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Commands parsed from Atari FIND bytecode format
class AtariBytecodeCommand {
  final BytecodeCommandType type;
  final int? colorIndex; // 0-3 for palette colors
  final List<Offset> points; // Polyline points
  final int? fillPattern; // For flood fill (0-255)
  final Offset? fillSeed; // Seed point for flood fill
  final String hexBytes; // Original hex bytes for display

  AtariBytecodeCommand({
    required this.type,
    this.colorIndex,
    this.points = const [],
    this.fillPattern,
    this.fillSeed,
    this.hexBytes = '',
  });

  @override
  String toString() {
    return 'BytecodeCmd($type, color=$colorIndex, points=${points.length}, pattern=$fillPattern)';
  }
}

enum BytecodeCommandType {
  polyline, // C8, CD, CE, CF, D0 - draw polyline
  closedPolyline, // C9, CA - close last polyline + flood fill (single op)
  floodFillAt, // CB, CC - flood fill at specific point
}

/// Room data parsed from Atari bytecode format
class AtariRoomBytecode {
  final int roomId;
  final List<Color> palette; // 4 colors: [COLBK, COLOR0, COLOR1, COLOR2]
  final List<AtariBytecodeCommand> commands;
  final Uint8List rawBytes;
  final int screenFillByte; // Initial screen fill pattern byte from header

  AtariRoomBytecode({
    required this.roomId,
    required this.palette,
    required this.commands,
    required this.rawBytes,
    required this.screenFillByte,
  });
}

/// Parser for Atari FIND bytecode format
///
/// Format specification:
/// - Data buffer: 5388 bytes starting at offset 30000
/// - Room markers: 0xA0 to 0xBB (room IDs 0-27)
/// - Header: AA C1 C2 C3 C4 (room ID + 4-color palette)
/// - Commands:
///   - C8 X1 Y1 X2 Y2... - polyline with current color
///   - C9 offset_byte - close last polyline and flood fill with current color at point0 + offset
///     - offset_byte: high nibble = X offset, low nibble = Y offset (e.g., 0x11 = +1X, +1Y)
///   - CA color offset_byte - close last polyline and flood fill with specified color at point0 + offset
///     - offset_byte: high nibble = X offset, low nibble = Y offset (e.g., 0x00 = +0X, +0Y)
///   - CB XX YY - flood fill with current color at absolute point (XX, YY)
///   - CC AB XX YY - flood fill at absolute point (XX, YY)
///     - If AB <= 3: solid fill with palette[AB]
///     - If AB > 3: pattern fill (2-bit pattern, 4 columns)
///   - CD X1 Y1... - polyline with color0
///   - CE X1 Y1... - polyline with color1
///   - CF X1 Y1... - polyline with color2
///   - D0 X1 Y1... - polyline with color3
///   - **Implicit polyline**: Any byte < 0xA0 (160) is treated as coordinate data
///     - Interpreted as polyline with current color (like C8)
///     - Allows compact encoding without repeating C8 command
///   - Stop conditions:
///     - Room marker (0xA0-0xBB)
///     - Command bytes (0xC8-0xD0) mark start of new command
///     - End marker (0xFF)
///   - Note: Valid coordinates are 0x00-0x9F (0-159) to avoid confusion with commands/markers
class AtariBytecodeParser {
  /// Helper to log messages (uses debugPrint for visibility in Flutter)
  static void _log(String message) {
    debugPrint('[AtariBytecode] $message');
  }

  /// Get hex string from buffer
  static String _getHexString(Uint8List buffer, int pos, int length) {
    final bytes = buffer.sublist(pos, (pos + length).clamp(0, buffer.length));
    return bytes
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(' ');
  }

  /// Log compact command with hex bytes
  static void _logCommand(
    Uint8List buffer,
    int pos,
    int length,
    String description,
  ) {
    final hex = _getHexString(buffer, pos, length);
    _log('$hex  $description');
  }

  /// Dump buffer showing -8, current 8, +8 bytes around position
  static void _dumpStopContext(Uint8List buffer, int position) {
    // Align to 8-byte boundary for the current position
    final alignedCurrent = (position ~/ 8) * 8;
    final prevChunkStart = (alignedCurrent - 8).clamp(0, buffer.length);
    final nextChunkStart = (alignedCurrent + 8).clamp(0, buffer.length);

    final chunks = <String>[];

    // Previous 8 bytes
    if (prevChunkStart < alignedCurrent) {
      final chunk = buffer.sublist(prevChunkStart, alignedCurrent);
      chunks.add(
        '-8: ${chunk.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ')}',
      );
    }

    // Current 8 bytes
    final currentEnd = (alignedCurrent + 8).clamp(0, buffer.length);
    final currentChunk = buffer.sublist(alignedCurrent, currentEnd);
    chunks.add(
      ' 8: ${currentChunk.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ')}',
    );

    // Next 8 bytes
    if (nextChunkStart < buffer.length) {
      final nextEnd = (nextChunkStart + 8).clamp(0, buffer.length);
      final nextChunk = buffer.sublist(nextChunkStart, nextEnd);
      chunks.add(
        '+8: ${nextChunk.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ')}',
      );
    }

    for (final chunk in chunks) {
      _log(chunk);
    }
  }

  /// Parse room data from raw bytecode buffer
  static AtariRoomBytecode? parseRoom(
    Uint8List buffer,
    int roomId, {
    bool enableLogging = false,
  }) {
    // Find room marker (roomId + 0xA0)
    final marker = roomId + 0xA0;
    int startPos = -1;

    for (int i = 0; i < buffer.length; i++) {
      if (buffer[i] == marker) {
        startPos = i;
        break;
      }
    }

    if (startPos == -1 || startPos + 5 > buffer.length) {
      if (enableLogging) {
        _log(
          'Room $roomId (0x${marker.toRadixString(16).toUpperCase()}): Not found or incomplete header',
        );
      }
      return null; // Room not found or incomplete header
    }

    // Parse header: AA [screen_fill] [COLOR0] [COLOR1] [COLOR2]
    // Byte 0: screen fill byte (fills screen buffer, NOT a color register)
    // Bytes 1-3: COLOR0-COLOR2 (for pixel values 1-3)
    // COLBK (pixel value 0) = black (set by GRAPHICS 23 in BASIC, not in bytecode)
    final screenFillByte = buffer[startPos + 1];
    final colorBytes = buffer.sublist(startPos + 2, startPos + 5);
    final palette = <Color>[
      const Color(0xFF000000), // Index 0: COLBK = black (OS default)
      _atariColorToRgb(colorBytes[0]), // Index 1: COLOR0 (pixel value 1)
      _atariColorToRgb(colorBytes[1]), // Index 2: COLOR1 (pixel value 2)
      _atariColorToRgb(colorBytes[2]), // Index 3: COLOR2 (pixel value 3)
    ];

    if (enableLogging) {
      // Compact header: show room marker, fill byte, and color bytes
      final headerHex = [
        marker,
        screenFillByte,
        ...colorBytes,
      ].map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');
      _log(
        '$headerHex  Starting room ${roomId.toRadixString(16).toUpperCase()}',
      );
    }

    // Find end position (next room marker or explicit end marker)
    int endPos = buffer.length;
    String stopReason = 'end of buffer';
    for (int i = startPos + 5; i < buffer.length; i++) {
      final b = buffer[i];
      // Stop only on explicit end marker (0xFF) or next room marker (0xA0-0xBB)
      if (b == 0xFF) {
        endPos = i;
        stopReason = 'explicit end marker 0xFF';
        break;
      } else if (b >= 0xA0 && b <= 0xBB) {
        endPos = i;
        final nextRoomId = b - 0xA0;
        stopReason =
            'next room marker 0x${b.toRadixString(16).toUpperCase()} (room $nextRoomId)';
        break;
      }
    }

    // Parse commands
    final commands = _parseCommands(
      buffer,
      startPos + 5,
      endPos,
      roomId,
      stopReason,
      enableLogging,
    );

    return AtariRoomBytecode(
      roomId: roomId,
      palette: palette,
      commands: commands,
      rawBytes: buffer.sublist(startPos, endPos),
      screenFillByte: screenFillByte,
    );
  }

  /// Parse command sequence from bytecode
  static List<AtariBytecodeCommand> _parseCommands(
    Uint8List buffer,
    int start,
    int end,
    int roomId,
    String stopReason,
    bool enableLogging,
  ) {
    final commands = <AtariBytecodeCommand>[];
    int i = start;
    int currentColor = 1; // DRAW routine initializes $06F2 to 1 at $488A
    Offset?
    lastPolylineVertex0; // Track first vertex of last polyline for C9/CA offsets

    while (i < end) {
      final byte = buffer[i];

      if (byte == 0xC8) {
        // C8: Polyline with current color
        final cmdStart = i;
        i++;
        final points = _readPoints(buffer, i, end);
        if (points.isNotEmpty) {
          lastPolylineVertex0 = points[0]; // Track first vertex for C9/CA
          final cmdLength = 1 + (points.length * 2);
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.polyline,
              colorIndex: currentColor,
              points: points,
              hexBytes: _getHexString(buffer, cmdStart, cmdLength),
            ),
          );
          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              cmdLength,
              'Polyline color=$currentColor, ${points.length} pts',
            );
          }
          i += points.length * 2;
        }
      } else if (byte == 0xCA) {
        // CA: Close polyline and flood fill with specified color at offset from vertex 0
        // Format: CA color offset_byte (high nibble=X offset, low nibble=Y offset)
        final cmdStart = i;
        i++;

        if (i + 1 < end && lastPolylineVertex0 != null) {
          final fillColor = buffer[i];
          final offsetByte = buffer[i + 1];

          // Decode offset: high nibble = X, low nibble = Y
          final offsetX = (offsetByte >> 4) & 0x0F;
          final offsetY = offsetByte & 0x0F;

          // Calculate absolute fill position: vertex0 + offset
          final fillX = lastPolylineVertex0.dx + offsetX;
          final fillY = lastPolylineVertex0.dy + offsetY;

          // Single command: close polyline + flood fill
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.closedPolyline,
              colorIndex: currentColor,
              points: [], // Points come from previous polyline
              fillPattern: fillColor,
              fillSeed: Offset(fillX, fillY),
              hexBytes: _getHexString(buffer, cmdStart, 3),
            ),
          );

          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              3,
              'CA: Close+Fill color=$fillColor vertex0=$lastPolylineVertex0 offset=($offsetX,$offsetY) → fill@($fillX,$fillY)',
            );
          }

          i += 2;
        } else {
          if (enableLogging && lastPolylineVertex0 == null) {
            _log('CA command without previous polyline vertex 0 - skipping');
          }
          break; // Incomplete command or no previous polyline
        }
      } else if (byte == 0xCB) {
        // CB: Flood fill with current color at absolute point (XX, YY)
        // Format: CB XX YY (3 bytes total)
        final cmdStart = i;
        if (i + 2 < end) {
          final xx = buffer[i + 1];
          final yy = buffer[i + 2];

          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.floodFillAt,
              fillPattern: currentColor,
              fillSeed: Offset(xx.toDouble(), yy.toDouble()),
              hexBytes: _getHexString(buffer, cmdStart, 3),
            ),
          );

          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              3,
              'CB: Flood fill current color=$currentColor x,y=$xx,$yy',
            );
          }

          i += 3;
        } else {
          break; // Incomplete command
        }
      } else if (byte == 0xC9) {
        // C9: Close polyline and flood fill with current color at offset from vertex 0
        // Format: C9 offset_byte (high nibble=X offset, low nibble=Y offset)
        final cmdStart = i;
        i++;

        if (i < end && lastPolylineVertex0 != null) {
          final offsetByte = buffer[i];

          // Decode offset: high nibble = X, low nibble = Y
          final offsetX = (offsetByte >> 4) & 0x0F;
          final offsetY = offsetByte & 0x0F;

          // Calculate absolute fill position: vertex0 + offset
          final fillX = lastPolylineVertex0.dx + offsetX;
          final fillY = lastPolylineVertex0.dy + offsetY;

          // Single command: close polyline + flood fill
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.closedPolyline,
              colorIndex: currentColor,
              points: [], // Points come from previous polyline
              fillPattern: currentColor,
              fillSeed: Offset(fillX, fillY),
              hexBytes: _getHexString(buffer, cmdStart, 2),
            ),
          );

          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              2,
              'C9: Close+Fill color=$currentColor vertex0=$lastPolylineVertex0 offset=($offsetX,$offsetY) → fill@($fillX,$fillY)',
            );
          }

          i += 1;
        } else {
          if (enableLogging && lastPolylineVertex0 == null) {
            _log('C9 command without previous polyline vertex 0 - skipping');
          }
          break; // Incomplete command or no previous polyline
        }
      } else if (byte == 0xCC) {
        // CC: Flood fill at specific point
        final cmdStart = i;
        if (i + 3 < end) {
          final ab = buffer[i + 1];
          final xx = buffer[i + 2];
          final yy = buffer[i + 3];

          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.floodFillAt,
              fillPattern: ab,
              fillSeed: Offset(xx.toDouble(), yy.toDouble()),
              hexBytes: _getHexString(buffer, cmdStart, 4),
            ),
          );

          if (enableLogging) {
            // Decode pattern for display
            final pattern = ab <= 3
                ? 'solid color $ab'
                : '${(ab >> 6) & 3},${(ab >> 4) & 3},${(ab >> 2) & 3},${ab & 3}';
            _logCommand(
              buffer,
              cmdStart,
              4,
              'Flood fill pattern $pattern x,y=$xx,$yy',
            );
          }

          i += 4;
        } else {
          break; // Incomplete command
        }
      } else if (byte == 0xCD) {
        // CD: Polyline with color 0
        final cmdStart = i;
        i++;
        currentColor = 0;
        final points = _readPoints(buffer, i, end);
        if (points.isNotEmpty) {
          lastPolylineVertex0 = points[0]; // Track first vertex for C9/CA
          final cmdLength = 1 + (points.length * 2);
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.polyline,
              colorIndex: 0,
              points: points,
              hexBytes: _getHexString(buffer, cmdStart, cmdLength),
            ),
          );
          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              cmdLength,
              'Polyline color=0, ${points.length} pts',
            );
          }
          i += points.length * 2;
        }
      } else if (byte == 0xCE) {
        // CE: Polyline with color 1
        final cmdStart = i;
        i++;
        currentColor = 1;
        final points = _readPoints(buffer, i, end);
        if (points.isNotEmpty) {
          lastPolylineVertex0 = points[0]; // Track first vertex for C9/CA
          final cmdLength = 1 + (points.length * 2);
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.polyline,
              colorIndex: 1,
              points: points,
              hexBytes: _getHexString(buffer, cmdStart, cmdLength),
            ),
          );
          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              cmdLength,
              'Polyline color=1, ${points.length} pts',
            );
          }
          i += points.length * 2;
        }
      } else if (byte == 0xCF) {
        // CF: Polyline with color 2
        final cmdStart = i;
        i++;
        currentColor = 2;
        final points = _readPoints(buffer, i, end);
        if (points.isNotEmpty) {
          lastPolylineVertex0 = points[0]; // Track first vertex for C9/CA
          final cmdLength = 1 + (points.length * 2);
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.polyline,
              colorIndex: 2,
              points: points,
              hexBytes: _getHexString(buffer, cmdStart, cmdLength),
            ),
          );
          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              cmdLength,
              'Polyline color=2, ${points.length} pts',
            );
          }
          i += points.length * 2;
        }
      } else if (byte == 0xD0) {
        // D0: Polyline with color 3
        final cmdStart = i;
        i++;
        currentColor = 3;
        final points = _readPoints(buffer, i, end);
        if (points.isNotEmpty) {
          lastPolylineVertex0 = points[0]; // Track first vertex for C9/CA
          final cmdLength = 1 + (points.length * 2);
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.polyline,
              colorIndex: 3,
              points: points,
              hexBytes: _getHexString(buffer, cmdStart, cmdLength),
            ),
          );
          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              cmdLength,
              'Polyline color=3, ${points.length} pts',
            );
          }
          i += points.length * 2;
        }
      } else if (byte < 0xA0) {
        // Implicit polyline: byte is a coordinate (< 160/0xA0), not a command
        // Treat as if we had a C8 command with current color
        final cmdStart = i;
        final points = _readPoints(buffer, i, end);
        if (points.isNotEmpty) {
          lastPolylineVertex0 = points[0]; // Track first vertex for C9/CA
          final cmdLength = points.length * 2;
          commands.add(
            AtariBytecodeCommand(
              type: BytecodeCommandType.polyline,
              colorIndex: currentColor,
              points: points,
              hexBytes: _getHexString(buffer, cmdStart, cmdLength),
            ),
          );
          if (enableLogging) {
            _logCommand(
              buffer,
              cmdStart,
              cmdLength,
              'Implicit Polyline color=$currentColor, ${points.length} pts',
            );
          }
          i += points.length * 2;
        } else {
          // No valid points - skip this byte and continue
          // This can happen with orphaned bytes after C9 commands or data padding
          if (enableLogging) {
            _log(
              '${byte.toRadixString(16).toUpperCase()} - Skipping invalid/orphaned byte',
            );
          }
          i++;
        }
      } else {
        // Unknown or stop byte (> 0xA0 and not a known command)
        if (enableLogging) {
          // Check if this is a room marker
          if (byte >= 0xA0 && byte <= 0xBB) {
            final nextRoom = byte - 0xA0;
            _log(
              '${byte.toRadixString(16).toUpperCase()} - Stopping as room ${nextRoom.toRadixString(16).toUpperCase()} starts',
            );
          } else {
            _log(
              '${byte.toRadixString(16).toUpperCase()} - Stopping ($stopReason)',
            );
          }
          _dumpStopContext(buffer, i);
        }
        break;
      }
    }

    // Log stop reason if we reached the end naturally
    if (enableLogging && i >= end) {
      // We stopped because we reached the pre-calculated end position
      if (end < buffer.length) {
        final stopByte = buffer[end];
        if (stopByte >= 0xA0 && stopByte <= 0xBB) {
          final nextRoom = stopByte - 0xA0;
          _log(
            '${stopByte.toRadixString(16).toUpperCase()} - Stopping as room ${nextRoom.toRadixString(16).toUpperCase()} starts',
          );
        } else if (stopByte == 0xFF) {
          _log('FF - Stopping (explicit end marker 0xFF)');
        } else {
          _log('Stopping ($stopReason)');
        }
        _dumpStopContext(buffer, end);
      } else {
        _log('Stopping (end of buffer)');
      }
    }

    return commands;
  }

  /// Read coordinate pairs until next command byte or stop condition
  static List<Offset> _readPoints(Uint8List buffer, int start, int end) {
    final points = <Offset>[];
    int i = start;

    // Read coordinates until we hit:
    // - A command byte (>= 0xC8)
    // - A room marker (>= 0xA0 and < 0xC0)
    // - End of buffer
    while (i + 1 < end) {
      final x = buffer[i];

      // Stop if this is a command byte or room marker
      if (x >= 0xC8 || (x >= 0xA0 && x < 0xC0)) {
        break;
      }

      final y = buffer[i + 1];

      // Also check Y coordinate for stop conditions
      if (y >= 0xC8 || (y >= 0xA0 && y < 0xC0)) {
        break;
      }

      points.add(Offset(x.toDouble(), y.toDouble()));
      i += 2;
    }

    return points;
  }

  /// Convert Atari color byte to RGB
  static Color _atariColorToRgb(int atariColor) {
    if (atariColor < 0 || atariColor > 255) {
      return const Color(0xFF000000);
    }

    final hue = (atariColor >> 4) & 0x0F;
    final luminance = atariColor & 0x0F;

    // Use same color generation as AtariColors
    return _generateColor(hue, luminance);
  }

  /// Generate RGB color from hue and luminance
  static Color _generateColor(int hue, int lum) {
    final brightness = (lum / 14.0).clamp(0.0, 1.0);

    switch (hue) {
      case 0x0: // Grays
        final gray = (brightness * 255).round();
        return Color.fromARGB(255, gray, gray, gray);

      case 0x1: // Brown/Rust
        return Color.fromARGB(
          255,
          (139 * brightness).round(),
          (90 * brightness).round(),
          (43 * brightness).round(),
        );

      case 0x2: // Red-Orange
        return Color.fromARGB(
          255,
          (255 * brightness).round(),
          (140 * brightness).round(),
          0,
        );

      case 0x3: // Dark Orange
        return Color.fromARGB(
          255,
          (205 * brightness).round(),
          (92 * brightness).round(),
          (92 * brightness).round(),
        );

      case 0x4: // Red
        return Color.fromARGB(255, (139 * brightness).round(), 0, 0);

      case 0x5: // Violet/Lavender
        return Color.fromARGB(
          255,
          (138 * brightness).round(),
          (43 * brightness).round(),
          (226 * brightness).round(),
        );

      case 0x6: // Blue
        return Color.fromARGB(255, 0, 0, (139 * brightness).round());

      case 0x7: // Light Blue
        return Color.fromARGB(
          255,
          (65 * brightness).round(),
          (105 * brightness).round(),
          (225 * brightness).round(),
        );

      case 0x8: // Blue-Cyan
        return Color.fromARGB(
          255,
          0,
          (139 * brightness).round(),
          (139 * brightness).round(),
        );

      case 0x9: // Cyan
        return Color.fromARGB(
          255,
          0,
          (180 * brightness).round(),
          (180 * brightness).round(),
        );

      case 0xA: // Green-Cyan
        return Color.fromARGB(
          255,
          0,
          (128 * brightness).round(),
          (128 * brightness).round(),
        );

      case 0xB: // Green
        return Color.fromARGB(255, 0, (139 * brightness).round(), 0);

      case 0xC: // Yellow-Green
        return Color.fromARGB(
          255,
          (154 * brightness).round(),
          (205 * brightness).round(),
          (50 * brightness).round(),
        );

      case 0xD: // Orange-Green
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
          0,
        );

      case 0xF: // Gold
        return Color.fromARGB(
          255,
          (255 * brightness).round(),
          (215 * brightness).round(),
          0,
        );

      default:
        return const Color(0xFF000000);
    }
  }
}
