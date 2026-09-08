import 'dart:convert';

import 'package:cloak_of_death_flutter/app_theme.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'package:cloak_of_death_flutter/widgets/save_game_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/walkthrough.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameState> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final game = GameState();
    await game.initialize();
    return game;
  }

  test(
    'eight independent checkpoints survive reset and application restart',
    () async {
      final game = await fresh();
      expect(game.saveSlots.length, 8);
      for (var i = 1; i <= 8; i++) {
        game.processCommand(i.isOdd ? 'W' : 'E');
        await game.saveToSlot(i);
      }
      await game.reset();
      final restarted = GameState();
      await restarted.initialize();
      expect(restarted.moveCount, 0);
      expect(restarted.saveSlots.every((slot) => slot.canLoad), isTrue);
      for (var i = 1; i <= 8; i++) {
        await restarted.loadFromSlot(i);
        expect(restarted.moveCount, i);
        expect(restarted.currentRoomId, i.isOdd ? 2 : 1);
      }
      final resumed = GameState();
      await resumed.initialize();
      expect(resumed.moveCount, 8);
      expect(resumed.currentRoomId, 1);
      expect(() => game.saveToSlot(0), throwsRangeError);
      expect(() => game.loadFromSlot(9), throwsRangeError);
    },
  );

  test(
    'checkpoint restores full puzzle, candle, journal and map state',
    () async {
      final game = await fresh();
      for (final command in walkthroughCommands) {
        if (command == '1327') break;
        game.processCommand(command);
      }
      expect(game.awaitingCombination, isTrue);
      await game.saveToSlot(1);
      final snapshot = game.saveSlots.first.data;
      game.selectObject('BIBLE');
      game.takeHint();
      game.processCommand('1327');
      await game.loadFromSlot(1);
      expect(game.selectedObject, isNull);
      expect(game.awaitingCombination, isTrue);
      expect(game.hasMoreHints, isTrue);
      await game.saveState();
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('cloak_save_state')!), snapshot);
      game.processCommand('1327');
      expect(game.awaitingCombination, isFalse);
      await game.saveState();
    },
  );

  test(
    'queued autosaves cannot overwrite a subsequently loaded checkpoint',
    () async {
      final game = await fresh();
      final saved = game.saveToSlot(1);
      game.processCommand('W');
      game.processCommand('N');
      final loaded = game.loadFromSlot(1);
      await Future.wait([saved, loaded]);
      expect(game.currentRoomId, 1);
      expect(game.moveCount, 0);
      final resumed = GameState();
      await resumed.initialize();
      expect(resumed.currentRoomId, 1);
      expect(resumed.moveCount, 0);
    },
  );

  test(
    'damaged and unsupported slots do not replace the active journey',
    () async {
      SharedPreferences.setMockInitialValues({
        'cloak_save_slot_1': '{broken',
        'cloak_save_slot_2': jsonEncode({'version': 9}),
        'cloak_save_slot_3': jsonEncode({
          'version': 1,
          'savedAt': DateTime.now().toIso8601String(),
          'state': {},
        }),
      });
      final game = GameState();
      await game.initialize();
      game.processCommand('W');
      await game.saveState();
      final prefs = await SharedPreferences.getInstance();
      final original = prefs.getString('cloak_save_state');
      for (var i = 1; i <= 3; i++) {
        expect(game.saveSlots[i - 1].unreadable, isTrue);
        await expectLater(game.loadFromSlot(i), throwsStateError);
        expect(game.currentRoomId, 2);
        expect(prefs.getString('cloak_save_state'), original);
      }
      await expectLater(game.loadFromSlot(4), throwsStateError);
      await game.saveToSlot(1);
      expect(game.saveSlots.first.canLoad, isTrue);
      await game.loadFromSlot(1);
    },
  );

  testWidgets(
    'slot UI saves, cancels overwrite, loads, and reaches slot eight',
    (tester) async {
      final game = await fresh();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: MaterialApp(
            theme: AppTheme.themeData,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const SaveGameDialog(),
                  ),
                  child: const Text('Open saves'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open saves'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('load-1')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('save-1')));
      await tester.pumpAndSettle();
      expect(find.text('Saved to slot 1.'), findsOneWidget);
      final firstSnapshot = game.saveSlots.first.snapshot;
      game.processCommand('W');
      await tester.tap(find.byKey(const ValueKey('save-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(game.saveSlots.first.snapshot, firstSnapshot);
      await tester.tap(find.byKey(const ValueKey('load-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load game'));
      await tester.pumpAndSettle();
      expect(game.currentRoomId, 1);
      expect(find.byType(SaveGameDialog), findsNothing);
      await tester.tap(find.text('Open saves'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-8')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('save-8')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-8')));
      await tester.pumpAndSettle();
      expect(game.saveSlots.last.canLoad, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
