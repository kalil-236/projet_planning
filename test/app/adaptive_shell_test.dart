import 'package:assistant_planning/core/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

Future<void> pumpAppAtWidth(WidgetTester tester, double width) =>
    pumpApp(tester, width: width);

void main() {
  setUpAll(initAppFormats);

  group('ShellLayout.forWidth', () {
    test('respecte les seuils de la section 9.1', () {
      expect(ShellLayout.forWidth(599.9), ShellLayout.mobile);
      expect(ShellLayout.forWidth(600), ShellLayout.tablet);
      expect(ShellLayout.forWidth(1023.9), ShellLayout.tablet);
      expect(ShellLayout.forWidth(1024), ShellLayout.desktop);
    });
  });

  group('navigation adaptative', () {
    testWidgets('390 dp : barre en bas', (tester) async {
      await pumpAppAtWidth(tester, 390);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('800 dp : rail compact', (tester) async {
      await pumpAppAtWidth(tester, 800);
      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.destinations, hasLength(5));
    });

    testWidgets('1280 dp : barre latérale', (tester) async {
      await pumpAppAtWidth(tester, 1280);
      expect(find.byType(NavigationBar), findsNothing);
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(rail.destinations, hasLength(5));
    });

    for (final width in const [390.0, 800.0, 1280.0]) {
      testWidgets('$width dp : les 5 destinations sont accessibles', (
        tester,
      ) async {
        await pumpAppAtWidth(tester, width);
        expect(find.widgetWithText(AppBar, "Aujourd'hui"), findsOneWidget);

        for (final label in const [
          'Semaine',
          'Bilan',
          'Importer',
          'Réglages',
        ]) {
          await tester.tap(find.text(label).first);
          await tester.pumpAndSettle();
          expect(find.widgetWithText(AppBar, label), findsOneWidget);
        }
      });
    }
  });

  testWidgets('le thème suit le mode sombre du système', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpAppAtWidth(tester, 390);

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
