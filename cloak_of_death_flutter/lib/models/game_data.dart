import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'room.dart';
import 'vector_command.dart';
import '../rendering/room_bytecode_data.dart';

/// Holds all game data loaded from JSON
class GameData {
  final Map<String, dynamic> metadata;
  final List<Room> rooms;

  GameData({
    required this.metadata,
    required this.rooms,
  });

  /// Load game data from JSON asset file
  static Future<GameData> loadFromAssets() async {
    final String jsonString =
        await rootBundle.loadString('assets/room_vectors.json');
    final Map<String, dynamic> json = jsonDecode(jsonString);

    // New format has rooms as a map with room IDs as keys
    final roomsMap = json['rooms'] as Map<String, dynamic>;
    final List<Room> roomsList = [];

    roomsMap.forEach((key, value) {
      final roomData = value as Map<String, dynamic>;
      final roomId = int.parse(key);

      // Load bytecode data for pixel rendering
      final bytecode = RoomBytecodeData.getRoomBuffer(roomId);

      roomsList.add(Room(
        id: roomId,
        name: _getRoomName(roomId),
        description: _getRoomDescription(roomId),
        vectors: (roomData['commands'] as List)
            .map((c) => VectorCommand.fromJson(c as Map<String, dynamic>))
            .toList(),
        exits: _getRoomExits(roomId),
        objects: const [],
        rawBytes: roomData['raw_bytes'] != null
            ? (roomData['raw_bytes'] as List).map((e) => e as int).toList()
            : const [],
        bytecodeData: bytecode,
      ));
    });

    return GameData(
      metadata: {
        'format_version': json['format_version'],
        'description': json['description'],
        'coordinate_system': json['coordinate_system'],
      },
      rooms: roomsList,
    );
  }

  static String _getRoomName(int roomId) {
    // Room names from the BASIC code
    final names = {
      1: 'Entrance Hall',
      2: 'Dining Room',
      3: 'Kitchen',
      4: 'Pantry',
      5: 'Dark Corridor',
      6: 'Conservatory',
      7: 'Oak Panelled Study',
      8: 'Sitting Room',
      9: 'Upstairs Hallway',
      10: 'Guest Bedroom',
      11: 'Dressing Room',
      12: 'Annexe',
      13: 'Master Bedroom',
      14: 'Icy Corridor',
      15: 'Haunted Room',
      16: 'Library',
      17: 'Secret Passageway',
      18: 'Old Attic',
      19: 'Tower',
      20: 'Cellar',
      21: 'Wine Cellar',
      22: 'Store Room',
      23: 'Crypt',
      24: 'Underground Chamber',
      25: 'Torture Chamber',
      26: 'Dark Passage',
      27: 'Exit',
    };
    return names[roomId] ?? 'Unknown Room';
  }

  static String _getRoomDescription(int roomId) {
    final descriptions = {
      1: 'in the entrance hall',
      2: 'in a large dining room',
      3: 'in the kitchen',
      4: 'standing in the pantry',
      5: 'in a dark eerie corridor',
      6: 'in a conservatory',
      7: 'in an oak panelled study',
      8: 'in a large sitting room',
      9: 'standing in an upstairs hallway',
      10: 'in a guest bedroom',
      11: 'in a dressing room',
      12: 'in a small annexe',
      13: 'in the master bedroom',
      14: 'standing in an icy corridor',
      15: 'in a haunted room',
      16: 'in the library',
      17: 'in a secret passageway',
      18: 'in an old attic',
      19: 'in a tower',
      20: 'in the cellar',
      21: 'in the wine cellar',
      22: 'in a store room',
      23: 'in a crypt',
      24: 'in an underground chamber',
      25: 'in a torture chamber',
      26: 'in a dark passage',
      27: 'outside the house!',
    };
    return descriptions[roomId] ?? 'in an unknown location';
  }

  static List<String> _getRoomExits(int roomId) {
    // Basic exit data from game_state.dart room connections
    final exits = {
      1: ['N', 'W', 'E'],
      2: ['S', 'N', 'E'],
      3: ['E', 'N', 'W'],
      4: ['W', 'N', 'E'],
      5: ['S', 'N', 'E'],
      6: ['W', 'S', 'N'],
      7: ['S', 'E', 'N'],
      8: ['E', 'W', 'N'],
      9: ['S', 'E', 'N'],
      10: ['W', 'S', 'N'],
      11: ['S', 'N', 'E'],
      12: ['W', 'S', 'N'],
      13: ['S', 'E', 'N'],
      14: ['W', 'S', 'N'],
      15: ['S', 'E', 'N'],
      16: ['W', 'S', 'N'],
      17: ['S', 'E', 'N'],
      18: ['W', 'S', 'N'],
      19: ['W', 'E', 'N'],
      20: ['E', 'S', 'W'],
      21: ['S', 'E', 'W'],
      22: ['E', 'S', 'W'],
      23: ['E', 'S', 'W'],
      24: ['E', 'S', 'W'],
      25: ['E', 'S', 'W'],
      26: ['E', 'S', 'W'],
      27: ['E', 'S'],
    };
    return exits[roomId] ?? [];
  }

  /// Get a room by its ID
  Room? getRoomById(int id) {
    try {
      return rooms.firstWhere((room) => room.id == id);
    } catch (e) {
      return null;
    }
  }

  int get totalRooms => rooms.length;
}
