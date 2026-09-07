import 'dart:io';
import 'dart:convert';
import 'package:cloak_of_death_flutter/game/adventure_engine.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'package:cloak_of_death_flutter/main.dart';
import 'package:cloak_of_death_flutter/rendering/room_bytecode_loader.dart';
import 'package:cloak_of_death_flutter/rendering/atari_render_controller.dart';
import 'package:cloak_of_death_flutter/rendering/atari_pixel_renderer.dart';
import 'package:cloak_of_death_flutter/rendering/atari_bytecode_parser.dart';
import 'support/walkthrough.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RoomBytecodeLoader.initialize();
    await (FontLoader(
      'Atari',
    )..addFont(rootBundle.load('assets/fonts/Atari-Regular.ttf'))).load();
    const font = String.fromEnvironment('PREVIEW_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
      final icons = File('${File(font).parent.path}/MaterialIcons-Regular.otf');
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(ByteData.sublistView(icons.readAsBytesSync())),
          ))
          .load();
    }
  });

  for (final variant in <(String, Size, double, double)>[
    ('desktop', const Size(1280, 900), 0, 1),
    ('phone', const Size(390, 844), 0, 1),
    ('small-phone', const Size(320, 568), 0, 1),
    ('landscape', const Size(844, 390), 0, 1),
    ('keyboard', const Size(390, 844), 320, 1),
    ('large-text', const Size(390, 844), 0, 1.6),
    ('dark-phone', const Size(390, 844), 0, 1),
    ('dark-desktop', const Size(1280, 900), 0, 1),
    ('upstairs-hallway', const Size(1280, 900), 0, 1),
    ('safe-phone', const Size(320, 568), 0, 1),
    ('safe-landscape', const Size(844, 390), 0, 1),
    ('safe-large-text', const Size(390, 844), 0, 1.6),
    ('hint-phone', const Size(320, 568), 0, 1),
  ]) {
    testWidgets('${variant.$1}: layout and command submission remain usable', (
      tester,
    ) async {
      tester.view.physicalSize = variant.$2;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: variant.$3);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final dark = variant.$1.startsWith('dark-');
      SharedPreferences.setMockInitialValues({
        if (dark)
          'cloak_save_state': jsonEncode(
            (AdventureEngine()..room = 22).toJson(),
          ),
      });
      final game = GameState();
      await game.initialize();
      game.setAutoAnimateRooms(false);
      final capture = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: game,
          child: RepaintBoundary(
            key: capture,
            child: MediaQuery(
              data: MediaQueryData(
                size: variant.$2,
                viewInsets: EdgeInsets.only(bottom: variant.$3),
                textScaler: TextScaler.linear(variant.$4),
              ),
              child: const CloakOfDeathApp(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final input = find.byKey(const ValueKey('command-input'));
      expect(input, findsOneWidget);
      expect(
        tester.getRect(input).bottom,
        lessThanOrEqualTo(variant.$2.height - variant.$3),
      );
      await tester.enterText(input, 'LOOK');
      await tester.tap(find.byTooltip('Send command'));
      await tester.pumpAndSettle();
      expect(game.moveCount, 1);
      if (!dark) expect(game.getVisibleObjects(), contains('CORRIDOR'));
      if (variant.$1 == 'upstairs-hallway') {
        // The player needs the Bible to overcome fear of going upstairs.
        for (final command in [
          'E',
          'N',
          'EXAMINE DESK',
          'GET BIBLE',
          'S',
          'W',
        ]) {
          game.processCommand(command);
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('U'));
        await tester.pumpAndSettle();
        expect(game.currentRoomId, 9);
        expect(find.byType(AtariAnimatedRoomView), findsOneWidget);
        expect(find.text('Room 9 has no graphics data'), findsNothing);
        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((widget) => widget.painter)
            .whereType<AtariPixelRenderer>()
            .single;
        expect(painter.screenBuffer!.pixels.toSet().length, 4);
      }
      final frame = tester.getRect(
        find.byKey(const ValueKey('room-artwork-frame')),
      );
      final rail = tester.getRect(
        find.byKey(const ValueKey('room-navigation-rail')),
      );
      expect(frame.width / frame.height, closeTo(game.aspectRatio, 0.001));
      expect(rail.left, greaterThan(frame.right));
      expect(tester.takeException(), isNull);

      if (variant.$1.startsWith('safe-')) {
        for (final command in walkthroughCommands) {
          if (command == '1327') break;
          game.processCommand(command);
        }
        await tester.pumpAndSettle();
        expect(game.awaitingCombination, isTrue);
        expect(find.byKey(const ValueKey('safe-combination')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      if (variant.$1 == 'hint-phone') {
        await tester.tap(find.byTooltip('A gentle hint'));
        await tester.pumpAndSettle();
        expect(find.text('Hints for your next step'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      const previewDir = String.fromEnvironment('PREVIEW_DIR');
      if (previewDir.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(previewDir).create(recursive: true);
          await File(
            '$previewDir/${variant.$1}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      if (variant.$1.startsWith('safe-')) {
        await tester.ensureVisible(find.text('Try combination'));
        expect(tester.takeException(), isNull);
      }
      await game.saveState();
    });
  }

  testWidgets(
    'disabling animation renders a full scene, including after room changes',
    (tester) async {
      var animated = false;
      var room = 1;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return AtariAnimatedRoomView(
                roomData: AtariBytecodeParser.parseRoom(
                  RoomBytecodeLoader.getRoomBuffer(room)!,
                  room,
                )!,
                autoStart: animated,
              );
            },
          ),
        ),
      );
      await tester.pump();
      AtariPixelRenderer painter() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<AtariPixelRenderer>()
          .single;
      expect(painter().screenBuffer!.pendingCount, 0);
      expect(painter().screenBuffer!.pixels.toSet().length, greaterThan(1));
      rebuild(() {
        room = 8;
      });
      await tester.pump();
      expect(painter().screenBuffer!.pendingCount, 0);
      expect(painter().screenBuffer!.pixels.toSet().length, greaterThan(1));
      rebuild(() {
        room = 7;
        animated = true;
      });
      await tester.pump();
      rebuild(() {
        animated = false;
      });
      await tester.pump();
      expect(painter().screenBuffer!.pendingCount, 0);
      expect(painter().screenBuffer!.pixels.toSet().length, greaterThan(1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
    },
  );
}
