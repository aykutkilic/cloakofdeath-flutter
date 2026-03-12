import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloak_of_death_flutter/rendering/atari_pixel_renderer.dart';
import 'package:cloak_of_death_flutter/rendering/atari_bytecode_parser.dart';

void main() {
  testWidgets('Compare renders', (WidgetTester tester) async {
    final bytes = File('assets/rooms.bin').readAsBytesSync();
    int start = -1, end = bytes.length;
    for (int i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0xA2) { start = i; break; }
    }
    for (int i = start + 1; i < bytes.length; i++) {
      if (bytes[i] >= 0xA0 && bytes[i] <= 0xBB) { end = i; break; }
    }
    final roomBytes = bytes.sublist(start, end);
    final roomData = AtariBytecodeParser.parseRoom(Uint8List.fromList(roomBytes), 2);

    // Render without limits
    final resultInf = AtariPixelRenderer.renderToPixelBuffer(roomData!);

    // Render incrementally command-by-command until complete
    Uint32List? iterBuf;
    int cmdIdx = 0;
    while (true) {
      final r = AtariPixelRenderer.renderToPixelBuffer(
        roomData,
        pixelBudget: 1, // allow one command at a time
        existingPixelBuffer: iterBuf,
        startCommandIndex: cmdIdx,
      );
      iterBuf = r.pixelBuffer;
      cmdIdx = r.lastCommandIndex + 1;
      if (r.isComplete) break;
    }

    // Compare
    int diffCount = 0;
    for (int i = 0; i < 160 * 96; i++) {
      if (resultInf.pixelBuffer[i] != iterBuf[i]) {
        diffCount++;
      }
    }

    // ignore: avoid_print
    print('Differences: $diffCount');
  });
}
