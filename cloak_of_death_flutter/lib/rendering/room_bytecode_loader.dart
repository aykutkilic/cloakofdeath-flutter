import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/// Loader for room bytecode data from binary file extracted from cassette
///
/// This loads the raw FIND bytecode for all 27 rooms from assets/rooms.bin
/// Format: Continuous binary stream with room markers (0xA0+id) + 4 palette bytes + drawing commands
class RoomBytecodeLoader {
  static Uint8List? _binaryData;
  static final Map<int, _RoomLocation> _roomLocations = {};
  static bool _initialized = false;

  /// Initialize and load the binary data
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load binary file from assets
    final ByteData data = await rootBundle.load('assets/rooms.bin');
    _binaryData = data.buffer.asUint8List();

    // Parse room locations
    _parseRoomLocations();
    _initialized = true;
  }

  /// Parse the binary data to find all room markers and their locations
  static void _parseRoomLocations() {
    if (_binaryData == null) return;

    for (int i = 0; i < _binaryData!.length; i++) {
      final byte = _binaryData![i];

      // Check if this is a room marker (0xA0-0xBB = rooms 0-27)
      if (byte >= 0xA0 && byte <= 0xBB) {
        final roomId = byte - 0xA0;

        // Find the end of this room (next room marker or end of file)
        int endOffset = _binaryData!.length;
        for (int j = i + 1; j < _binaryData!.length; j++) {
          if (_binaryData![j] >= 0xA0 && _binaryData![j] <= 0xBB) {
            endOffset = j;
            break;
          }
        }

        _roomLocations[roomId] = _RoomLocation(i, endOffset);
      }
    }
  }

  /// Get bytecode buffer for a specific room
  static Uint8List? getRoomBuffer(int roomId) {
    if (!_initialized || _binaryData == null) {
      throw StateError(
          'RoomBytecodeLoader not initialized. Call initialize() first.');
    }

    final location = _roomLocations[roomId];
    if (location == null) return null;

    return _binaryData!.sublist(location.start, location.end);
  }

  /// Get all available room IDs
  static List<int> get availableRooms {
    if (!_initialized) {
      throw StateError(
          'RoomBytecodeLoader not initialized. Call initialize() first.');
    }
    return _roomLocations.keys.toList()..sort();
  }

  /// Check if room bytecode exists
  static bool hasRoom(int roomId) {
    if (!_initialized) {
      throw StateError(
          'RoomBytecodeLoader not initialized. Call initialize() first.');
    }
    return _roomLocations.containsKey(roomId);
  }

  /// Get room size in bytes
  static int? getRoomSize(int roomId) {
    if (!_initialized) {
      throw StateError(
          'RoomBytecodeLoader not initialized. Call initialize() first.');
    }

    final location = _roomLocations[roomId];
    if (location == null) return null;

    return location.end - location.start;
  }
}

/// Internal class to track room location in binary data
class _RoomLocation {
  final int start;
  final int end;

  _RoomLocation(this.start, this.end);
}
