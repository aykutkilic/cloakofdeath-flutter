import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloak_of_death_flutter/game/adventure_engine.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'package:cloak_of_death_flutter/game/exploration_map.dart';
import 'package:cloak_of_death_flutter/models/game_data.dart';
import 'package:cloak_of_death_flutter/models/room.dart';
import 'package:cloak_of_death_flutter/widgets/exploration_map_dialog.dart';
import 'package:cloak_of_death_flutter/widgets/hint_button.dart';
import 'package:cloak_of_death_flutter/app_theme.dart';
import 'support/walkthrough.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const font = String.fromEnvironment('PREVIEW_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  '${File(font).parent.path}/MaterialIcons-Regular.otf',
                ).readAsBytesSync(),
              ),
            ),
          ))
          .load();
    }
  });
  Future<GameState> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final game = GameState();
    await game.initialize();
    return game;
  }

  Future<GameState> restoreWithMap(
    AdventureEngine engine,
    List<int> rooms,
  ) async {
    final knowledge = ExplorationMap()..visited.addAll(rooms);
    SharedPreferences.setMockInitialValues({
      'cloak_save_state': jsonEncode({
        ...engine.toJson(),
        'exploration': knowledge.toJson(),
      }),
    });
    final game = GameState();
    await game.initialize();
    return game;
  }

  test(
    'discovery persists and old saves never infer previously visited rooms',
    () async {
      final game = await fresh();
      expect(game.visitedRooms, {1});
      expect(game.mapRoomName(3), 'Unknown');
      expect(game.mapRoomContents(3), isEmpty);
      game.processCommand('W');
      game.processCommand('N');
      game.processCommand('GET KNIFE');
      expect(game.visitedRooms, {1, 2, 3});
      expect(game.mapRoomContents(3), isNot(contains('KNIFE')));
      game.processCommand('DROP KNIFE');
      expect(game.mapRoomContents(3), contains('KNIFE'));
      await game.saveState();
      final restored = GameState();
      await restored.initialize();
      expect(restored.visitedRooms, game.visitedRooms);
      expect(restored.exploredLinks.length, 2);
      SharedPreferences.setMockInitialValues({
        'cloak_save_state': jsonEncode((AdventureEngine()..room = 23).toJson()),
      });
      final legacy = GameState();
      await legacy.initialize();
      expect(legacy.visitedRooms, {23});
      expect(legacy.mapRoomName(23), 'Unlit room');
      expect(legacy.mapRoomContents(23), isEmpty);
      await game.reset();
      expect(game.visitedRooms, {1});
    },
  );

  test(
    'route preview is read-only and fast travel equals manual movement',
    () async {
      final game = await fresh();
      for (final command in ['W', 'N', 'GET KNIFE', 'S', 'E']) {
        game.processCommand(command);
      }
      final before = game.moveCount;
      final journal = List.of(game.outputMessages);
      expect(game.mapRoutes[3], ['W', 'N']);
      expect(game.mapRoutes.containsKey(7), isFalse);
      expect(game.moveCount, before);
      expect(game.outputMessages, journal);
      expect(game.travelToRoom(3), isTrue);
      expect(game.currentRoomId, 3);
      expect(game.moveCount, before + 2);
      expect(game.visitedRooms, {1, 2, 3});
      await game.saveState();
    },
  );

  test('routes obey stairs, rat, cellar trap and pending safe input', () async {
    final data = await GameData.loadFromAssets();
    final map = ExplorationMap()..visited.addAll(roomPositions.keys);
    final engine = AdventureEngine();
    engine.locations['CORRIDOR'] = 1;
    expect(map.routes(engine, data).containsKey(9), isFalse);
    expect(map.routes(engine, data).containsKey(5), isFalse);
    engine.locations['KNIFE'] = -1;
    engine.locations['BIBLE'] = -1;
    expect(map.routes(engine, data)[9], ['U']);
    expect(map.routes(engine, data)[5], ['GO CORRIDOR']);
    engine.room = 23;
    expect(map.routes(engine, data).containsKey(5), isFalse);
    engine.flags['door_propped'] = true;
    expect(map.routes(engine, data)[5], ['U']);
    engine.awaitingCombination = true;
    expect(map.routes(engine, data), isEmpty);
  });

  test(
    'travel preserves candle use, entry effects and discovered-room limits',
    () async {
      final engine = AdventureEngine()..room = 23;
      engine.locations['CANDLE'] = 0;
      engine.locations['LIT CANDLE'] = -1;
      engine.candleLife = 20;
      final knowledge = ExplorationMap()..visited.addAll([23, 24, 25]);
      SharedPreferences.setMockInitialValues({
        'cloak_save_state': jsonEncode({
          ...engine.toJson(),
          'exploration': knowledge.toJson(),
        }),
      });
      final game = GameState();
      await game.initialize();
      expect(game.travelToRoom(26), isFalse);
      expect(game.moveCount, 0);
      expect(game.travelToRoom(25), isTrue);
      expect(game.moveCount, 2);
      expect(game.candleLife, 18);
      expect(game.mapRoomContents(24), contains('HAMMER'));
      expect(game.mapRoomContents(25), contains('BAR'));
      await game.saveState();
      final restored = GameState();
      await restored.initialize();
      expect(restored.currentRoomId, 25);
      expect(restored.candleLife, 18);
      expect(restored.exploredLinks.length, 2);
    },
  );

  test(
    'route simulation respects entry side effects, candle and cloak death',
    () async {
      final data = await GameData.loadFromAssets();
      final map = ExplorationMap()..visited.addAll([14, 15, 16, 17, 19, 21]);
      final engine = AdventureEngine()..room = 16;
      engine.locations['PASSAGEWAY'] = 16;
      engine.locations['LIT CANDLE'] = -1;
      engine.locations['CANDLE'] = 0;
      engine.locations['BIBLE'] = -1;
      engine.locations['CRUCIFIX'] = -1;
      engine.flags['table_pushed'] = true;
      expect(map.routes(engine, data)[19], ['GO PASSAGEWAY', 'U']);
      engine.room = 17;
      engine.flags['table_pushed'] = false;
      expect(map.routes(engine, data).containsKey(16), isFalse);
      engine.room = 14;
      engine.cloakTurns = 2;
      expect(map.routes(engine, data).containsKey(15), isFalse);
      engine.cloakTurns = 0;
      expect(map.routes(engine, data)[15], ['E']);
      expect(engine.candleLife, AdventureEngine.candleBurnTurns);
    },
  );

  test(
    'map travel manages candle across light boundaries and saves exact turns',
    () async {
      final engine = AdventureEngine()..room = 14;
      engine.locations['CANDLE'] = -1;
      engine.locations['MATCHES'] = -1;
      engine.candleLife = 20;
      final game = await restoreWithMap(engine, [9, 14, 16]);
      final journal = List.of(game.outputMessages);
      expect(game.mapRoutes[16], ['LIGHT CANDLE', 'N']);
      expect(game.moveCount, 0);
      expect(game.candleLife, 20);
      expect(game.inventory, contains('CANDLE'));
      expect(game.outputMessages, journal);
      expect(game.travelToRoom(16), isTrue);
      expect(game.hasLitCandle, isTrue);
      expect(game.isRoomRevealed(16), isTrue);
      expect(game.candleLife, 18);
      expect(game.moveCount, 2);
      expect(game.mapRoutes[9], ['S', 'EXTINGUISH CANDLE', 'S']);
      expect(game.travelToRoom(9), isTrue);
      expect(game.hasLitCandle, isFalse);
      expect(game.candleLife, 17);
      expect(game.moveCount, 5);
      expect(game.mapRoutes[16], ['N', 'LIGHT CANDLE', 'N']);
      expect(game.travelToRoom(16), isTrue);
      expect(game.candleLife, 15);
      expect(game.moveCount, 8);
      await game.saveState();
      final restored = GameState();
      await restored.initialize();
      expect(restored.currentRoomId, 16);
      expect(restored.hasLitCandle, isTrue);
      expect(restored.candleLife, 15);
      expect(restored.moveCount, 8);

      final data = await GameData.loadFromAssets();
      for (final command in [
        'LIGHT CANDLE',
        'N',
        'S',
        'EXTINGUISH CANDLE',
        'S',
        'N',
        'LIGHT CANDLE',
        'N',
      ]) {
        engine.execute(command, data.getRoomById(engine.room)!.connections);
      }
      final saved =
          jsonDecode(
                (await SharedPreferences.getInstance()).getString(
                  'cloak_save_state',
                )!,
              )
              as Map<String, dynamic>;
      for (final entry in engine.toJson().entries) {
        expect(saved[entry.key], entry.value, reason: entry.key);
      }
    },
  );

  test(
    'bright travel snuffs before moving and never adjusts a remote candle',
    () async {
      final data = await GameData.loadFromAssets();
      final map = ExplorationMap()..visited.addAll([1, 2, 3]);
      final engine = AdventureEngine();
      engine.locations['CANDLE'] = 0;
      engine.locations['LIT CANDLE'] = -1;
      engine.candleLife = 1;
      final game = await restoreWithMap(engine, [1, 2, 3]);
      expect(game.mapRoutes[3], ['EXTINGUISH CANDLE', 'W', 'N']);
      expect(game.travelToRoom(3), isTrue);
      expect(game.candleLife, 1);
      expect(game.inventory, contains('CANDLE'));
      expect(game.moveCount, 3);
      await game.saveState();
      engine.locations['LIT CANDLE'] = 1;
      expect(map.routes(engine, data)[3], ['W', 'N']);
    },
  );

  test(
    'automatic lighting requires carried equipment and never refills fuel',
    () async {
      final data = await GameData.loadFromAssets();
      final map = ExplorationMap()..visited.addAll([14, 16]);
      final engine = AdventureEngine()..room = 14;
      engine.locations['CANDLE'] = -1;
      // Manual navigation in darkness is legal; missing equipment does not grant light.
      expect(map.routes(engine, data)[16], ['N']);
      engine.locations['MATCHES'] = -1;
      engine.locations['CANDLE'] = 14;
      expect(map.routes(engine, data)[16], ['N']);
      engine.locations['CANDLE'] = -1;
      engine.candleLife = 0;
      expect(map.routes(engine, data)[16], ['N']);
      engine.candleLife = 2;
      final game = await restoreWithMap(engine, [14, 16]);
      expect(game.mapRoutes[16], ['LIGHT CANDLE', 'N']);
      expect(game.travelToRoom(16), isTrue);
      expect(game.candleLife, 0);
      expect(game.hasLitCandle, isFalse);
      expect(game.isTooDarkToSee, isTrue);
      await game.saveState();
    },
  );

  test('candle actions respect haunted-room timing and terminal exit', () async {
    final data = await GameData.loadFromAssets();
    final map = ExplorationMap()..visited.addAll([14, 15, 17, 26, 27]);
    final engine = AdventureEngine()..room = 15;
    engine.locations['CANDLE'] = 0;
    engine.locations['LIT CANDLE'] = -1;
    engine.cloakTurns = 2;
    expect(map.routes(engine, data)[14], ['W', 'EXTINGUISH CANDLE']);
    engine.locations['LIT CANDLE'] = 0;
    engine.locations['CANDLE'] = -1;
    engine.locations['MATCHES'] = -1;
    engine.locations['PASSAGEWAY'] = 15;
    // A synthetic dark exit isolates the extra LIGHT turn in the haunted room.
    final hazardData = GameData(
      rooms: [
        ...data.rooms.where((room) => room.id != 15),
        Room(
          id: 15,
          name: 'Haunted',
          description: '',
          exits: ['N'],
          connections: {'N': 17},
        ),
      ],
    );
    expect(map.routes(engine, hazardData).containsKey(17), isFalse);
    engine.room = 26;
    engine.locations['CANDLE'] = 0;
    engine.locations['LIT CANDLE'] = -1;
    engine.locations['DOG'] = 0;
    engine.flags['gates_unlocked'] = true;
    final game = await restoreWithMap(engine, [26, 27]);
    expect(game.mapRoutes[27], ['EXTINGUISH CANDLE', 'E']);
    expect(game.travelToRoom(27), isTrue);
    expect(game.hasWon, isTrue);
    expect(game.hasLitCandle, isFalse);
    await game.saveState();
  });

  test('route cost includes candle actions, not just rooms crossed', () {
    final data = GameData(
      rooms: [
        for (final entry in <int, Map<String, int>>{
          1: {'N': 16, 'E': 2},
          16: {'E': 3},
          2: {'E': 4},
          4: {'E': 3},
          3: {},
        }.entries)
          Room(
            id: entry.key,
            name: '',
            description: '',
            exits: entry.value.keys.toList(),
            connections: entry.value,
          ),
      ],
    );
    final map = ExplorationMap()..visited.addAll([1, 2, 3, 4, 16]);
    final engine = AdventureEngine();
    engine.locations['CANDLE'] = -1;
    engine.locations['MATCHES'] = -1;
    // Two moves via darkness take four turns; three bright moves take three.
    expect(map.routes(engine, data)[3], ['E', 'E', 'E']);
  });

  test('all directional room relations agree with floor coordinates', () async {
    final data = await GameData.loadFromAssets();
    final engine = AdventureEngine();
    for (final room in data.rooms) {
      engine.room = room.id;
      engine.flags['table_pushed'] = true;
      final from = roomPositions[room.id]!;
      for (final edge in engine.exits(room.connections).entries) {
        final to = roomPositions[edge.value]!;
        switch (edge.key) {
          case 'N':
            expect(to.y, lessThan(from.y));
            expect(to.floor, from.floor);
          case 'S':
            expect(to.y, greaterThan(from.y));
            expect(to.floor, from.floor);
          case 'W':
            expect(to.x, lessThan(from.x));
            expect(to.floor, from.floor);
          case 'E':
            expect(to.x, greaterThan(from.x));
            expect(to.floor, from.floor);
          case 'U':
            expect(to.floor, greaterThan(from.floor));
            expect(to.x, from.x);
            expect(to.y, from.y);
          case 'D':
            expect(to.floor, lessThan(from.floor));
            expect(to.x, from.x);
            expect(to.y, from.y);
        }
      }
    }
    expect(
      roomPositions.values
          .map((p) => '${p.x},${p.y},${p.floor}')
          .toSet()
          .length,
      roomPositions.length,
    );
  });

  testWidgets(
    'hints advance without repeating across reopening and stop at exhaustion',
    (tester) async {
      final game = await fresh();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: const MaterialApp(home: Scaffold(body: HintButton())),
        ),
      );
      await tester.tap(find.byTooltip('A gentle hint'));
      await tester.pumpAndSettle();
      final primary = game.nextHint.text;
      expect(find.text(primary), findsOneWidget);
      await tester.tap(find.text('Another hint'));
      await tester.pumpAndSettle();
      expect(find.text(primary), findsNothing);
      final second = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Text),
            ),
          )
          .data!;
      await tester.tap(find.text('Keep exploring'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('A gentle hint'));
      await tester.pumpAndSettle();
      expect(find.text(primary), findsNothing);
      expect(find.text(second), findsNothing);
      expect(find.text('All hints shown'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'All hints shown'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Keep exploring'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('A gentle hint'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('You have seen all the guidance'),
        findsOneWidget,
      );
      expect(find.text(primary), findsNothing);
      expect(game.moveCount, 0);
      expect(game.candleLife, AdventureEngine.candleBurnTurns);
    },
  );

  testWidgets(
    'map hides unvisited rooms, shows hover contents, and travels on click',
    (tester) async {
      final game = await fresh();
      for (final command in ['W', 'N', 'S', 'E']) {
        game.processCommand(command);
      }
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: const MaterialApp(
            home: Scaffold(body: ExplorationMapButton()),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Exploration map'));
      await tester.pumpAndSettle();
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('3'), findsNothing);
      expect(find.textContaining('turns away'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('map-room-3'))),
        const Size(48, 48),
      );
      expect(find.text('Oak Panelled Study'), findsNothing);
      expect(find.text('Attic'), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await tester.tap(find.byTooltip('Fit floor'));
      await tester.pumpAndSettle();
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('map-room-3'))),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.textContaining('KNIFE'), findsWidgets);
      expect(find.textContaining('Kitchen\n'), findsOneWidget);
      final before = game.moveCount;
      await mouse.down(
        tester.getCenter(find.byKey(const ValueKey('map-room-3'))),
      );
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(game.currentRoomId, 3);
      expect(game.moveCount, before + 2);
      expect(find.byType(ExplorationMapDialog), findsNothing);
      await mouse.removePointer();
      await game.saveState();
    },
  );

  for (final hold in [false, true]) {
    testWidgets(
      'touch inspects first; ${hold ? 'long press' : 'double tap'} travels',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final game = await fresh();
        for (final command in ['W', 'N', 'S', 'E']) {
          game.processCommand(command);
        }
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: game,
            child: const MaterialApp(
              home: Scaffold(body: ExplorationMapButton()),
            ),
          ),
        );
        await tester.tap(find.byTooltip('Exploration map'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Fit floor'));
        await tester.pumpAndSettle();
        final room = find.byKey(const ValueKey('map-room-3'));
        final before = game.moveCount;
        await tester.tap(room);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.textContaining('Kitchen\n'), findsOneWidget);
        expect(find.textContaining('KNIFE'), findsOneWidget);
        expect(game.currentRoomId, 1);
        expect(game.moveCount, before);
        expect(find.byType(ExplorationMapDialog), findsOneWidget);
        if (hold) {
          await tester.longPress(room);
        } else {
          await tester.tap(room);
          await tester.pump(const Duration(milliseconds: 60));
          await tester.tap(room);
        }
        await tester.pumpAndSettle();
        expect(game.currentRoomId, 3);
        expect(game.moveCount, before + 2);
        expect(find.byType(ExplorationMapDialog), findsNothing);
        await game.saveState();
      },
    );
  }

  testWidgets('touch travel gestures cannot bypass a blocked stair route', (
    tester,
  ) async {
    final engine = AdventureEngine();
    final knowledge = ExplorationMap()
      ..visited.addAll([1, 9])
      ..revealed.addAll([1, 9]);
    SharedPreferences.setMockInitialValues({
      'cloak_save_state': jsonEncode({
        ...engine.toJson(),
        'exploration': knowledge.toJson(),
      }),
    });
    final game = GameState();
    await game.initialize();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: game,
        child: const MaterialApp(home: Scaffold(body: ExplorationMapButton())),
      ),
    );
    await tester.tap(find.byTooltip('Exploration map'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First floor').last);
    await tester.pumpAndSettle();
    final room = find.byKey(const ValueKey('map-room-9'));
    await tester.tap(room);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(room);
    await tester.pumpAndSettle();
    expect(find.textContaining('No traversable route'), findsOneWidget);
    await tester.longPress(room);
    await tester.pumpAndSettle();
    expect(game.currentRoomId, 1);
    expect(game.moveCount, 0);
    expect(find.byType(ExplorationMapDialog), findsOneWidget);
  });

  for (final size in [
    const Size(1280, 900),
    const Size(320, 568),
    const Size(844, 390),
  ]) {
    testWidgets('explored map fits $size with floor links', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = await fresh();
      for (final command in walkthroughCommands) {
        if (command == 'EXORCISE CLOAK') break;
        game.processCommand(command);
      }
      final capture = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: RepaintBoundary(
            key: capture,
            child: MaterialApp(
              theme: AppTheme.themeData,
              home: const Scaffold(body: ExplorationMapButton()),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Exploration map'));
      await tester.pumpAndSettle();
      expect(find.text('First floor'), findsOneWidget);
      expect(tester.takeException(), isNull);
      const preview = String.fromEnvironment('PREVIEW_DIR');
      Future<void> captureMap(String name) async {
        if (preview.isEmpty) return;
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(preview).create(recursive: true);
          await File(
            '$preview/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await captureMap('map-${size.width.toInt()}');
      if (size.width == 1280) {
        await tester.tap(find.byType(DropdownButton<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ground floor').last);
        await tester.pumpAndSettle();
        await captureMap('map-ground');
      }
      await game.saveState();
    });
  }
}
