import 'dart:typed_data';
import 'lib/rendering/room_bytecode_data.dart';

/// Scan bytecode buffer to find all room markers
void main() {
  if (kDebugMode) {
    print('=== Scanning for Room Markers ===\n');
  }

  // Collect all room buffers into one combined buffer
  final availableRooms = RoomBytecodeData.availableRooms;
  final buffers = <Uint8List>[];

  for (final roomId in availableRooms) {
    final roomBuffer = RoomBytecodeData.getRoomBuffer(roomId);
    if (roomBuffer != null) {
      buffers.add(roomBuffer);
    }
  }

  // Combine all buffers
  final totalSize = buffers.fold<int>(0, (sum, buf) => sum + buf.length);
  final buffer = Uint8List(totalSize);
  int offset = 0;
  for (final buf in buffers) {
    buffer.setRange(offset, offset + buf.length, buf);
    offset += buf.length;
  }

  print('Total buffer size: ${buffer.length} bytes');
  print('Available rooms: ${availableRooms.join(", ")}\n');

  print('Room markers found (0xA0-0xBB = rooms 0-27):');
  print('-' * 60);

  for (int i = 0; i < buffer.length; i++) {
    final byte = buffer[i];
    if (byte >= 0xA0 && byte <= 0xBB) {
      final roomId = byte - 0xA0;
      final hex = byte.toRadixString(16).toUpperCase();

      // Show context around the room marker
      final start = (i - 5).clamp(0, buffer.length);
      final end = (i + 10).clamp(0, buffer.length);
      final context = buffer.sublist(start, end);
      final contextHex = context
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(' ');

      print('Position $i: 0x$hex (Room $roomId)');
      print('  Context: $contextHex');

      // Look ahead to next room marker
      int nextPos = -1;
      for (int j = i + 1; j < buffer.length; j++) {
        if (buffer[j] >= 0xA0 && buffer[j] <= 0xBB) {
          nextPos = j;
          break;
        }
      }

      if (nextPos > 0) {
        final distance = nextPos - i;
        final nextRoomId = buffer[nextPos] - 0xA0;
        print(
          '  Next room: $nextPos (Room $nextRoomId, distance: $distance bytes)',
        );
      } else {
        print('  Next room: End of buffer');
      }
      print('');
    }
  }

  print('=== Scan Complete ===');
}
