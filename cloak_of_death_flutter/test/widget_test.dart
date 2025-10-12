// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cloak_of_death_flutter/main.dart';
import 'package:cloak_of_death_flutter/game/game_state.dart';

void main() {
  testWidgets('Game app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => GameState()..initialize(),
        child: const CloakOfDeathApp(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app title is present
    expect(find.text('CLOAK OF DEATH'), findsOneWidget);
  });
}
