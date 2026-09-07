import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'support/walkthrough.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Complete original walkthrough without state injection or excess load',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameState();
      await game.initialize();
      for (final (index, command) in walkthroughCommands.indexed) {
        expect(
          game.isGameOver,
          isFalse,
          reason: 'Before step $index: $command',
        );
        game.processCommand(command);
        expect(game.inventoryLoad, lessThanOrEqualTo(6), reason: command);
        if (command.startsWith('GET ')) {
          final item = command.substring(4);
          if (item == 'KEY') {
            expect(
              game.inventory.any((i) => i == 'KEY' || i == 'GATE KEY'),
              isTrue,
              reason: 'Step $index: $command',
            );
          } else if (item == 'WATER') {
            expect(game.inventory, contains('HOLY WATER'));
          } else {
            expect(
              game.inventory,
              contains(item),
              reason: 'Step $index: $command',
            );
          }
        }
        if (command == 'UNLOCK GATES') {
          expect(game.hasWon, isFalse);
          expect(game.currentRoomId, 26);
        }
      }
      expect(game.currentRoomId, 27);
      expect(game.hasWon, isTrue);
      expect(game.candleLife, greaterThan(0));
      expect(
        game.moveCount,
        walkthroughCommands.length - 1,
      ); // Safe prompt + input = one turn.
      expect(game.outputMessages.join(' '), contains('CONGRATULATIONS'));
      await game.saveState();
      final restored = GameState();
      await restored.initialize();
      expect(restored.hasWon, isTrue);
      expect(restored.candleLife, game.candleLife);
      expect(restored.inventory, game.inventory);
      final moves = restored.moveCount;
      restored.processCommand('W');
      expect(restored.moveCount, moves);
      await restored.reset();
      expect(restored.isGameOver, isFalse);
      expect(restored.currentRoomId, 1);
      expect(restored.inventory, isEmpty);
    },
  );
}
