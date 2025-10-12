import 'lib/rendering/room_bytecode_loader.dart';
import 'lib/rendering/atari_bytecode_parser.dart';

/// Test script to demonstrate bytecode parsing with logging
void main() async {
  print('=== Bytecode Parser Logging Test ===\n');

  // Initialize the loader
  await RoomBytecodeLoader.initialize();

  // Test a few rooms to show the logging
  final testRooms = [1, 2, 3];

  for (final roomId in testRooms) {
    print('\n--- Testing Room $roomId ---');

    final buffer = RoomBytecodeLoader.getRoomBuffer(roomId);
    if (buffer == null) {
      print('Room $roomId: No buffer data');
      continue;
    }

    // Parse with logging enabled
    final roomData = AtariBytecodeParser.parseRoom(buffer, roomId, enableLogging: true);

    if (roomData == null) {
      print('Room $roomId: Failed to parse');
    } else {
      print('Room $roomId: Successfully parsed ${roomData.commands.length} commands');
    }

    print('');
  }

  print('\n=== Test Complete ===');
  print('Check the console logs above to see detailed parsing information.');
  print('Logs include:');
  print('  - Room marker positions');
  print('  - Palette data');
  print('  - Data range and stop reason');
  print('  - Each command with its type, color, and point count');
  print('  - Why parsing stopped (next room marker, end marker, etc.)');
}
