import 'package:flutter_test/flutter_test.dart';
import 'package:cloak_of_death_flutter/rendering/atari_bytecode_parser.dart';
import 'package:cloak_of_death_flutter/rendering/atari_pixel_renderer.dart';
import 'package:cloak_of_death_flutter/rendering/atari_screen_buffer.dart';
import 'package:cloak_of_death_flutter/rendering/room_bytecode_loader.dart';

AtariScreenBuffer _render(int roomId) {
  final buf = RoomBytecodeLoader.getRoomBuffer(roomId)!;
  final room = AtariBytecodeParser.parseRoom(buf, roomId)!;
  final screen = AtariScreenBuffer();
  AtariPixelRenderer.renderAll(screen, room);
  screen.flushAllPending();
  return screen;
}

void main() {
  test('all rooms render without throwing (CA pattern bytes)', () {
    // Rooms 11,13,15,16,18,21,22,23,26 contain CA commands whose color byte
    // is a pattern byte (> 3) and used to crash with a palette RangeError.
    for (final roomId in RoomBytecodeLoader.availableRooms) {
      if (RoomBytecodeLoader.getRoomBuffer(roomId)!.isEmpty) continue;
      expect(() => _render(roomId), returnsNormally, reason: 'room $roomId');
    }
  });

  test('room 8 doorway is boundary-filled with the CC 64 pattern', () {
    // CC 64 3F 1A fills the open doorway (x 70-80, y 26-39) with pattern
    // [1,2,1,0], plowing through the color-2 frame line and color-3 interior
    // and stopping at black — the original $8BA3 boundary-fill behavior.
    // A seed-color-match fill only repaints the 1-px frame line instead.
    final screen = _render(8);
    final room = AtariBytecodeParser.parseRoom(
      RoomBytecodeLoader.getRoomBuffer(8)!,
      8,
    )!;
    int argb(int i) => AtariScreenBuffer.colorToArgb(room.palette[i]);

    // Inside the doorway, above the black bar at y=40: pattern columns.
    expect(screen.peek(76, 30), argb(1)); // x%4==0 -> color 1
    expect(screen.peek(73, 30), argb(2)); // x%4==1 -> color 2
    expect(screen.peek(75, 30), argb(0)); // x%4==3 -> color 0 (black)
    // Below the bar the CA 03 gray fill must survive untouched.
    expect(screen.peek(76, 45), argb(3));
  });
}
