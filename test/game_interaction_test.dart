import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloak_of_death_flutter/game/adventure_engine.dart';
import 'package:cloak_of_death_flutter/widgets/unified_minimap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'package:cloak_of_death_flutter/widgets/object_panel.dart';
import 'package:cloak_of_death_flutter/widgets/verb_panel.dart';
import 'support/walkthrough.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final propped in [true, false]) {
    testWidgets('dark cellar movement respects door prop: $propped', (
      tester,
    ) async {
      final engine = AdventureEngine()..room = 23;
      engine.flags['door_propped'] = propped;
      SharedPreferences.setMockInitialValues({
        'cloak_save_state': jsonEncode(engine.toJson()),
      });
      final game = GameState();
      await game.initialize();
      expect(game.isTooDarkToSee, isTrue);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: const MaterialApp(home: Scaffold(body: UnifiedMinimap())),
        ),
      );
      await tester.tap(find.text('U'));
      await tester.pumpAndSettle();
      expect(game.currentRoomId, propped ? 5 : 23);
      expect(game.moveCount, 1);
      if (!propped) {
        expect(game.outputMessages.last, contains('locked'));
        expect(game.darknessGuidance, contains('broken latch'));
      }
      await game.saveState();
    });
  }

  testWidgets('tap corridor action uses the same turn path as typed movement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameState();
    await game.initialize();
    for (final command in ['W', 'N', 'GET KNIFE', 'S', 'E', 'LOOK']) {
      game.processCommand(command);
    }
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(home: Scaffold(body: ObjectPanel())),
      ),
    );
    await tester.tap(find.text('CORRIDOR'));
    await tester.pumpAndSettle();
    expect(find.text('GO'), findsOneWidget);
    final before = game.moveCount;
    await tester.tap(find.text('GO'));
    await tester.pumpAndSettle();
    expect(game.currentRoomId, 5);
    expect(game.moveCount, before + 1);
    expect(tester.takeException(), isNull);
    await game.saveState();
  });

  testWidgets('exorcism is available and works from the cloak popup', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final game = GameState();
    await game.initialize();
    for (final command in walkthroughCommands) {
      if (command == 'EXORCISE CLOAK') break;
      game.processCommand(command);
    }
    expect(game.currentRoomId, 15);
    expect(game.isGameOver, isFalse);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(home: Scaffold(body: ObjectPanel())),
      ),
    );
    await tester.tap(find.text('CLOAK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXORCISE'));
    await tester.pumpAndSettle();
    expect(game.inventory, contains('GOBLET'));
    expect(game.inventory, isNot(contains('HOLY WATER')));
    game.processCommand('WAIT');
    game.processCommand('WAIT');
    expect(game.isGameOver, isFalse);
    expect(tester.takeException(), isNull);
    await game.saveState();
  });

  testWidgets(
    'wire menu can craft the crucifix without a nonexistent object target',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final game = GameState();
      await game.initialize();
      for (final command in walkthroughCommands) {
        if (command == 'MAKE CRUCIFIX') break;
        game.processCommand(command);
      }
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => VerbPanel.showVerbPopup(context, 'WIRE'),
                  child: const Text('WIRE'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('WIRE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MAKE'));
      await tester.pumpAndSettle();
      expect(game.getVisibleObjects(), contains('CRUCIFIX'));
      expect(game.inventory, isNot(contains('WIRE')));
      expect(tester.takeException(), isNull);
      await game.saveState();
    },
  );
}
