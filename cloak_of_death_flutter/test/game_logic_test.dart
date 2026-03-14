import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late GameState gameState;

  setUp(() async {
    gameState = GameState();
    await gameState.initialize();
  });

  test('Complete Walkthrough Test', () {
    // Walkthrough matching original Atari BASIC game flow.
    // Object locations verified against Atari screenshots.

    void exec(String cmd) {
      gameState.processCommand(cmd);
    }

    void expectInv(String item) {
      expect(
        gameState.inventory.contains(item),
        isTrue,
        reason: 'Expected $item in inventory',
      );
    }

    void expectNotInv(String item) {
      expect(
        gameState.inventory.contains(item),
        isFalse,
        reason: 'Expected $item NOT in inventory',
      );
    }

    void assertRoom(int id) {
      expect(gameState.currentRoomId, id, reason: 'Expected to be in room $id');
    }

    // === Phase 1: Kitchen — get KNIFE, open CUPBOARD for MATCHES ===
    assertRoom(1);
    exec('W');
    assertRoom(2); // Dining Room
    exec('GET CHAIR');
    expectInv('CHAIR');

    exec('N');
    assertRoom(3); // Kitchen — KNIFE, BREAD, SINK here; CUPBOARD hidden until LOOK
    exec('DROP CHAIR');
    exec('LOOK AROUND'); // Reveals CUPBOARD (BASIC line 1220)
    exec('OPEN CUPBOARD');
    exec('EXAMINE CUPBOARD');
    exec('CLIMB CHAIR');
    exec('GET MATCHES');
    exec('GET KNIFE');
    expectInv('MATCHES');
    expectInv('KNIFE');
    exec('EXAMINE SINK');

    // === Phase 2: Study — get BIBLE from DESK, Conservatory — get CHEST ===
    exec('S');
    assertRoom(2);
    exec('E');
    assertRoom(1);
    exec('E');
    assertRoom(8); // Sitting Room
    exec('EXAMINE FIREPLACE');
    exec('GET COAL');
    expectInv('COAL');

    exec('N');
    assertRoom(7); // Oak Panelled Study — DESK here (screenshot verified)
    exec('EXAMINE DESK');
    exec('GET BIBLE');
    exec('GET LETTER');
    expectInv('BIBLE');
    exec('READ LETTER');
    exec('DROP LETTER');

    exec('W');
    assertRoom(6); // Conservatory
    exec('GET CHEST');
    expectInv('CHEST');

    // === Phase 3: Corridors and Cellar ===
    exec('S');
    assertRoom(1);
    exec('LOOK AROUND'); // Reveals CORRIDOR (BASIC line 1210)
    exec('GO CORRIDOR');
    assertRoom(5); // Dark Corridor
    exec('DROP CHEST');
    exec('KICK CHEST');
    exec('EXAMINE CHEST');
    exec('GET KEY');
    expectInv('KEY');

    exec('UNLOCK DOOR');
    exec('W');
    assertRoom(4); // Pantry
    exec('GET CANDLE');
    expectInv('CANDLE');

    exec('E');
    assertRoom(5);
    exec('LIGHT CANDLE');
    expectInv('LIT CANDLE');

    exec('GO DOOR');
    assertRoom(20); // Cellar
    exec('GET WIRE');
    expectInv('WIRE');
    exec('GET IRON');
    expectInv('IRON');

    exec('E');
    assertRoom(24); // Underground Chamber
    exec('S');
    assertRoom(25); // Torture Chamber
    exec('GET RAG');
    expectInv('RAG');

    exec('N');
    assertRoom(24);
    exec('E');
    assertRoom(26); // Dark Passage
    exec('DROP COAL');
    exec('DROP RAG');
    exec('BURN COAL'); // Dog runs away

    exec('W');
    assertRoom(24);
    exec('GET HAMMER');
    expectInv('HAMMER');
    exec('GET SAW');
    expectInv('SAW');

    // === Phase 4: Make Crucifix at room 25 ===
    exec('S');
    assertRoom(25);
    exec('GET BAR');
    expectInv('BAR');
    exec('CUT BAR');
    expectInv('BAR PIECES');
    exec('MAKE CRUCIFIX');
    exec('GET CRUCIFIX');
    expectInv('CRUCIFIX');
    exec('DROP SAW');

    // === Phase 5: Back upstairs ===
    exec('N');
    assertRoom(24);
    exec('W');
    assertRoom(20);
    exec('U');
    assertRoom(5);
    exec('EXTINGUISH CANDLE');
    expectNotInv('LIT CANDLE');

    // === Phase 6: Upstairs — Library and Hatch ===
    exec('S');
    assertRoom(1);
    exec('U');
    assertRoom(14); // Icy Corridor
    exec('N');
    assertRoom(15); // Haunted Room
    exec('N');
    assertRoom(16); // Library
    exec('LIGHT CANDLE');
    exec('EXAMINE SHELVES');
    exec('PUSH BOOK');
    exec('GO PASSAGEWAY');
    assertRoom(17); // Secret Passageway

    exec('D');
    assertRoom(16); // Library
    exec('S');
    assertRoom(15);
    exec('S');
    assertRoom(14);
    exec('EXTINGUISH CANDLE');
    exec('D');
    assertRoom(1);

    // === Phase 7: Cellar — HATCH at room 21, get Wine ===
    exec('GO CORRIDOR');
    assertRoom(5);
    exec('LIGHT CANDLE');
    exec('GO DOOR');
    assertRoom(20);
    exec('W');
    assertRoom(21); // Wine Cellar / Pool Room — WINE, HATCH, TABLE here
    exec('REMOVE NAILS');
    exec('DROP HAMMER');
    exec('GET WINE');
    expectInv('WINE');

    exec('E');
    assertRoom(20);
    exec('U');
    assertRoom(5);
    exec('EXTINGUISH CANDLE');

    // === Phase 8: Get Goblet, set up safe ===
    exec('S');
    assertRoom(1);
    exec('DROP KNIFE');
    exec('U');
    assertRoom(14);
    exec('N');
    assertRoom(15);
    exec('GET PAINTING');
    expectInv('PAINTING');
    exec('W');
    assertRoom(12); // Annexe — GOBLET here
    exec('GET GOBLET');
    expectInv('GOBLET');

    exec('E');
    assertRoom(15);
    exec('E');
    assertRoom(13); // Master Bedroom
    exec('DROP PAINTING');
    exec('OPEN SAFE');
    exec('1327');
    exec('EXAMINE SAFE');
    exec('GET GATE KEY');
    expectInv('GATE KEY');

    // === Phase 9: Get water, make HOLY WATER ===
    exec('W');
    assertRoom(15);
    exec('S');
    assertRoom(14);
    exec('D');
    assertRoom(1);
    exec('W');
    assertRoom(2);
    exec('N');
    assertRoom(3); // Kitchen
    exec('GET WATER'); // GOBLET + BIBLE + CRUCIFIX → HOLY WATER
    expectInv('HOLY WATER');
    exec('GET BREAD');
    expectInv('BREAD');

    // === Phase 10: The Exorcism ===
    exec('S');
    assertRoom(2);
    exec('E');
    assertRoom(1);
    exec('U');
    assertRoom(14);
    exec('N');
    assertRoom(15); // Haunted Room — CLOAK here
    exec('LIGHT CANDLE');
    exec('DROP MATCHES');
    exec('EXORCISE CLOAK');
    exec('DROP BREAD');

    // === Phase 11: Escape ===
    exec('S');
    assertRoom(14);
    exec('EXTINGUISH CANDLE');
    exec('D');
    assertRoom(1);
    exec('GET KNIFE');
    exec('GO CORRIDOR');
    assertRoom(5);
    exec('GET MATCHES');
    exec('LIGHT CANDLE');
    exec('GO DOOR');
    assertRoom(20);
    exec('E');
    assertRoom(24);
    exec('E');
    assertRoom(26); // Dark Passage
    exec('UNLOCK GATES');
    exec('E'); // Escape!

    expect(gameState.outputMessages.join(" "), contains("CONGRATULATIONS"));
  });
}
