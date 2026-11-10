import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/features/task_editor/task_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

Finder get _field => find.widgetWithText(TextField, 'Ajout express');

void main() {
  setUpAll(initAppFormats);

  testWidgets('aperçu en direct puis ajout avec Entrée', (tester) async {
    final db = await pumpApp(tester);
    await tester.enterText(_field, 'sport demain 18h 1h');
    await tester.pump();
    expect(find.textContaining('demain, 18h – 19h · Activité'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final tasks = await tester.runAsync(
      () => TaskRepository(db).activeInRange(
        const DateRange(LocalDate(2026, 11, 11), LocalDate(2026, 11, 11)),
      ),
    );
    expect(tasks, hasLength(1));
    expect(tasks!.single.title, 'Sport');
    expect(tasks.single.start, const LocalTime(18, 0));
    expect(tasks.single.category, TaskCategory.activite);
    expect(find.textContaining('Ajouté : Sport'), findsOneWidget);
  });

  testWidgets('phrase incomplète : explication, pas d\'ajout', (tester) async {
    await pumpApp(tester);
    await tester.enterText(_field, 'demain 18h');
    await tester.pump();
    expect(find.textContaining('Ajoutez un titre'), findsOneWidget);
    expect(find.byTooltip('Ajouter'), findsNothing);
  });

  testWidgets('« Détails » ouvre le formulaire prérempli', (tester) async {
    await pumpApp(tester);
    await tester.enterText(_field, 'révisions de 14h à 16h');
    await tester.pump();
    await tester.tap(find.text('Détails'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskEditorForm), findsOneWidget);
    expect(find.text('Révisions'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
  });
}
