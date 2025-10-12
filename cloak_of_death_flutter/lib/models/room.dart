import 'dart:typed_data';
import 'vector_command.dart';

/// CAS file location metadata
class RoomLocation {
  final String sectionName;
  final String chunkRange;
  final int sectionByteOffset;

  const RoomLocation(this.sectionName, this.chunkRange, this.sectionByteOffset);
}

/// Represents a room in the game
class Room {
  final int id;
  final String name;
  final String description;
  final List<VectorCommand> vectors;
  final List<String> exits;
  final List<String> objects;
  final List<int> rawBytes; // Raw hex data from CAS file
  final Uint8List? bytecodeData; // Raw FIND bytecode format data (optional)

  /// Mapping of room IDs to their CAS file locations
  static const Map<int, RoomLocation> _roomLocations = {
    1: RoomLocation('Section 1', '117-159', 4799),
    2: RoomLocation('Section 2', '160-204', 74),
    3: RoomLocation('Section 1', '117-159', 5276),
    4: RoomLocation('Section 2', '160-204', 936),
    5: RoomLocation('Section 2', '160-204', 1331),
    6: RoomLocation('Section 2', '160-204', 1119),
    7: RoomLocation('Section 2', '160-204', 703),
    8: RoomLocation('Section 2', '160-204', 446),
    9: RoomLocation('Section 1', '117-159', 4401),
    10: RoomLocation('Section 2', '160-204', 3548),
    11: RoomLocation('Section 2', '160-204', 2410),
    12: RoomLocation('Section 2', '160-204', 3778),
    13: RoomLocation('Section 2', '160-204', 3170),
    14: RoomLocation('Section 2', '160-204', 2813),
    15: RoomLocation('Section 2', '160-204', 767),
    16: RoomLocation('Section 2', '160-204', 639),
    17: RoomLocation('Section 1', '117-159', 4388),
    18: RoomLocation('Section 2', '160-204', 1828),
    19: RoomLocation('Section 2', '160-204', 383),
    20: RoomLocation('Section 2', '160-204', 2607),
    21: RoomLocation('Section 2', '160-204', 261),
    22: RoomLocation('Section 2', '160-204', 4427),
    23: RoomLocation('Section 2', '160-204', 2165),
    24: RoomLocation('Section 2', '160-204', 3331),
    25: RoomLocation('Section 2', '160-204', 2960),
    26: RoomLocation('Section 2', '160-204', 1998),
    27: RoomLocation('Section 2', '160-204', 3917),
  };

  Room({
    required this.id,
    required this.name,
    required this.description,
    required this.vectors,
    required this.exits,
    this.objects = const [],
    this.rawBytes = const [],
    this.bytecodeData,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      vectors: (json['vectors'] as List)
          .map((v) => VectorCommand.fromJson(v as Map<String, dynamic>))
          .toList(),
      exits: (json['exits'] as List).map((e) => e as String).toList(),
      objects: json['objects'] != null
          ? (json['objects'] as List).map((e) => e as String).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'vectors': vectors.map((v) => v.toJson()).toList(),
      'exits': exits,
      'objects': objects,
    };
  }

  /// Get hex bytes and location for a specific command
  /// Returns a map with 'hex' and 'location' keys
  Map<String, dynamic> getCommandInfo(int commandIndex) {
    if (rawBytes.isEmpty) {
      return {'hex': 'No raw bytes', 'location': 'No location data'};
    }
    if (commandIndex < 0 || commandIndex >= vectors.length) {
      return {'hex': 'Invalid index', 'location': 'Invalid index'};
    }

    // Command opcodes are 0xC8-0xCF
    const opcodes = {0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xCF};

    // Skip marker (1 byte) and header (4 bytes)
    int bytePos = 5;
    int cmdCount = 0;

    // Find the start of our target command
    while (bytePos < rawBytes.length && cmdCount < commandIndex) {
      if (opcodes.contains(rawBytes[bytePos])) {
        cmdCount++;
      }
      bytePos++;
    }

    // Now at the start of our command
    if (bytePos >= rawBytes.length || !opcodes.contains(rawBytes[bytePos])) {
      return {'hex': 'Not found', 'location': 'Not found'};
    }

    final startPos = bytePos;
    bytePos++; // Move past opcode

    // Read parameters until next opcode or end
    while (bytePos < rawBytes.length && !opcodes.contains(rawBytes[bytePos])) {
      bytePos++;
    }

    // Extract command bytes
    final commandBytes = rawBytes.sublist(startPos, bytePos);
    final hexString = commandBytes.map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0')).join(' ');

    // Get CAS file location
    final location = _roomLocations[id];
    final String locationString;
    if (location != null) {
      final absoluteByte = location.sectionByteOffset + startPos;
      locationString = 'Chunks ${location.chunkRange}, ${location.sectionName} byte $absoluteByte';
    } else {
      locationString = 'Unknown location';
    }

    return {
      'hex': hexString,
      'location': locationString,
    };
  }

  @override
  String toString() => 'Room(id: $id, name: $name)';
}
