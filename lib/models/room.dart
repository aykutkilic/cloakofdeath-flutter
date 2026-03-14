/// Represents a room in the game
class Room {
  final int id;
  final String name;
  final String description;
  final List<String> exits;
  final Map<String, int> connections;
  final List<String> objects;

  Room({
    required this.id,
    required this.name,
    required this.description,
    required this.exits,
    this.connections = const {},
    this.objects = const [],
  });

  @override
  String toString() => 'Room(id: $id, name: $name)';
}
