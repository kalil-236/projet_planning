import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(initAppFormats);

  Future<void> openReport(WidgetTester tester, List<Task> tasks) async {
    final db = await pumpApp(tester);
    await tester.runAsync(() => TaskRepository(db).upsertAll(tasks));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bilan').last);
    await tester.pumpAndSettle();
  }

  testWidgets('chiffres de la semaine, verdict et graphique', (tester) async {
    await openReport(tester, [
      makeTask(id: 'a', date: monday, status: TaskStatus.done),
      makeTask(id: 'b', date: monday, start: '11:00', end: '12:00'),
      makeTask(id: 'c', start: '06:00', end: '07:00', status: TaskStatus.done),
      makeTask(id: 'd', date: wednesday),
    ]);
    expect(find.text('67 %'), findsOneWidget);
    expect(find.text('2 missions accomplies sur 3 dues'), findsOneWidget);
    expect(find.text('1 à venir'), findsOneWidget);
    expect(find.text('Missions par jour'), findsOneWidget);
    for (final title in ['Temps par catégorie', 'F.R.I.D.A.Y a remarqué']) {
      await tester.scrollUntilVisible(find.text(title), 300);
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('semaine précédente vide : état vide, retour possible', (
    tester,
  ) async {
    await openReport(tester, [makeTask()]);
    await tester.tap(find.byTooltip('Semaine précédente'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune tâche cette semaine'), findsOneWidget);
    await tester.tap(find.text('Cette semaine'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune tâche cette semaine'), findsNothing);
  });
}
