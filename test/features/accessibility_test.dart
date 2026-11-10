import 'dart:ui';

import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_sync_backend.dart';
import '../support/fakes.dart';
import '../support/test_app.dart';

/// Section 14, phase 4 : sémantique, contraste et échelle du texte.
final _tasks = [
  makeTask(id: 'a', title: 'Cours de maths', start: '08:00', end: '10:00'),
  makeTask(
    id: 'b',
    title: 'Sport',
    start: '11:00',
    end: '12:00',
    status: TaskStatus.done,
  ),
  makeTask(
    id: 'c',
    title: 'Lecture',
    start: '14:00',
    end: '15:00',
  ).copyWith(status: TaskStatus.cancelled),
  makeTask(
    id: 'd',
    title: 'Révisions',
    start: '16:00',
    end: '17:00',
    shifted: true,
    originalStart: '15:30',
  ),
];

const _screens = ['Aujourd\'hui', 'Semaine', 'Importer', 'Réglages'];

Future<void> _pumpSeeded(
  WidgetTester tester, {
  required double width,
  double height = 900,
}) async {
  final db = await pumpApp(
    tester,
    width: width,
    height: height,
    syncBackend: FakeSyncBackend(FakeServer()),
  );
  await tester.runAsync(() => TaskRepository(db).upsertAll(_tasks));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _expectGuidelines(WidgetTester tester, String where) async {
  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: where,
  );
  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: where,
  );
  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: where,
  );
}

void main() {
  setUpAll(initAppFormats);

  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1280.0]) {
      testWidgets(
        'contraste et zones tactiles : ${brightness.name}, $width dp',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          final handle = tester.ensureSemantics();
          await _pumpSeeded(tester, width: width);

          for (final screen in _screens) {
            await _open(tester, screen);
            await _expectGuidelines(tester, '$screen, ${brightness.name}');
          }
          handle.dispose();
        },
      );
    }
  }

  testWidgets('écran de connexion accessible', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      syncBackend: FakeSyncBackend(FakeServer(), signedIn: false),
      loginRequired: true,
    );
    await _expectGuidelines(tester, 'connexion');
    handle.dispose();
  });

  for (final width in [390.0, 800.0, 1280.0]) {
    testWidgets('texte agrandi à 200 % sans débordement, $width dp', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpSeeded(tester, width: width);

      for (final screen in _screens) {
        await _open(tester, screen);
        expect(tester.takeException(), isNull, reason: screen);
      }
    });
  }

  testWidgets('chaque tâche est annoncée avec son état', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpSeeded(tester, width: 390);

    for (final state in ['Faite', 'Annulée', 'Décalée']) {
      expect(find.bySemanticsLabel(RegExp(state)), findsWidgets, reason: state);
    }
    handle.dispose();
  });
}
