import 'package:assistant_planning/core/french_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _openWeek(WidgetTester tester) async {
  await tester.tap(find.text('Semaine').first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initAppFormats);

  testWidgets('N ouvre une nouvelle tâche', (tester) async {
    await pumpApp(tester, width: 1280);

    await _press(tester, LogicalKeyboardKey.keyN);

    expect(find.text('Nouvelle tâche'), findsOneWidget);
  });

  testWidgets('une fenêtre ouverte désactive les raccourcis', (tester) async {
    await pumpApp(tester, width: 1280);
    await _press(tester, LogicalKeyboardKey.keyN);

    await _press(tester, LogicalKeyboardKey.keyN);

    expect(find.text('Nouvelle tâche'), findsOneWidget);
  });

  testWidgets('saisir un N dans un champ ne déclenche rien', (tester) async {
    await pumpApp(tester, width: 1280);
    await _press(tester, LogicalKeyboardKey.keyN);

    await tester.enterText(find.byType(TextField).first, 'Natation');
    await _press(tester, LogicalKeyboardKey.keyN);

    expect(find.text('Nouvelle tâche'), findsOneWidget);
    expect(find.text('Natation'), findsOneWidget);
  });

  testWidgets('← et → changent de jour, et de semaine au besoin', (
    tester,
  ) async {
    await pumpApp(tester, width: 1280);
    await _openWeek(tester);
    final thisWeek = formatWeekRange(tuesday.monday);
    expect(find.text(thisWeek), findsOneWidget);

    await _press(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text(thisWeek), findsOneWidget, reason: 'mardi -> lundi');

    await _press(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text(formatWeekRange(tuesday.monday.addDays(-7))), findsOne);
  });

  testWidgets('T ramène Semaine à aujourd\'hui', (tester) async {
    await pumpApp(tester, width: 1280);
    await _openWeek(tester);
    for (var i = 0; i < 8; i++) {
      await _press(tester, LogicalKeyboardKey.arrowRight);
    }
    expect(find.text(formatWeekRange(tuesday.monday)), findsNothing);

    await _press(tester, LogicalKeyboardKey.keyT);

    expect(find.text(formatWeekRange(tuesday.monday)), findsOneWidget);
  });

  testWidgets('T ouvre Aujourd\'hui depuis un autre écran', (tester) async {
    await pumpApp(tester, width: 1280);
    await tester.tap(find.text('Réglages').first);
    await tester.pumpAndSettle();

    await _press(tester, LogicalKeyboardKey.keyT);

    expect(find.text(formatFullDate(tuesday)), findsOneWidget);
  });

  testWidgets('les flèches restent sans effet hors de Semaine', (tester) async {
    await pumpApp(tester, width: 1280);

    await _press(tester, LogicalKeyboardKey.arrowRight);

    expect(find.text(formatFullDate(tuesday)), findsOneWidget);
  });
}
