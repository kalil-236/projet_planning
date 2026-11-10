import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

Future<Task> _read(WidgetTester tester, TaskRepository repo) async =>
    (await tester.runAsync(() => repo.byId('a')))!;

void main() {
  setUpAll(initAppFormats);

  Future<TaskRepository> pumpWithTask(WidgetTester tester) async {
    final db = createTestDatabase();
    final repo = TaskRepository(db);
    await tester.runAsync(
      () => repo.upsert(
        makeTask(id: 'a', title: 'Révisions', start: '10:00', end: '12:00'),
      ),
    );
    await pumpApp(tester, database: db);
    return repo;
  }

  testWidgets('glisser à droite : faite, puis Annuler', (tester) async {
    final repo = await pumpWithTask(tester);
    await tester.drag(find.text('Révisions'), const Offset(160, 0));
    await tester.pumpAndSettle();
    expect((await _read(tester, repo)).status, TaskStatus.done);
    expect(find.text('Faite : Révisions'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect((await _read(tester, repo)).status, TaskStatus.todo);
  });

  testWidgets('glisser à gauche : décalée de 15 min', (tester) async {
    final repo = await pumpWithTask(tester);
    await tester.drag(find.text('Révisions'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    final task = (await _read(tester, repo));
    expect(task.start, const LocalTime(10, 15));
    expect(task.shifted, isTrue);
  });

  testWidgets('glissement trop court : rien ne change', (tester) async {
    final repo = await pumpWithTask(tester);
    await tester.drag(find.text('Révisions'), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect((await _read(tester, repo)).status, TaskStatus.todo);
  });

  testWidgets('actions proposées aux lecteurs d\'écran', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWithTask(tester);
    final node = tester.getSemantics(
      find
          .ancestor(
            of: find.text('Révisions'),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Semantics && w.properties.customSemanticsActions != null,
            ),
          )
          .first,
    );
    final labels = node.getSemanticsData().customSemanticsActionIds;
    expect(labels, hasLength(2));
    handle.dispose();
  });
}
