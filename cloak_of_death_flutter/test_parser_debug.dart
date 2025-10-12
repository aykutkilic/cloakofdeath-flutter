import 'dart:typed_data';
import 'lib/rendering/room_bytecode_data.dart';
import 'lib/rendering/atari_bytecode_parser.dart';

void main() {
  print('Testing Room 1 bytecode parser with detailed logging...\n');

  final buffer = RoomBytecodeData.getRoomBuffer(1);
  if (buffer == null) {
    print('ERROR: Room 1 buffer is null!');
    return;
  }

  print('✓ Room 1 buffer size: ${buffer.length} bytes');
  print('  First 30 bytes:');
  for (int i = 0; i < 30 && i < buffer.length; i++) {
    final byte = buffer[i];
    final hex = byte.toRadixString(16).padLeft(2, '0');
    final chr = byte >= 0x20 && byte < 0x7F ? String.fromCharCode(byte) : '.';
    print('    [$i] 0x$hex ($byte) \'$chr\'');
  }

  // Manual parse to debug
  print('\n--- Manual Parse Debug ---');

  // Find marker
  final marker = 0xA1; // Room 1
  int startPos = -1;
  for (int i = 0; i < buffer.length; i++) {
    if (buffer[i] == marker) {
      startPos = i;
      break;
    }
  }

  print('Marker 0xA1 found at: $startPos');

  if (startPos == -1) {
    print('ERROR: Marker not found!');
    return;
  }

  // Parse palette
  print('\nPalette bytes (positions ${startPos + 1} to ${startPos + 4}):');
  for (int i = 1; i <= 4; i++) {
    final byte = buffer[startPos + i];
    print('  [$i] 0x${byte.toRadixString(16).padLeft(2, '0')} ($byte)');
  }

  // Find end position
  int endPos = buffer.length;
  for (int i = startPos + 5; i < buffer.length; i++) {
    final b = buffer[i];
    if (b == 0xFF || (b >= 0xA0 && b <= 0xBB) || b < 0xC0) {
      endPos = i;
      print('\nEnd marker found at position $i: 0x${b.toRadixString(16)} ($b)');
      break;
    }
  }

  print('Command range: ${startPos + 5} to $endPos (${endPos - (startPos + 5)} bytes)');

  // Show command bytes
  print('\nCommand bytes:');
  for (int i = startPos + 5; i < endPos && i < startPos + 50; i++) {
    final byte = buffer[i];
    final hex = byte.toRadixString(16).padLeft(2, '0');
    final isCommand = byte >= 0xC8 && byte <= 0xD0;
    final marker = isCommand ? ' <-- CMD' : '';
    print('  [$i] 0x$hex ($byte)$marker');
  }

  // Now try actual parser
  print('\n--- Calling AtariBytecodeParser.parseRoom() ---');
  final roomData = AtariBytecodeParser.parseRoom(buffer, 1);

  if (roomData == null) {
    print('ERROR: Parser returned null!');
    return;
  }

  print('✓ Parsed successfully!');
  print('  Room ID: ${roomData.roomId}');
  print('  Palette: ${roomData.palette.length} colors');
  print('  Commands: ${roomData.commands.length}');
  print('  Raw bytes: ${roomData.rawBytes.length}');

  if (roomData.commands.isEmpty) {
    print('\n⚠ WARNING: No commands parsed!');
  } else {
    print('\n✓ Commands:');
    for (int i = 0; i < roomData.commands.length; i++) {
      final cmd = roomData.commands[i];
      print('  ${i + 1}. ${cmd.type} (color=${cmd.colorIndex}, points=${cmd.points.length})');
    }
  }
}
