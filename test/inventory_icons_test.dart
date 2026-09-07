import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloak_of_death_flutter/app_theme.dart';
import 'package:cloak_of_death_flutter/game/adventure_engine.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';
import 'package:cloak_of_death_flutter/widgets/interactive_inventory.dart';
import 'package:cloak_of_death_flutter/widgets/inventory_icon_painter.dart';
import 'package:cloak_of_death_flutter/widgets/object_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    const font = String.fromEnvironment('PREVIEW_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('Roboto')..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
    }
  });

  test('every portable object has purpose-built artwork', () {
    expect(
      InventoryIconPainter.supportedObjects,
      containsAll(AdventureEngine.portable),
    );
  });

  test('related items have distinct rendered states at chip size', () async {
    Future<List<int>> pixels(String object) async {
      final recorder = ui.PictureRecorder();
      InventoryIconPainter(object).paint(Canvas(recorder), const Size(20, 20));
      final picture = recorder.endRecording();
      final image = await picture.toImage(20, 20);
      final data = await image.toByteData();
      final bytes = data!.buffer.asUint8List().toList();
      image.dispose();
      picture.dispose();
      return bytes;
    }

    for (final pair in [
      ('KEY', 'GATE KEY'),
      ('BAR', 'BAR PIECES'),
      ('BOOK', 'BIBLE'),
      ('CANDLE', 'LIT CANDLE'),
      ('GOBLET', 'GOBLET OF WATER'),
      ('GOBLET OF WATER', 'HOLY WATER'),
      ('IRON', 'COAL'),
    ]) {
      expect(
        await pixels(pair.$1),
        isNot(await pixels(pair.$2)),
        reason: '${pair.$1} and ${pair.$2} must not share artwork',
      );
    }
  });

  testWidgets('inventory icon sheet and real phone inventory', (tester) async {
    tester.view.physicalSize = const Size(700, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    final game = GameState();
    SharedPreferences.setMockInitialValues({});
    await game.initialize();
    for (final command in ['W', 'N', 'GET KNIFE']) {
      game.processCommand(command);
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: RepaintBoundary(
          key: capture,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('INVENTORY · ITEM STUDIES'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      for (final object
                          in InventoryIconPainter.supportedObjects)
                        SizedBox(
                          width: 100,
                          height: 78,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ObjectIcon(object, size: 36),
                                  const SizedBox(width: 12),
                                  ObjectIcon(object, size: 20),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                object,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 320,
                    child: ChangeNotifierProvider.value(
                      value: game,
                      child: const InteractiveInventory(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNothing);
    const previewDir = String.fromEnvironment('PREVIEW_DIR');
    if (previewDir.isNotEmpty) {
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(previewDir).create(recursive: true);
        await File(
          '$previewDir/inventory-icons.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.widgetWithText(OutlinedButton, 'KNIFE'));
    await tester.pumpAndSettle();
    expect(find.text('DROP'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await game.saveState();
  });
}
