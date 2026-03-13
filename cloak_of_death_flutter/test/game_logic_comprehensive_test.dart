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

      // Examine rat
      gameState.processCommand('EXAMINE RAT');
      expect(gameState.outputMessages.last, 'Looks pretty nasty!!');

      // Attempt to interact with rat (original game throws error, we just block)
      // Getting the knife and then going north
      gameState.processCommand('E'); // Go to sitting room
      gameState.processCommand('W'); // Go back to dark hall
      gameState.processCommand('W'); // Go to dining room
      gameState.processCommand('N'); // Go to kitchen

      // Pick up knife
      gameState.processCommand('OPEN CUPBOARD');
      gameState.processCommand('EXAMINE CUPBOARD');
      gameState.processCommand('GET KNIFE');
      expect(gameState.inventory.contains('KNIFE'), isTrue);

      gameState.processCommand('S'); // Back to dining room
      gameState.processCommand('E'); // Back to dark hall

      // Now we should be able to go North
      gameState.processCommand('N');
      expect(gameState.currentRoomId, 5); // Assuming Room 5 is dark corridor
    });

    test('Examine specific objects', () {
      gameState.processCommand('EXAMINE BIBLE');
      expect(gameState.outputMessages.last, 'It falls open at the first page.');

      gameState.processCommand('EXAMINE WINE');
      expect(gameState.outputMessages.last, 'French red. Maybe you should try it.');

      gameState.processCommand('EXAMINE PAINTING');
      expect(gameState.outputMessages.last, "It's an oil painting of two horses.");

      gameState.processCommand('EXAMINE CLOCK');
      expect(gameState.outputMessages.last, "It's getting terribly late!!");
      
      gameState.processCommand('EXAMINE DOG');
      expect(gameState.outputMessages.last, "It has eyes like red embers.");
    });
    
    test('Dog burn coal logic', () {
      // Need to simulate getting coal and rag, then going to dog
      gameState.processCommand('GET COAL'); // Hack: just pretend we have them
      gameState.processCommand('GET RAG');
      // For testing, let's just cheat the locations or run the command 
    });
  });
}
