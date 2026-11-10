import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/features/task_editor/task_editor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(initAppFormats);

  testWidgets('créneau libre : ajoute une tâche préremplie', (tester) async {
    final db = createTestDatabase();
    await tester.runAsync(
      () => TaskRepository(db).upsertAll([
        makeTask(id: 'a', title: 'Cours', start: '10:00', end: '12:00'),
        makeTask(id: 'b', title: 'Sport', start: '14:00', end: '15:00'),
      ]),
    );
    await pumpApp(tester, database: db);

    final slot = find.textContaining('Libre · 2 h · 12h – 14h');
    expect(slot, findsOneWidget);
    await tester.tap(slot);
    await tester.pumpAndSettle();
    expect(find.byType(TaskEditorForm), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
  });

  testWidgets('chevauchement signalé sur les tâches et en tête', (
    tester,
  ) async {
    final db = createTestDatabase();
    await tester.runAsync(
      () => TaskRepository(db).upsertAll([
        makeTask(id: 'a', title: 'Cours', start: '10:00', end: '12:00'),
        makeTask(id: 'b', title: 'Sport', start: '11:00', end: '13:00'),
      ]),
    );
    await pumpApp(tester, database: db);
    expect(find.text('2 tâches se chevauchent'), findsOneWidget);
    expect(find.text('Chevauchement'), findsNWidgets(2));
  });
}
