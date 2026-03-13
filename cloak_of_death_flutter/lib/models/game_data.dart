import 'room.dart';
import '../data/room_definitions.dart';

/// Holds all game data
class GameData {
  final List<Room> rooms;

  GameData({
    required this.rooms,
  });

  /// Load game data from compiled room definitions.
  static Future<GameData> loadFromAssets() async {
    final roomsList = roomDefinitions.map((def) => Room(
      id: def.id,
      name: def.name,
      description: def.description,
      exits: def.exits,
    )).toList();

    return GameData(rooms: roomsList);
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
