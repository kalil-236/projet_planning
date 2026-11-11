import 'dart:convert';

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
import 'package:assistant_planning/domain/task_ops.dart';
import 'package:assistant_planning/notifications/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

class MockScheduler extends Mock implements ReminderScheduler {}

const _week = DateRange(LocalDate(2026, 11, 1), LocalDate(2026, 11, 30));

ParsedPlan weekPlan({String? dayEnd}) => parsePlanJson(
  jsonEncode({
    'schema_version': 1,
    'plan_start': '2026-11-09',
    'plan_end': '2026-11-15',
    'day_bounds': ?(dayEnd == null ? null : {'start': '06:00', 'end': dayEnd}),
    'tasks': [
      for (var i = 0; i < 7; i++)
        {
          'title': 'Jour $i',
          'date': monday.addDays(i).toIso(),
          'start': '08:00',
          'end': '09:00',
        },
    ],
  }),
);

void main() {
  late AppDatabase db;
  late TaskRepository tasks;
  late SettingsRepository settings;
  late MockScheduler scheduler;
  late PlanningService service;
  late FakeClock clock;

  setUpAll(initAppFormats);

  setUp(() {
    db = createTestDatabase();
    clock = FakeClock.porto(tuesday, 9);
    tasks = TaskRepository(db);
    settings = SettingsRepository(db, clock);
    scheduler = MockScheduler();
    when(scheduler.rescheduleAll).thenAnswer((_) async {});
    service = PlanningService(
      tasks: tasks,
      settings: settings,
      clock: clock,
      scheduler: scheduler,
    );
  });

  tearDown(() => db.close());

  test('aller-retour complet d\'une tâche en base', () async {
    final task = makeTask(
      originalStart: '07:00',
      shifted: true,
      source: TaskSource.import,
    ).copyWith(notes: 'Salle B2', reminderBeforeMin: 15);
    await tasks.upsert(task);
    expect(await tasks.activeInRange(_week), [task]);
  });

  test('réglages par défaut, puis enregistrés', () async {
    expect(await settings.current(), const AppSettings());
    const edited = AppSettings(
      dayEnd: LocalTime(20, 30),
      themeMode: AppThemeMode.dark,
    );
    await settings.save(edited);
    expect(await settings.current(), edited);
  });

  group('import', () {
    test('section 5.3 : mardi, option activée', () async {
      final summary = await service.importPlan(
        plan: weekPlan(),
        mode: ImportMode.replace,
        fromToday: true,
        applyDayBounds: false,
      );
      expect(summary.inserted, 6);
      final stored = await tasks.activeInRange(_week);
      expect(stored.map((t) => t.date), isNot(contains(monday)));
      expect(tasksForToday(stored, tuesday).single.title, 'Jour 1');
    });

    test('section 5.3 : mardi, option désactivée', () async {
      await service.importPlan(
        plan: weekPlan(),
        mode: ImportMode.replace,
        fromToday: false,
        applyDayBounds: false,
      );
      final stored = await tasks.activeInRange(_week);
      final mondayTask = stored.singleWhere((t) => t.date == monday);
      expect(mondayTask.status, TaskStatus.missed);
      final today = tasksForToday(stored, tuesday);
      expect(today.single.date, tuesday);
    });

    test('réimporter en remplacement ne crée pas de doublons', () async {
      for (var i = 0; i < 2; i++) {
        await service.importPlan(
          plan: weekPlan(),
          mode: ImportMode.replace,
          fromToday: true,
          applyDayBounds: false,
        );
      }
      expect(await tasks.activeInRange(_week), hasLength(6));
    });

    test('remplacer conserve une tâche faite', () async {
      await service.importPlan(
        plan: weekPlan(),
        mode: ImportMode.merge,
        fromToday: true,
        applyDayBounds: false,
      );
      final first = (await tasks.activeInRange(_week)).first;
      await service.setStatus(first, TaskStatus.done);

      final summary = await service.importPlan(
        plan: weekPlan(),
        mode: ImportMode.replace,
        fromToday: true,
        applyDayBounds: false,
      );
      expect(summary.replaced, 5);
      expect(summary.skippedDuplicates, 1);
      final stored = await tasks.activeInRange(_week);
      expect(stored, hasLength(6));
      expect(stored.where((t) => t.status == TaskStatus.done), hasLength(1));
    });

    test('fusionner deux fois ignore les doublons', () async {
      for (var i = 0; i < 2; i++) {
        await service.importPlan(
          plan: weekPlan(),
          mode: ImportMode.merge,
          fromToday: true,
          applyDayBounds: false,
        );
      }
      expect(await tasks.activeInRange(_week), hasLength(6));
    });

    test('applique les bornes de journée sur demande seulement', () async {
      await service.importPlan(
        plan: weekPlan(dayEnd: '21:00'),
        mode: ImportMode.merge,
        fromToday: true,
        applyDayBounds: false,
      );
      expect((await settings.current()).dayEnd, const LocalTime(22, 0));

      await service.importPlan(
        plan: weekPlan(dayEnd: '21:00'),
        mode: ImportMode.merge,
        fromToday: true,
        applyDayBounds: true,
      );
      expect((await settings.current()).dayEnd, const LocalTime(21, 0));
    });

    test('l\'import reprogramme les rappels', () async {
      await service.importPlan(
        plan: weekPlan(),
        mode: ImportMode.merge,
        fromToday: true,
        applyDayBounds: false,
      );
      verify(scheduler.rescheduleAll).called(1);
    });
  });

  test('section 5.3 : changer de fuseau garde la date locale et reprogramme '
      'les rappels', () async {
    final task = makeTask();
    await tasks.upsert(task);
    final before = await tasks.activeInRange(_week);

    await service.saveSettings(const AppSettings(timezone: 'America/New_York'));

    expect(await tasks.activeInRange(_week), before);
    expect((await settings.current()).timezone, 'America/New_York');
    verify(scheduler.rescheduleAll).called(1);
  });

  group('actions', () {
    test(
      "marquer faite note l'heure réelle, la remettre à faire l'oublie",
      () async {
        final task = makeTask();
        await tasks.upsert(task);
        await service.setStatus(task, TaskStatus.done);
        final done = (await tasks.byId(task.id))!;
        expect(done.completedAt, clock.nowUtc());

        clock.advance(const Duration(minutes: 5));
        await service.updateTask(done, done.copyWith(title: 'Renommée'));
        expect(
          (await tasks.byId(task.id))!.completedAt,
          done.completedAt,
          reason: 'modifier une tâche faite garde son heure de réalisation',
        );

        await service.setStatus(done, TaskStatus.todo);
        expect((await tasks.byId(task.id))!.completedAt, isNull);
      },
    );

    test('statut « Faite » choisi dans le formulaire', () async {
      final task = makeTask();
      await tasks.upsert(task);
      await service.updateTask(task, task.copyWith(status: TaskStatus.done));
      expect((await tasks.byId(task.id))!.completedAt, isNotNull);
    });

    test('reporter à demain les tâches restantes du jour', () async {
      await tasks.upsertAll([
        makeTask(id: 'a', start: '17:00', end: '18:00'),
        makeTask(id: 'b', status: TaskStatus.done),
        makeTask(id: 'c', date: wednesday, start: '09:00', end: '10:00'),
      ]);
      expect(await service.postponeToNextDay(tuesday), 1);
      final moved = (await tasks.byId('a'))!;
      expect(moved.date, wednesday);
      expect(moved.start, const LocalTime(17, 0));
      expect(moved.shifted, isTrue);
      expect((await tasks.byId('b'))!.date, tuesday);
      expect(await service.postponeToNextDay(tuesday), 0);
    });

    test('la suppression est logique', () async {
      final task = makeTask();
      await tasks.upsert(task);
      await service.deleteTask(task);
      expect(await tasks.activeInRange(_week), isEmpty);
      final row = await db.select(db.tasks).getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('décaler refuse de traverser minuit sans rien écrire', () async {
      final task = makeTask(start: '23:00', end: '23:30');
      await tasks.upsert(task);
      expect(await service.shiftBy(task, 60), isFalse);
      expect(await tasks.activeInRange(_week), [task]);
      verifyNever(scheduler.rescheduleAll);
    });

    test('décaler la journée applique le plan', () async {
      await tasks.upsert(makeTask(id: 'a', start: '10:00', end: '11:00'));
      await tasks.upsert(makeTask(id: 'b', start: '07:00', end: '08:00'));
      final plan = await service.previewDayShift(30);
      await service.applyDayShift(plan);
      final stored = await tasks.activeInRange(_week);
      expect(stored.firstWhere((t) => t.id == 'a').start.toHHmm(), '10:30');
      expect(stored.firstWhere((t) => t.id == 'b').start.toHHmm(), '07:00');
    });

    test('modifier l\'heure d\'une tâche importée la marque décalée', () async {
      final task = makeTask(source: TaskSource.import);
      await service.updateTask(
        task,
        task.copyWith(start: const LocalTime(9, 0)),
      );
      final stored = (await tasks.activeInRange(_week)).single;
      expect(stored.shifted, isTrue);
      expect(stored.originalStart, const LocalTime(8, 0));
    });

    test('ajout manuel nettoyé des emojis', () async {
      await service.addTask(
        title: 'Sport \u{1F3C3}',
        date: tuesday,
        start: const LocalTime(10, 0),
        end: const LocalTime(11, 0),
        category: makeTask().category,
        notes: '   ',
        reminderBeforeMin: null,
      );
      final stored = (await tasks.activeInRange(_week)).single;
      expect(stored.title, 'Sport');
      expect(stored.notes, isNull);
      expect(stored.source, TaskSource.manual);
    });
  });
}
