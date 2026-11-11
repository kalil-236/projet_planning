import 'package:assistant_planning/data/device_prefs_repository.dart';
import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/notifications/notification_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_speaker.dart';
import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(initAppFormats);

  testWidgets('« Écouter le briefing » lit les tâches du jour', (tester) async {
    final speaker = FakeSpeaker();
    final db = createTestDatabase();
    await tester.runAsync(
      () => TaskRepository(db)
          .upsert(makeTask(title: 'Révisions', start: '14:00', end: '16:00')),
    );
    await pumpApp(tester, database: db, speaker: speaker);
    await tester.tap(find.byTooltip('Écouter le briefing'));
    await tester.pumpAndSettle();
    expect(speaker.spoken.single, contains('Révisions à 14 heures'));
  });

  testWidgets('bouton « Écouter » du résumé : lecture à l\'ouverture', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    await pumpApp(
      tester,
      speaker: speaker,
      gateway: FakeNotificationGateway()..allowed = true,
    );
    notificationTaps.add(listenPayload);
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(speaker.spoken, hasLength(1));
  });

  testWidgets('réglages : voix choisie et test de la voix', (tester) async {
    final speaker = FakeSpeaker();
    final db = await pumpApp(tester, speaker: speaker);
    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    expect(find.text('Voix de F.R.I.D.A.Y'), findsOneWidget);

    await tester.tap(find.text('Voix française par défaut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('fr-fr-x-vlf (fr-FR)').last);
    await tester.pumpAndSettle();
    final prefs = await tester.runAsync(
      () => DevicePrefsRepository(db).current(),
    );
    expect(prefs!.voiceName, 'fr-fr-x-vlf');

    await tester.ensureVisible(find.text('Tester la voix'));
    await tester.tap(find.text('Tester la voix'));
    await tester.pumpAndSettle();
    expect(speaker.spoken.single, startsWith('Bonjour monsieur'));
    expect(speaker.usedPrefs.single.voiceName, 'fr-fr-x-vlf');
    expect(find.byType(Slider), findsNWidgets(2));
  });
}
