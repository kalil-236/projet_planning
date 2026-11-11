import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

const _batteryTile = 'Assistance batterie';
const _testButton = 'Envoyer une notification de test dans 1 minute';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Réglages'));
  await tester.pumpAndSettle();
}

Future<void> _openBattery(WidgetTester tester) async {
  await _openSettings(tester);
  await tester.scrollUntilVisible(find.text(_batteryTile), 100);
  await tester.ensureVisible(find.text(_batteryTile));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_batteryTile));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initAppFormats);

  group('demande de permission au premier lancement', () {
    testWidgets('explique, demande, puis ne redemande plus', (tester) async {
      final gateway = FakeNotificationGateway();
      final db = createTestDatabase();

      await pumpApp(tester, gateway: gateway, database: db);
      expect(find.text('Autoriser les rappels'), findsOneWidget);
      expect(gateway.permissionRequests, 0);

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(gateway.permissionRequests, 1);

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, gateway: gateway, database: db);
      expect(find.text('Autoriser les rappels'), findsNothing);
      expect(gateway.permissionRequests, 1);
    });

    testWidgets('rien à demander si déjà autorisé', (tester) async {
      final gateway = FakeNotificationGateway()..allowed = true;

      await pumpApp(tester, gateway: gateway);

      expect(find.text('Autoriser les rappels'), findsNothing);
    });

    testWidgets('rien sur le web', (tester) async {
      await pumpApp(tester);

      expect(find.text('Autoriser les rappels'), findsNothing);
    });
  });

  group('réglages', () {
    testWidgets('désactiver le résumé masque son heure', (tester) async {
      await pumpApp(tester);
      await _openSettings(tester);
      expect(find.text('Heure du résumé'), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(find.text('Heure du résumé'), findsNothing);
    });

    testWidgets('pas d\'assistance batterie sur le web', (tester) async {
      await pumpApp(tester);
      await _openSettings(tester);

      expect(find.text(_batteryTile), findsNothing);
    });
  });

  group('assistance batterie', () {
    late FakeNotificationGateway gateway;

    setUp(() => gateway = FakeNotificationGateway()..allowed = true);

    testWidgets('affiche l\'état et propose de corriger', (tester) async {
      gateway.exact = false;

      await pumpApp(tester, gateway: gateway);
      await _openBattery(tester);

      expect(find.text('Notifications autorisées'), findsOneWidget);
      expect(find.text('Ouvrir « Alarmes et rappels »'), findsOneWidget);

      await tester.tap(find.text('Ouvrir « Alarmes et rappels »'));
      await tester.pumpAndSettle();
      expect(gateway.exactSettingsOpened, 1);
    });

    testWidgets('désactive l\'optimisation de batterie', (tester) async {
      await pumpApp(tester, gateway: gateway);
      await _openBattery(tester);

      await tester.tap(find.text('Désactiver'));
      await tester.pumpAndSettle();

      expect(find.text('Optimisation de batterie désactivée'), findsOneWidget);
    });

    testWidgets('programme la notification de test', (tester) async {
      await pumpApp(tester, gateway: gateway);
      await _openBattery(tester);

      await tester.scrollUntilVisible(find.text(_testButton), 100);
      await tester.tap(find.text(_testButton));
      await tester.pumpAndSettle();

      expect(gateway.pending, contains(testNotificationId));
      expect(
        find.text('Notification de test prévue dans 1 minute.'),
        findsOneWidget,
      );
    });

    testWidgets('refuse le test sans autorisation', (tester) async {
      gateway.allowed = false;
      await pumpApp(tester, gateway: gateway);
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await _openBattery(tester);

      await tester.scrollUntilVisible(find.text(_testButton), 100);
      await tester.tap(find.text(_testButton));
      await tester.pumpAndSettle();

      expect(gateway.pending, isNot(contains(testNotificationId)));
      expect(
        find.text('Autorisez d\'abord les notifications.'),
        findsOneWidget,
      );
    });

    testWidgets('le bouton retour revient aux réglages', (tester) async {
      await pumpApp(tester, gateway: gateway);
      await _openBattery(tester);

      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();

      expect(find.text(_batteryTile), findsOneWidget);
    });
  });
}
