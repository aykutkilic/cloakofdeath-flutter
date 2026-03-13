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
    // We will verify the game logic can execute the exact walkthrough.

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

    // Sequence 1: Entrance, Dining, Kitchen
    assertRoom(1);
    exec('W');
    assertRoom(2); // Dining Room
    exec('GET CHAIR');
    expectInv('CHAIR');

    exec('N');
    assertRoom(3); // Kitchen
    exec('DROP CHAIR');
    exec('LOOK AROUND');
    exec('OPEN CUPBOARD');
    exec('EXAMINE CUPBOARD');
    exec('CLIMB CHAIR');
    exec('GET MATCHES');
    exec('GET KNIFE');
    expectInv('MATCHES');
    expectInv('KNIFE');
    exec('EXAMINE SINK');

    // Sequence 2: Sitting Room, Study, Conservatory
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
    assertRoom(7); // Oak Panelled Study
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

    // Sequence 3: Corridors and Cellar
    exec('S');
    assertRoom(1);
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
    exec('E');
    assertRoom(24); // Underground Chamber
    exec('S');
    assertRoom(25); // Torture Chamber
    exec('GET RAG');
    expectInv('RAG');

    exec('N');
    assertRoom(24);
    exec('E');
    assertRoom(26); // Dark Passage (Dog)
    exec('EXAMINE DOG');
    exec('DROP COAL');
    exec('DROP RAG');
    exec('BURN COAL'); // Dog runs away

    exec('W');
    assertRoom(24);
    exec('GET HAMMER');
    expectInv('HAMMER');

    exec('W');
    assertRoom(20);
    exec('U');
    assertRoom(5);
    exec('EXTINGUISH CANDLE');
    expectNotInv('LIT CANDLE');

    // Sequence 4: Upstairs
    exec('S');
    assertRoom(1);
    exec('U');
    assertRoom(14); // Icy Corridor
    exec('N');
    assertRoom(15); // Haunted Room? Wait, walkthrough says N, N
    exec('N');
    assertRoom(16); // Library
    exec('LIGHT CANDLE');
    exec('EXAMINE SHELVES');
    exec('PUSH BOOK');
    exec('GO PASSAGEWAY');
    assertRoom(17); // Secret Passageway

    exec('U');
    assertRoom(18); // Old Attic
    exec('E');
    assertRoom(19); // Tower (Pool Room?)
    exec('REMOVE NAILS');
    exec('DROP HAMMER');
    exec('GO HATCH');
    assertRoom(22); // Store room
    exec('GET WIRE');
    expectInv('WIRE');

    // Sequence 5: Cellar and Saw
    exec('S'); // Back from hatch to Tower?
    exec('PUSH TABLE');
    exec('W');
    exec('D');
    exec('S'); // 16 -> 15
    exec('S'); // 15 -> 14
    exec('EXTINGUISH CANDLE');
    exec('D'); // 14 -> 1
    exec('GO CORRIDOR');
    exec('GO DOOR');
    exec('LIGHT CANDLE');
    exec('E');
    exec('GET SAW');
    expectInv('SAW');

    // Sequence 6: Making the Crucifix
    exec('S');
    exec('DROP BIBLE');
    exec('GET BAR');
    exec('CUT BAR');
    exec('MAKE CRUCIFIX');
    exec('DROP SAW');
    exec('GET CRUCIFIX');
    exec('GET BIBLE');
    expectInv('CRUCIFIX');
    expectInv('BIBLE');

    // Sequence 7: Iron and Goblet
    exec('N');
    exec('W');
    exec('U');
    exec('EXTINGUISH CANDLE');
    exec('S');
    exec('DROP BIBLE');
    exec('DROP CRUCIFIX');
    exec('GO CORRIDOR');
    exec('LIGHT CANDLE');
    exec('DROP MATCHES');
    exec('GO DOOR');
    exec('GET IRON');
    expectInv('IRON');

    exec('U');
    exec('EXTINGUISH CANDLE');
    exec('S');
    exec('DROP KNIFE');
    exec('GET BIBLE');
    exec('U');
    exec('W');
    exec('PULL CORD');
    exec('DROP IRON');
    exec('E');
    exec('N');
    exec('W');
    exec('GO ANNEXE');
    exec('GET GOBLET');
    expectInv('GOBLET');

    // Sequence 8: Wine and Water
    exec('E');
    exec('E');
    exec('S');
    exec('D');
    exec('GET KNIFE');
    exec('DROP BIBLE');
    exec('GO CORR');
    exec('GET MATCHES');
    exec('GO DOOR');
    exec('LIGHT CANDLE');
    exec('W');
    exec('GET WINE');
    expectInv('WINE');

    exec('E');
    exec('U');
    exec('EXTINGUISH CANDLE');
    exec('S');
    exec('DROP KNIFE');
    exec('GET CRUCIFIX');
    exec('GET BIBLE');
    exec('U');
    exec('N');
    exec('DROP MATCHES');
    exec('DROP CANDLE'); // Dropping unlit candle
    exec('S');
    exec('D');
    exec('W');
    exec('N');
    exec(
      'GET WATER',
    ); // Automatically makes HOLY WATER if we have Bible and Crucifix
    exec('GET BREAD');
    expectInv('HOLY WATER');
    expectInv('BREAD');

    // Sequence 9: The Exorcism
    exec('S');
    exec('E');
    exec('U');
    exec('N');
    exec('GET CANDLE');
    exec('DROP BIBLE');
    exec('GET MATCHES');
    exec('LIGHT CANDLE');
    exec('DROP MATCHES');
    exec('GET BIBLE');
    // In Haunted Room (15)
    exec('EXORCISE CLOAK');
    exec('DROP BREAD');
    exec('E'); // Move to Master Bedroom (13) for Safe
    exec('GET PAINTING');
    exec('DROP PAINTING');
    exec('OPEN SAFE'); // 1327
    exec('1327');
    exec('EXAMINE SAFE');
    exec('GET KEY'); // Gets GATE KEY
    expectInv('GATE KEY');

    // Sequence 10: Escape
    exec('W');
    exec('EXTINGUISH CANDLE');
    exec('LEAVE WINE'); // DROP WINE
    exec('GET MATCHES');
    exec('S');
    exec('D');
    exec('GET KNIFE');
    exec('GO CORR');
    exec('GO DOOR');
    exec('LIGHT CANDLE');
    exec('E');
    exec('E'); // To Dark Passage
    exec('UNLOCK GATES'); // Uses GATE KEY
    exec('E'); // Escape!

    expect(gameState.outputMessages.join(" "), contains("CONGRATULATIONS"));
  });
}
