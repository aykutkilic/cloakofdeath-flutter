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
    // Walkthrough matching original Atari BASIC game flow with corrected room
    // connections derived from the E$ exit table in the cassette data.
    // Room layout: 1-8 ground floor, 9 upstairs hallway, 10-16 upstairs,
    // 17 secret passageway, 18-19 attic, 20-21 upper cellar, 22-26 lower cellar.

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

    // === Phase 3: Corridors — get KEY, CANDLE, open cellar door ===
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

    // === Phase 4: First cellar trip — get RAG, burn coal, get HAMMER ===
    exec('GO DOOR');
    assertRoom(23); // Cold Damp Cellar (BASIC K=35 → room 23)

    exec('E');
    assertRoom(24); // Old Garage
    exec('S');
    assertRoom(25); // Dirty Workshop
    exec('GET RAG');
    expectInv('RAG');

    exec('N');
    assertRoom(24);
    exec('E');
    assertRoom(26); // Long Dark Tunnel
    exec('DROP COAL');
    exec('DROP RAG');
    exec('BURN COAL'); // Dog runs away

    exec('W');
    assertRoom(24);
    exec('GET HAMMER');
    expectInv('HAMMER');

    // === Phase 5: Return upstairs ===
    exec('W');
    assertRoom(23);
    exec('U');
    assertRoom(5);
    exec('EXTINGUISH CANDLE');
    expectNotInv('LIT CANDLE');

    // === Phase 6: Upstairs — Library, Secret Passageway, Pool Room, get WIRE ===
    exec('S');
    assertRoom(1);
    exec('U');
    assertRoom(9); // Upstairs Hallway (BASIC K=5, needs BIBLE)
    exec('N');
    assertRoom(14); // Icy Corridor
    exec('N');
    assertRoom(16); // Library
    exec('LIGHT CANDLE');
    exec('EXAMINE SHELVES');
    exec('PUSH BOOK');
    exec('GO PASSAGEWAY');
    assertRoom(17); // Secret Passageway

    exec('U');
    assertRoom(19); // Creaky Attic
    exec('E');
    assertRoom(21); // Pool Room — HATCH, TABLE here
    exec('REMOVE NAILS');
    exec('DROP HAMMER');
    exec('GO HATCH');
    assertRoom(20); // Store Room — WIRE here
    exec('GET WIRE');
    expectInv('WIRE');

    exec('S');
    assertRoom(21);
    exec('W');
    assertRoom(19);
    exec('D');
    assertRoom(17);
    exec('D');
    assertRoom(16); // Library
    exec('S');
    assertRoom(14);
    exec('S');
    assertRoom(9);
    exec('EXTINGUISH CANDLE');
    exec('D');
    assertRoom(1);

    // === Phase 7: Second cellar trip — get SAW, make CRUCIFIX ===
    exec('GO CORRIDOR');
    assertRoom(5);
    exec('LIGHT CANDLE');
    exec('GO DOOR');
    assertRoom(23);

    exec('E');
    assertRoom(24);
    exec('GET SAW');
    expectInv('SAW');

    exec('S');
    assertRoom(25); // Dirty Workshop
    exec('GET BAR');
    expectInv('BAR');
    exec('CUT BAR');
    expectInv('BAR PIECES');
    exec('MAKE CRUCIFIX');
    exec('GET CRUCIFIX');
    expectInv('CRUCIFIX');
    exec('DROP SAW');

    exec('N');
    assertRoom(24);
    exec('W');
    assertRoom(23);
    exec('U');
    assertRoom(5);
    exec('EXTINGUISH CANDLE');

    // === Phase 8: Get IRON, cord/annexe puzzle, get GOBLET ===
    exec('S');
    assertRoom(1);
    exec('DROP BIBLE');
    exec('DROP CRUCIFIX');
    exec('GO CORRIDOR');
    assertRoom(5);
    exec('LIGHT CANDLE');
    exec('DROP MATCHES');
    exec('GO DOOR');
    assertRoom(23);
    exec('GET IRON'); // IRON at room 23; triggers CORD=10, ANNEXE=0
    expectInv('IRON');

    exec('U');
    assertRoom(5);
    exec('EXTINGUISH CANDLE');
    exec('S');
    assertRoom(1);
    exec('DROP KNIFE');
    exec('GET BIBLE'); // Dropped at room 1
    exec('U');
    assertRoom(9);
    exec('W');
    assertRoom(10); // Guest Bedroom
    exec('PULL CORD'); // F7=1
    exec('DROP IRON'); // At room 10 with cord pulled → ANNEXE=13
    exec('E');
    assertRoom(9);
    exec('N');
    assertRoom(14);
    exec('W');
    assertRoom(13); // Master Bedroom — ANNEXE now visible here
    exec('GO ANNEXE');
    assertRoom(12); // Annexe — GOBLET here
    exec('GET GOBLET');
    expectInv('GOBLET');

    exec('E');
    assertRoom(13);
    exec('E');
    assertRoom(14);
    exec('S');
    assertRoom(9);
    exec('D');
    assertRoom(1);

    // === Phase 9: Get WINE from Wine Cellar ===
    exec('GET KNIFE'); // Dropped at room 1 earlier
    exec('DROP BIBLE');
    exec('GO CORRIDOR');
    assertRoom(5);
    exec('GET MATCHES'); // Dropped at room 5 earlier
    exec('GO DOOR');
    assertRoom(23);
    exec('LIGHT CANDLE');
    exec('W');
    assertRoom(22); // Wine Cellar
    exec('GET WINE');
    expectInv('WINE');

    exec('E');
    assertRoom(23);
    exec('U');
    assertRoom(5);
    exec('EXTINGUISH CANDLE');

    // === Phase 10: Get HOLY WATER from kitchen ===
    exec('S');
    assertRoom(1);
    exec('DROP KNIFE');
    exec('GET CRUCIFIX'); // Dropped at room 1
    exec('GET BIBLE'); // Dropped at room 1

    exec('W');
    assertRoom(2);
    exec('N');
    assertRoom(3); // Kitchen
    exec('GET WATER'); // GOBLET + BIBLE + CRUCIFIX → HOLY WATER
    expectInv('HOLY WATER');
    exec('GET BREAD');
    expectInv('BREAD');

    // === Phase 11: The Exorcism ===
    exec('S');
    assertRoom(2);
    exec('E');
    assertRoom(1);
    exec('U');
    assertRoom(9);
    exec('N');
    assertRoom(14); // Icy Corridor
    exec('E'); // Conditional: have BIBLE + CRUCIFIX → room 15
    assertRoom(15); // Haunted Room — CLOAK here
    exec('LIGHT CANDLE');
    exec('DROP MATCHES');
    exec('EXORCISE CLOAK');
    exec('DROP BREAD');

    // === Phase 12: Open safe at room 15, get GATE KEY ===
    exec('GET PAINTING');
    expectInv('PAINTING');
    exec('DROP PAINTING'); // Reveals SAFE at room 15
    exec('OPEN SAFE');
    exec('1327');
    exec('EXAMINE SAFE');
    exec('GET GATE KEY');
    expectInv('GATE KEY');

    // === Phase 13: Escape ===
    exec('W');
    assertRoom(14);
    exec('EXTINGUISH CANDLE');
    exec('S');
    assertRoom(9);
    exec('D');
    assertRoom(1);
    exec('GET KNIFE');
    exec('GO CORRIDOR');
    assertRoom(5);
    exec('GET MATCHES');
    exec('LIGHT CANDLE');
    exec('GO DOOR');
    assertRoom(23);
    exec('E');
    assertRoom(24);
    exec('E');
    assertRoom(26); // Long Dark Tunnel
    exec('UNLOCK GATES');
    exec('E'); // Escape!

    expect(gameState.outputMessages.join(" "), contains("CONGRATULATIONS"));
  });
}
