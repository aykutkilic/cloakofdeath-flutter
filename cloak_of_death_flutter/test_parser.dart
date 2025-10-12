import 'lib/rendering/room_bytecode_data.dart';
import 'lib/rendering/atari_bytecode_parser.dart';

void main() {
  print('Testing Room 1 bytecode parser...\n');

  final buffer = RoomBytecodeData.getRoomBuffer(1);
  if (buffer == null) {
    print('ERROR: Room 1 buffer is null!');
    return;
  }

  print('✓ Room 1 buffer size: ${buffer.length} bytes');
  print('  First 10 bytes: ${buffer.sublist(0, 10).map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');

  final roomData = AtariBytecodeParser.parseRoom(buffer, 1);
  if (roomData == null) {
    print('ERROR: Failed to parse room 1!');
    return;
  }

  print('\n✓ Parsed successfully!');
  print('  Room ID: ${roomData.roomId}');
  print('  Palette: ${roomData.palette.length} colors');
  print('  Commands: ${roomData.commands.length}');

  if (roomData.commands.isEmpty) {
    print('\n⚠ WARNING: No commands parsed!');
    print('  Raw bytes length: ${roomData.rawBytes.length}');
  } else {
    print('\n✓ First 10 commands:');
    for (int i = 0; i < roomData.commands.length && i < 10; i++) {
      final cmd = roomData.commands[i];
      print('  ${i + 1}. ${cmd.type} (color=${cmd.colorIndex}, points=${cmd.points.length})');
    }
  }

  // Test all available rooms
  print('\n\nTesting all available rooms:');
  final allRooms = RoomBytecodeData.availableRooms;
  for (final roomId in allRooms) {
    final buf = RoomBytecodeData.getRoomBuffer(roomId);
    final data = AtariBytecodeParser.parseRoom(buf!, roomId);
    if (data != null) {
      print('  Room $roomId: ${data.commands.length} commands');
    } else {
      print('  Room $roomId: PARSE FAILED');
    }
  }
}
