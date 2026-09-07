import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloak_of_death_flutter/game/adventure_engine.dart';
import 'package:cloak_of_death_flutter/game/adventure_hints.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'package:cloak_of_death_flutter/main.dart';
import 'package:cloak_of_death_flutter/models/game_data.dart';
import 'package:cloak_of_death_flutter/widgets/unified_minimap.dart';
import 'support/walkthrough.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AdventureHint hint(AdventureEngine game) =>
      AdventureHints.next(game, (id) => 'room $id');

  test(
    'hints are read-only and restore identically throughout the solution',
    () async {
      final data = await GameData.loadFromAssets();
      final game = AdventureEngine();
      for (final command in walkthroughCommands) {
        final before = jsonEncode(game.toJson());
        final current = hint(game);
        const milestones = {
          'REMOVE NAILS': 'hatch',
          'MAKE CRUCIFIX': 'cross',
          'PULL CORD': 'cord-weight',
          'EXORCISE CLOAK': 'cloak-danger',
          '1327': 'safe-code',
        };
        if (milestones.containsKey(command)) {
          expect(current.id, milestones[command], reason: command);
        }
        expect(current.text, isNotEmpty, reason: command);
        expect(jsonEncode(game.toJson()), before, reason: command);
        expect(
          hint(AdventureEngine.fromJson(jsonDecode(before))).text,
          current.text,
        );
        game.execute(command, data.getRoomById(game.room)!.connections);
      }
      expect(game.outcome, 'won');
      expect(hint(game).id, 'ending');
    },
  );

  test(
    'hazards and pending safe input take priority over unfinished puzzles',
    () {
      final game = AdventureEngine()..room = 15;
      expect(hint(game).id, 'cloak-danger');
      game.awaitingCombination = true;
      expect(hint(game).text, contains('1327'));
      game.awaitingCombination = false;
      game.room = 23;
      expect(hint(game).id, 'darkness-equipment');
      game.locations['CANDLE'] = -1;
      game.locations['MATCHES'] = -1;
      expect(hint(game).id, 'darkness');
    },
  );

  test(
    'out-of-order completion and dropped gate key guide the remaining task',
    () {
      final game = AdventureEngine()..room = 1;
      game.flags['cloak_exorcised'] = true;
      game.flags['gate_key_found'] = true;
      game.locations['GATE KEY'] = 7;
      expect(hint(game).id, 'GATE KEY');
      expect(hint(game).text, contains('room 7'));
      game.locations['GATE KEY'] = -1;
      game.flags['dog_terrified'] = true;
      expect(hint(game).id, 'gate');
      game.flags['gates_unlocked'] = true;
      expect(hint(game).id, 'escape');
    },
  );

  test(
    'iron stage does not demand dropped relics needed for carrying space',
    () {
      final game = AdventureEngine();
      for (final flag in [
        'matches_reached',
        'door_unlocked',
        'dog_terrified',
      ]) {
        game.flags[flag] = true;
      }
      game.locations['CANDLE'] = -1;
      game.locations['MATCHES'] = -1;
      game.locations['CRUCIFIX'] = 1;
      game.locations['BIBLE'] = 1;
      expect(hint(game).id, 'IRON');
      game.locations['IRON'] = -1;
      game.room = 10;
      expect(hint(game).id, 'cord-weight');
    },
  );

  Future<GameState> mount(WidgetTester tester, {bool pending = false}) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameState();
    await game.initialize();
    game.setAutoAnimateRooms(false);
    for (final command in walkthroughCommands) {
      if (command == 'OPEN SAFE') break;
      game.processCommand(command);
    }
    if (pending) {
      game.processCommand('OPEN SAFE');
      await game.saveState();
      final restored = GameState();
      await restored.initialize();
      restored.setAutoAnimateRooms(false);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: restored,
          child: const CloakOfDeathApp(),
        ),
      );
      await tester.pumpAndSettle();
      return restored;
    }
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: game, child: const CloakOfDeathApp()),
    );
    await tester.pumpAndSettle();
    return game;
  }

  testWidgets('lightbulb opens an indirect hint without a turn or fuel cost', (
    tester,
  ) async {
    final game = await mount(tester);
    final moves = game.moveCount;
    final fuel = game.candleLife;
    final journal = List.of(game.outputMessages);
    await tester.tap(find.byTooltip('A gentle hint'));
    await tester.pumpAndSettle();
    expect(find.text('A thought to follow'), findsOneWidget);
    expect(find.textContaining('1327'), findsOneWidget);
    expect(game.moveCount, moves);
    expect(game.candleLife, fuel);
    expect(game.outputMessages, journal);
    await tester.tap(find.text('Keep exploring'));
    await tester.pumpAndSettle();
    await game.saveState();
  });

  for (final correct in [true, false]) {
    testWidgets('typed OPEN SAFE uses keypad and engine outcome: $correct', (
      tester,
    ) async {
      final game = await mount(tester);
      final moves = game.moveCount;
      await tester.enterText(
        find.byKey(const ValueKey('command-input')),
        'OPEN SAFE',
      );
      await tester.tap(find.byTooltip('Send command'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('safe-combination')), findsOneWidget);
      expect(game.moveCount, moves);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Try combination'),
            )
            .onPressed,
        isNull,
      );
      for (final digit in (correct ? '1327' : '1234').split('')) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.tap(find.text('Try combination'));
      await tester.pumpAndSettle();
      expect(game.awaitingCombination, isFalse);
      expect(game.moveCount, moves + 1);
      expect(game.isGameOver, !correct);
      expect(find.byKey(const ValueKey('safe-combination')), findsNothing);
      if (correct) {
        game.processCommand('EXAMINE SAFE');
        expect(game.getVisibleObjects(), contains('GATE KEY'));
      }
      expect(tester.takeException(), isNull);
      await game.saveState();
    });
  }

  testWidgets('restored pending safe supports keyboard editing and hints', (
    tester,
  ) async {
    final game = await mount(tester, pending: true);
    expect(game.awaitingCombination, isTrue);
    final moves = game.moveCount;
    for (final key in [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit8,
    ]) {
      await tester.sendKeyEvent(key, character: key.keyLabel);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7, character: '7');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('safe-combination')),
        matching: find.byTooltip('A gentle hint'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1327'), findsOneWidget);
    expect(game.moveCount, moves);
    await tester.tap(find.text('Keep exploring'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try combination'));
    await tester.pumpAndSettle();
    expect(game.isGameOver, isFalse);
    expect(game.awaitingCombination, isFalse);
    expect(game.moveCount, moves + 1);
    await game.saveState();
  });

  testWidgets(
    'safe object popup opens keypad; clear and length limit are local',
    (tester) async {
      final game = await mount(tester);
      final moves = game.moveCount;
      await tester.tap(find.widgetWithText(OutlinedButton, 'SAFE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(game.awaitingCombination, isTrue);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.widgetWithText(OutlinedButton, '1'));
        await tester.pump();
      }
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Try combination'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'C'));
      await tester.pump();
      expect(game.moveCount, moves);
      expect(game.isGameOver, isFalse);
      for (final digit in '1327'.split('')) {
        await tester.tap(find.widgetWithText(OutlinedButton, digit));
        await tester.pump();
      }
      await tester.tap(find.text('Try combination'));
      await tester.pumpAndSettle();
      expect(game.isGameOver, isFalse);
      expect(game.moveCount, moves + 1);
      await game.saveState();
    },
  );

  testWidgets('west is before east and still moves west', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameState();
    await game.initialize();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 128, child: UnifiedMinimap(vertical: true)),
          ),
        ),
      ),
    );
    expect(
      tester.getCenter(find.text('W')).dx,
      lessThan(tester.getCenter(find.text('E')).dx),
    );
    await tester.tap(find.text('W'));
    await tester.pumpAndSettle();
    expect(game.currentRoomId, 2);
    await game.saveState();
  });
}
