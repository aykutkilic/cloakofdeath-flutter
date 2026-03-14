import 'package:flutter_test/flutter_test.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'package:cloak_of_death_flutter/rendering/room_bytecode_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RoomBytecodeLoader.initialize();
  });

  group('Comprehensive Game Logic Tests', () {
    late GameState gameState;

    setUp(() async {
      gameState = GameState();
      await gameState.initialize();
    });

    test('Initial rat logic in dark hall', () {
      // Room 1 (Dark Hall)
      expect(gameState.currentRoomId, 1);

      // Moving North should be blocked by the rat initially
      gameState.processCommand('N');
      expect(gameState.outputMessages.last, 'What about the rat?');
      expect(gameState.currentRoomId, 1); // Still in room 1

      // Examine rat (RAT is at room 1)
      gameState.processCommand('EXAMINE RAT');
      expect(gameState.outputMessages.last, 'Looks pretty nasty!!');

      // Get KNIFE from kitchen (already visible at room 3)
      gameState.processCommand('W'); // Go to dining room
      gameState.processCommand('N'); // Go to kitchen

      // KNIFE is already visible at room 3 (P(21)=3)
      gameState.processCommand('GET KNIFE');
      expect(gameState.inventory.contains('KNIFE'), isTrue);

      gameState.processCommand('S'); // Back to dining room
      gameState.processCommand('E'); // Back to dark hall

      // Now we should be able to go North with KNIFE
      gameState.processCommand('N');
      expect(gameState.currentRoomId, 5); // Room 5 is dark corridor
    });

    test('Examine objects requires presence', () {
      // EXAMINE objects not in room should fail with presence check
      gameState.processCommand('EXAMINE BIBLE');
      // BIBLE is hidden (P(4)=0), not in room 1
      expect(gameState.outputMessages.last, "I don't see it here.");

      // EXAMINE RAT at room 1 (RAT is here)
      gameState.processCommand('EXAMINE RAT');
      expect(gameState.outputMessages.last, 'Looks pretty nasty!!');

      // EXAMINE CLOCK at room 8
      gameState.processCommand('E'); // →8
      gameState.processCommand('EXAMINE CLOCK');
      expect(gameState.outputMessages.last, "It's getting terribly late!!");

      // EXAMINE FIREPLACE at room 8
      gameState.processCommand('EXAMINE FIREPLACE');
      expect(gameState.outputMessages.last, 'I can see something!');
    });

    test('CUPBOARD is at room 3 (kitchen), DESK at room 7 (study)', () {
      // Go to kitchen (room 3)
      gameState.processCommand('W'); // →2
      gameState.processCommand('N'); // →3

      // CUPBOARD is hidden until LOOK AROUND (BASIC line 1220)
      expect(gameState.getVisibleObjects().contains('CUPBOARD'), isFalse);
      gameState.processCommand('LOOK AROUND'); // Reveals CUPBOARD
      expect(gameState.getVisibleObjects().contains('CUPBOARD'), isTrue);

      // OPEN CUPBOARD at room 3 should succeed
      gameState.processCommand('OPEN CUPBOARD');
      expect(gameState.outputMessages.last, 'Ok');

      // EXAMINE CUPBOARD reveals MATCHES
      gameState.processCommand('EXAMINE CUPBOARD');
      expect(gameState.outputMessages.last, 'I can see something!');
      expect(gameState.getVisibleObjects().contains('MATCHES'), isTrue);

      // Go to study (room 7)
      gameState.processCommand('S'); // →2
      gameState.processCommand('E'); // →1
      gameState.processCommand('E'); // →8
      gameState.processCommand('N'); // →7

      // DESK should be visible at room 7 (per Atari screenshot)
      expect(gameState.getVisibleObjects().contains('DESK'), isTrue);

      // EXAMINE DESK reveals BIBLE
      gameState.processCommand('EXAMINE DESK');
      expect(gameState.outputMessages.last, 'I can see something!');
      expect(gameState.getVisibleObjects().contains('BIBLE'), isTrue);
    });

    test('Dog at room 5 does not block east from room 26', () {
      // DOG starts at room 5 (P(38)=5), should not block east from room 26
      // (only blocks if dog is AT room 26)
      // This tests that the original game logic is correctly implemented

      // Quick path to room 26: need knife, key, candle, matches
      gameState.processCommand('W'); // →2
      gameState.processCommand('N'); // →3
      gameState.processCommand('LOOK AROUND'); // Reveals CUPBOARD
      gameState.processCommand('GET KNIFE');
      gameState.processCommand('OPEN CUPBOARD');
      gameState.processCommand('EXAMINE CUPBOARD'); // Reveals MATCHES
      gameState.processCommand('GET MATCHES');
      gameState.processCommand('S'); // →2
      gameState.processCommand('E'); // →1
      gameState.processCommand('E'); // →8
      gameState.processCommand('N'); // →7
      gameState.processCommand('W'); // →6
      gameState.processCommand('GET CHEST');
      gameState.processCommand('S'); // →1
      gameState.processCommand('LOOK AROUND'); // Reveals CORRIDOR
      gameState.processCommand('GO CORRIDOR'); // →5
      gameState.processCommand('DROP CHEST');
      gameState.processCommand('KICK CHEST');
      gameState.processCommand('EXAMINE CHEST');
      gameState.processCommand('GET KEY');
      gameState.processCommand('UNLOCK DOOR');
      gameState.processCommand('W'); // →4
      gameState.processCommand('GET CANDLE');
      gameState.processCommand('E'); // →5
      gameState.processCommand('LIGHT CANDLE');
      gameState.processCommand('GO DOOR'); // →20
      gameState.processCommand('E'); // →24
      gameState.processCommand('E'); // →26
      expect(gameState.currentRoomId, 26);

      // East from 26 should be blocked by LOCKED GATES (not dog)
      gameState.processCommand('E');
      expect(gameState.outputMessages.last, 'The gates are locked.');
    });
  });
}
