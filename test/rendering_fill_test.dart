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
      expect(
        RoomBytecodeLoader.getRoomBuffer(roomId),
        isNotEmpty,
        reason: 'room $roomId must have artwork',
      );
      expect(() => _render(roomId), returnsNormally, reason: 'room $roomId');
    }
  });

  test('upstairs hallway has its complete original drawing', () {
    final data = RoomBytecodeLoader.getRoomBuffer(9)!;
    expect(data.length, 157);
    final room = AtariBytecodeParser.parseRoom(data, 9)!;
    expect(room.commands.length, greaterThan(15));
    final screen = _render(9);
    final colors = <int>{
      for (var y = 0; y < 96; y++)
        for (var x = 0; x < 160; x++) screen.peek(x, y),
    };
    expect(colors.length, 4);
  });

  test('hallway ceiling and inner right door have solid interiors', () {
    final screen = _render(9);
    final room = AtariBytecodeParser.parseRoom(
      RoomBytecodeLoader.getRoomBuffer(9)!,
      9,
    )!;
    int argb(int i) => AtariScreenBuffer.colorToArgb(room.palette[i]);
    expect(screen.peek(80, 10), argb(2)); // ceiling
    expect(screen.peek(109, 40), argb(1)); // inner right door
    expect(screen.peek(54, 40), argb(1)); // matching left door
    expect(screen.peek(100, 25), argb(3)); // wall survives
    expect(screen.peek(80, 80), argb(1)); // runner survives
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
