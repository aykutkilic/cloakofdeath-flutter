import 'lib/rendering/room_bytecode_data.dart';
import 'lib/rendering/atari_bytecode_parser.dart';

void main() {
  print('Testing Room 8 bytecode parser with logging enabled...\n');

  final buffer = RoomBytecodeData.getRoomBuffer(8);
  if (buffer == null) {
    print('ERROR: Room 8 buffer is null!');
    return;
  }

  print('✓ Room 8 buffer size: ${buffer.length} bytes\n');

  // Parse with logging enabled
  final roomData = AtariBytecodeParser.parseRoom(buffer, 8, enableLogging: true);
  if (roomData == null) {
    print('\nERROR: Failed to parse room 8!');
    return;
  }

  print('\n✓ Parsed successfully!');
  print('  Room ID: ${roomData.roomId}');
  print('  Palette: ${roomData.palette.length} colors');
  print('  Commands: ${roomData.commands.length}');

  if (roomData.commands.isEmpty) {
    print('\n⚠ WARNING: No commands parsed!');
  } else {
    print('\n✓ All commands:');
    for (int i = 0; i < roomData.commands.length; i++) {
      final cmd = roomData.commands[i];
      print('  ${i + 1}. ${cmd.type} (color=${cmd.colorIndex}, points=${cmd.points.length})');
    }
  }
}
