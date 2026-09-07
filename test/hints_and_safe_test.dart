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
          'PUSH TABLE': 'passage-return',
          'PULL CORD': 'cord-weight',
          'EXORCISE CLOAK': 'cloak-danger',
          '1327': 'safe-code',
        };
        if (milestones.containsKey(command)) {
          expect(current.id, milestones[command], reason: command);
        }
        expect(current.text, isNotEmpty, reason: command);
        final guidance = AdventureHints.variants(current);
        expect(guidance.toSet().length, guidance.length, reason: command);
        expect(
          guidance.any(
            (text) => text.startsWith('Consider what you already know:'),
          ),
          isFalse,
        );
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

  test('practical hints name the rat, stairs, and cellar prerequisites', () {
    final game = AdventureEngine();
    game.flags['matches_reached'] = true;
    expect(hint(game).id, 'KNIFE');
    expect(hint(game).text, contains('knife'));
    expect(hint(game).text, contains('rat'));
    game.locations['KNIFE'] = -1;
    expect(hint(game).id, 'BIBLE');
    expect(hint(game).text, contains('upstairs'));
    expect(hint(game).text, contains('study desk'));
    game.locations['BIBLE'] = -1;
    game.locations['KEY'] = -1;
    expect(hint(game).id, 'cellar-lock');
    expect(
      AdventureHints.variants(hint(game)).join(' '),
      contains('DROP CHEST'),
    );
    game.flags['door_unlocked'] = true;
    game.locations['KEY'] = 0;
    game.room = 5;
    expect(hint(game).id, 'cellar-prop');
    expect(hint(game).text, contains('Drop the chest in the dark corridor'));
    expect(hint(game).text, contains('broken latch'));
    expect(
      AdventureHints.variants(hint(game)).join(' '),
      isNot(contains('KICK CHEST')),
    );
  });

  test('dog hints give the complete coal, rag, and matches recipe', () {
    final game = AdventureEngine()..room = 19;
    game.flags['matches_reached'] = true;
    game.flags['door_unlocked'] = true;
    game.locations['LIT CANDLE'] = -1;
    game.locations['CANDLE'] = 0;
    game.locations['MATCHES'] = -1;
    expect(hint(game).id, 'COAL');
    final steps = AdventureHints.variants(hint(game));
    expect(steps.length, 3);
    expect(steps.first, contains('oily rag'));
    expect(steps[1], contains('matches'));
    expect(steps[2], contains('DROP COAL and DROP RAG, then LIGHT COAL'));
    game.room = 26;
    game.locations['COAL'] = 26;
    game.locations['RAG'] = 26;
    expect(hint(game).id, 'embers');
    game.execute('LIGHT COAL', {});
    expect(game.flag('dog_terrified'), isTrue);
    expect(hint(game).id, isNot(isIn(['COAL', 'RAG', 'embers', 'dog'])));
  });

  test('crucifix guidance uses silver bar, saw, and wire, not heavy iron', () {
    final game = AdventureEngine()..room = 25;
    for (final flag in [
      'matches_reached',
      'door_unlocked',
      'dog_terrified',
      'hatch_open',
    ]) {
      game.flags[flag] = true;
    }
    for (final item in ['LIT CANDLE', 'MATCHES', 'WIRE', 'SAW', 'BAR']) {
      game.locations[item] = -1;
    }
    game.locations['CANDLE'] = 0;
    expect(hint(game).id, 'cut-silver');
    expect(
      hint(game).text,
      contains('silver bar with the saw in the workshop'),
    );
    game.execute('CUT BAR', {});
    expect(hint(game).id, 'cross');
    expect(hint(game).text, contains('silver bar pieces and silver wire'));
    expect(
      AdventureHints.variants(hint(game)).last,
      contains('heavy iron is for the bedroom cord'),
    );
    game.execute('MAKE CROSS', {});
    expect(game.locations['CRUCIFIX'], 25);
  });

  test(
    'hint progression is finite, read-only, and refreshed by progress or reset',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = GameState();
      await game.initialize();
      final journal = List.of(game.outputMessages);
      final seen = <String>{};
      final count = AdventureHints.variants(game.nextHint).length;
      for (var i = 0; i < count; i++) {
        expect(game.hasMoreHints, isTrue);
        expect(seen.add(game.takeHint().text), isTrue);
      }
      expect(game.hasMoreHints, isFalse);
      expect(game.takeHint().id, 'hints-exhausted');
      expect(game.moveCount, 0);
      expect(game.outputMessages, journal);
      game.processCommand('W');
      game.processCommand('GET CHAIR');
      expect(game.nextHint.id, 'high-cupboard');
      expect(game.hasMoreHints, isTrue);
      expect(game.takeHint().id, 'high-cupboard');
      await game.reset();
      expect(game.hasMoreHints, isTrue);
      expect(game.takeHint().text, seen.first);
      expect(
        AdventureHints.variants(
          const AdventureHint('unlisted', 'One useful clue.'),
        ),
        ['One useful clue.'],
      );
      await game.saveState();
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

  testWidgets(
    'lightbulb opens practical guidance without a turn or fuel cost',
    (tester) async {
      final game = await mount(tester);
      final moves = game.moveCount;
      final fuel = game.candleLife;
      final journal = List.of(game.outputMessages);
      await tester.tap(find.byTooltip('A gentle hint'));
      await tester.pumpAndSettle();
      expect(find.text('Hints for your next step'), findsOneWidget);
      expect(find.textContaining('1327'), findsOneWidget);
      expect(game.moveCount, moves);
      expect(game.candleLife, fuel);
      expect(game.outputMessages, journal);
      await tester.tap(find.text('Keep exploring'));
      await tester.pumpAndSettle();
      await game.saveState();
    },
  );

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
