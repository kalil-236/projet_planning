import 'package:assistant_planning/app/in_app_reminders.dart';
import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(initAppFormats);

  Future<FakeClock> pumpBeforeStart(
    WidgetTester tester, {
    required bool enabled,
    TaskStatus status = TaskStatus.todo,
  }) async {
    final clock = FakeClock.porto(tuesday, 8, 59)
      ..advance(const Duration(seconds: 50));
    final db = await pumpApp(
      tester,
      width: 1280,
      clock: clock,
      inAppReminders: enabled,
    );
    await tester.runAsync(
      () => TaskRepository(db).upsert(
        makeTask(title: 'Cours', start: '09:00', end: '10:00', status: status),
      ),
    );
    await tester.pumpAndSettle();
    return clock;
  }

  Future<void> reachStart(WidgetTester tester, FakeClock clock) async {
    clock.advance(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('web : bandeau à l\'heure de début de la tâche', (tester) async {
    final clock = await pumpBeforeStart(tester, enabled: true);
    expect(find.text("C'est l'heure : Cours"), findsNothing);

    await reachStart(tester, clock);

    expect(find.text("C'est l'heure : Cours"), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('pas de bandeau pour une tâche faite', (tester) async {
    final clock = await pumpBeforeStart(
      tester,
      enabled: true,
      status: TaskStatus.done,
    );

    await reachStart(tester, clock);

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Android : pas de bandeau, les rappels sont des notifications', (
    tester,
  ) async {
    final clock = await pumpBeforeStart(tester, enabled: false);

    await reachStart(tester, clock);

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('mouvement réduit : changement d\'écran sans animation', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester);

    final context = tester.element(find.text('Semaine').first);
    final builders = Theme.of(context).pageTransitionsTheme.builders.values;
    expect(builders, everyElement(isA<NoTransitionsBuilder>()));
  });
}
