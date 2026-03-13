import 'dart:typed_data';
import '../data/room_definitions.dart';

/// Loader for room bytecode data from compiled room definitions.
///
/// Room bytecode is now embedded directly in Dart source
/// (lib/data/room_definitions.dart) rather than loaded from a binary asset.
class RoomBytecodeLoader {
  static final Map<int, RoomDefinition> _roomMap = {
    for (final room in roomDefinitions) room.id: room,
  };

  /// No-op — data is compiled in. Kept for API compatibility.
  static Future<void> initialize() async {}

  /// Get bytecode buffer for a specific room.
  static Uint8List? getRoomBuffer(int roomId) {
    return _roomMap[roomId]?.bytecode;
  }

  /// Get room definition (bytecode + metadata).
  static RoomDefinition? getRoomDefinition(int roomId) {
    return _roomMap[roomId];
  }

  /// Get all available room IDs.
  static List<int> get availableRooms {
    return _roomMap.keys.toList()..sort();
  }

  /// Check if room bytecode exists.
  static bool hasRoom(int roomId) {
    return _roomMap.containsKey(roomId);
  }

  /// Get room size in bytes.
  static int? getRoomSize(int roomId) {
    return _roomMap[roomId]?.bytecode.length;
  }
}
