import 'dart:convert';

import 'package:assistant_planning/app/providers.dart';
import 'package:assistant_planning/data/database.dart';
import 'package:assistant_planning/data/planning_service.dart';
import 'package:assistant_planning/data/settings_repository.dart';
import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/plan_import.dart';
import 'package:assistant_planning/domain/plan_parser.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/features/import_plan/import_preview_panel.dart';
import 'package:assistant_planning/features/shared/timeline_layout.dart';
import 'package:assistant_planning/features/task_editor/task_detail.dart';
import 'package:assistant_planning/features/task_editor/task_editor.dart';
import 'package:assistant_planning/app/theme/app_theme.dart';
import 'package:assistant_planning/notifications/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

ParsedPlan weekPlan() => parsePlanJson(
  jsonEncode({
    'schema_version': 1,
    'tasks': [
      for (var i = 0; i < 7; i++)
        {
          'title': 'Jour $i',
          'date': monday.addDays(i).toIso(),
          'start': '08:00',
          'end': '10:00',
          'category': 'cours',
        },
    ],
  }),
);

Future<void> importWeek(
  WidgetTester tester,
  AppDatabase db,
  FakeClock clock, {
  required bool fromToday,
}) async {
  await tester.runAsync(() async {
    await PlanningService(
      tasks: TaskRepository(db),
      settings: SettingsRepository(db, clock),
      clock: clock,
      scheduler: const NoopReminderScheduler(),
    ).importPlan(
      plan: weekPlan(),
      mode: ImportMode.replace,
      fromToday: fromToday,
      applyDayBounds: false,
    );
  });
  await tester.pumpAndSettle();
}

Future<void> seed(WidgetTester tester, AppDatabase db, List<Task> tasks) async {
  await tester.runAsync(() => TaskRepository(db).upsertAll(tasks));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initAppFormats);

  group('Aujourd\'hui', () {
    testWidgets('état vide', (tester) async {
      await pumpApp(tester);
      expect(find.text("Rien de prévu aujourd'hui"), findsOneWidget);
      expect(find.text('Importer un planning'), findsOneWidget);
      expect(find.text('Mardi 10 novembre 2026'), findsOneWidget);
    });

    testWidgets('le bouton de l\'état vide ouvre l\'import', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Importer un planning'));
      await tester.pumpAndSettle();
      expect(find.text('Copier le prompt'), findsOneWidget);
    });

    testWidgets('frise : blocs, résumé et trait maintenant', (tester) async {
      final db = await pumpApp(tester);
      await seed(tester, db, [
        makeTask(id: 'a', title: 'Cours', start: '08:00', end: '10:00'),
        makeTask(id: 'b', title: 'Sport', start: '14:00', end: '16:00'),
      ]);
      expect(find.text('Cours'), findsOneWidget);
      expect(find.text('Sport'), findsOneWidget);
      expect(find.text('2 tâches restantes, prochaine à 14h'), findsOneWidget);
      expect(find.byKey(const ValueKey('now-line')), findsOneWidget);
    });

    testWidgets('section 5.3 : import un mardi, lundi jamais affiché', (
      tester,
    ) async {
      final clock = FakeClock.porto(tuesday, 7);
      final db = await pumpApp(tester, clock: clock);
      await importWeek(tester, db, clock, fromToday: true);
      expect(find.text('Jour 1'), findsOneWidget);
      expect(find.text('Jour 0'), findsNothing);
    });

    testWidgets(
      'section 5.3 : option désactivée, lundi absent d\'Aujourd\'hui',
      (tester) async {
        final clock = FakeClock.porto(tuesday, 7);
        final db = await pumpApp(tester, clock: clock);
        await importWeek(tester, db, clock, fromToday: false);
        expect(find.text('Jour 1'), findsOneWidget);
        expect(find.text('Jour 0'), findsNothing);

        await tester.tap(find.text('Semaine'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('9'));
        await tester.pumpAndSettle();
        expect(find.text('Jour 0'), findsOneWidget);
        expect(find.text('Passée'), findsOneWidget);
      },
    );

    testWidgets('section 5.3 : passage de minuit, l\'appli reste ouverte', (
      tester,
    ) async {
      final clock = FakeClock.porto(tuesday, 23, 59);
      final db = await pumpApp(tester, clock: clock);
      await seed(tester, db, [
        makeTask(id: 'mar', title: 'Mardi', start: '08:00', end: '09:00'),
        makeTask(
          id: 'mer',
          title: 'Mercredi',
          date: wednesday,
          start: '08:00',
          end: '09:00',
        ),
      ]);
      expect(find.text('Mardi 10 novembre 2026'), findsOneWidget);
      expect(find.text('Mardi'), findsOneWidget);
      expect(find.text('Mercredi'), findsNothing);

      clock.advance(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(find.text('Mercredi 11 novembre 2026'), findsOneWidget);
      expect(find.text('Mercredi'), findsOneWidget);
      expect(find.text('Mardi'), findsNothing);
    });

    testWidgets('retour au premier plan : la date est recalculée', (
      tester,
    ) async {
      final clock = FakeClock.porto(tuesday, 22);
      await pumpApp(tester, clock: clock);
      clock.advance(const Duration(hours: 3));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Mercredi 11 novembre 2026'), findsOneWidget);
    });

    testWidgets('changer de fuseau change le jour affiché', (tester) async {
      // 2 h UTC le mardi : déjà mardi à Porto-Novo, encore lundi à New York.
      final clock = FakeClock(DateTime.utc(2026, 11, 10, 2));
      final db = await pumpApp(tester, clock: clock);
      expect(find.text('Mardi 10 novembre 2026'), findsOneWidget);

      await tester.runAsync(
        () => SettingsRepository(
          db,
          clock,
        ).save(const AppSettings(timezone: 'America/New_York')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lundi 9 novembre 2026'), findsOneWidget);
    });
  });

  group('actions sur une tâche', () {
    testWidgets('marquer faite depuis la feuille de détail', (tester) async {
      final db = await pumpApp(tester);
      await seed(tester, db, [makeTask(title: 'Cours')]);

      await tester.tap(find.text('Cours'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fait'));
      await tester.pumpAndSettle();

      expect(find.text('Faite'), findsOneWidget);
      expect(find.text('Aucune tâche restante'), findsOneWidget);
    });

    testWidgets('décaler de 30 min', (tester) async {
      final db = await pumpApp(tester);
      await seed(tester, db, [
        makeTask(title: 'Cours', start: '10:00', end: '11:00'),
      ]);

      await tester.tap(find.text('Cours'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Décaler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+30 min'));
      await tester.pumpAndSettle();

      expect(find.text('10:30 – 11:30'), findsOneWidget);
      expect(find.text('Décalée'), findsOneWidget);
    });

    testWidgets('décaler la journée avertit du dépassement', (tester) async {
      final db = await pumpApp(tester);
      await seed(tester, db, [
        makeTask(title: 'Soir', start: '20:30', end: '21:45'),
      ]);

      await tester.tap(find.text('Décaler toute la journée'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.textContaining('après la fin de journée'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Décaler'));
      await tester.pumpAndSettle();
      expect(find.text('21:00 – 22:15'), findsOneWidget);
    });

    testWidgets('annuler et supprimer', (tester) async {
      final db = await pumpApp(tester);
      await seed(tester, db, [makeTask(title: 'Cours')]);

      await tester.tap(find.text('Cours'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Annulée'), findsOneWidget);

      await tester.tap(find.text('Cours'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();
      expect(find.text('Cours'), findsNothing);
    });
  });

  group('éditeur', () {
    Future<void> pumpEditor(WidgetTester tester, Task? task) async {
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(FakeClock.porto(tuesday, 9)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: TaskEditorForm(task: task)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('titre obligatoire', (tester) async {
      await pumpEditor(tester, null);
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      expect(find.text('Le titre est obligatoire.'), findsOneWidget);
    });

    testWidgets('refuse une fin avant le début', (tester) async {
      await pumpEditor(
        tester,
        makeTask().copyWith(
          start: const LocalTime(10, 0),
          end: const LocalTime(9, 0),
        ),
      );
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      expect(find.text('La fin doit être après le début.'), findsOneWidget);
    });
  });

  group('Semaine', () {
    Future<AppDatabase> seeded(WidgetTester tester, double width) async {
      final db = await pumpApp(tester, width: width);
      await seed(tester, db, [
        makeTask(id: 'lun', title: 'Lundi', date: monday),
        makeTask(id: 'mar', title: 'Mardi'),
        makeTask(
          id: 'dim',
          title: 'Dimanche',
          date: const LocalDate(2026, 11, 15),
        ),
      ]);
      await tester.tap(find.text('Semaine'));
      await tester.pumpAndSettle();
      return db;
    }

    testWidgets('390 dp : bande de jours et liste du jour', (tester) async {
      await seeded(tester, 390);
      expect(find.text('9 – 15 novembre 2026'), findsOneWidget);
      expect(find.text('Mardi'), findsOneWidget);
      expect(find.text('Lundi'), findsNothing);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(find.text('Dimanche'), findsOneWidget);
    });

    testWidgets('800 dp : trois jours', (tester) async {
      await seeded(tester, 800);
      expect(find.text('Mardi'), findsOneWidget);
      expect(find.text('Lundi'), findsNothing);
      expect(find.text('jeu. 12'), findsOneWidget);
      expect(find.text('ven. 13'), findsNothing);
    });

    testWidgets('1280 dp : sept colonnes et panneau de détail', (tester) async {
      await seeded(tester, 1280);
      for (final title in ['Lundi', 'Mardi', 'Dimanche']) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('dim. 15'), findsOneWidget);
      expect(find.byType(TaskDetailView), findsNothing);

      await tester.tap(find.text('Mardi'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailView), findsOneWidget);
      expect(find.text('Mardi 10 novembre 2026'), findsOneWidget);
    });

    testWidgets('navigation entre semaines et retour à aujourd\'hui', (
      tester,
    ) async {
      await seeded(tester, 390);
      await tester.tap(find.byTooltip('Semaine suivante'));
      await tester.pumpAndSettle();
      expect(find.text('16 – 22 novembre 2026'), findsOneWidget);
      expect(find.text('Mardi'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, "Aujourd'hui"));
      await tester.pumpAndSettle();
      expect(find.text('9 – 15 novembre 2026'), findsOneWidget);
      expect(find.text('Mardi'), findsOneWidget);
    });
  });

  group('aperçu d\'import', () {
    Future<void> pumpPreview(WidgetTester tester, ParsedPlan plan) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = createTestDatabase();
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(FakeClock.porto(tuesday, 9)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ImportPreviewPanel(plan: plan, onImported: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('option activée par défaut, compte recalculé', (tester) async {
      await pumpPreview(tester, weekPlan());
      expect(find.text('Importer 6 tâches'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Importer 7 tâches'), findsOneWidget);
    });

    testWidgets('section 5.3 : avertit d\'un fuseau différent', (tester) async {
      final plan = parsePlanJson(
        jsonEncode({
          'schema_version': 1,
          'timezone': 'Europe/Paris',
          'tasks': <Object>[],
        }),
      );
      await pumpPreview(tester, plan);
      expect(find.textContaining('Europe/Paris'), findsOneWidget);
    });
  });

  group('disposition de la frise', () {
    final scale = TimelineScale.covering(
      dayStart: const LocalTime(7, 0),
      dayEnd: const LocalTime(22, 0),
      tasks: const [],
    );

    test('tâches qui se recouvrent côte à côte', () {
      final items = layoutTimeline(
        tasks: [
          makeTask(id: 'a', start: '08:00', end: '10:00'),
          makeTask(id: 'b', start: '09:00', end: '11:00'),
          makeTask(id: 'c', start: '12:00', end: '13:00'),
        ],
        scale: scale,
        minHeight: 52,
      );
      final byId = {for (final item in items) item.task.id: item};
      expect(byId['a']!.columnCount, 2);
      expect(byId['b']!.column, 1);
      expect(byId['c']!.columnCount, 1);
    });

    test('la frise s\'élargit aux tâches hors de la journée', () {
      final wide = TimelineScale.covering(
        dayStart: const LocalTime(7, 0),
        dayEnd: const LocalTime(22, 0),
        tasks: [makeTask(start: '05:30', end: '06:00')],
      );
      expect(wide.startMinutes, 5 * 60);
      expect(wide.endMinutes, 22 * 60);
    });
  });
}
