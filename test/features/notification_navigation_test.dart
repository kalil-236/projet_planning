import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:assistant_planning/notifications/notification_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(initAppFormats);

  testWidgets('lancée par le bilan de la semaine : ouvre Bilan', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway()
      ..allowed = true
      ..launchedWith = reportPayload;
    await pumpApp(tester, gateway: gateway);
    expect(find.widgetWithText(AppBar, 'Bilan'), findsOneWidget);
  });

  testWidgets('notification touchée application ouverte', (tester) async {
    await pumpApp(tester, gateway: FakeNotificationGateway()..allowed = true);
    await tester.tap(find.text('Semaine'));
    await tester.pumpAndSettle();

    notificationTaps.add(reportPayload);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Bilan'), findsOneWidget);

    notificationTaps.add('t1');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, "Aujourd'hui"), findsOneWidget);
  });
}
