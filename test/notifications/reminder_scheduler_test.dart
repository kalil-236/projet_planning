import 'package:assistant_planning/data/database.dart';
import 'package:assistant_planning/data/planning_service.dart';
import 'package:assistant_planning/data/settings_repository.dart';
import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/notifications/reminder_scheduler.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(initAppFormats);

  late AppDatabase db;
  late TaskRepository tasks;
  late SettingsRepository settings;
  late FakeNotificationGateway gateway;
  late FakeClock clock;
  late LocalReminderScheduler scheduler;
  late PlanningService service;

  Iterable<PlannedNotification> startsOf() => gateway.pending.values.where(
    (notification) => notification.kind == NotificationKind.start,
  );

  setUp(() async {
    db = createTestDatabase();
    clock = FakeClock.porto(tuesday, 6);
    tasks = TaskRepository(db);
    settings = SettingsRepository(db, clock);
    gateway = FakeNotificationGateway();
    scheduler = LocalReminderScheduler(
      tasks: tasks,
      settings: settings,
      clock: clock,
      gateway: gateway,
    );
    service = PlanningService(
      tasks: tasks,
      settings: settings,
      clock: clock,
      scheduler: scheduler,
    );
    await settings.save(const AppSettings(morningSummaryEnabled: false));
  });

  tearDown(() => db.close());

  Future<Task> addedTask() async {
    await service.addTask(
      title: 'Cours',
      date: tuesday,
      start: const LocalTime(8, 0),
      end: const LocalTime(10, 0),
      category: TaskCategory.autre,
      notes: null,
      reminderBeforeMin: null,
    );
    return (await tasks.activeInRange(notificationWindow(tuesday))).single;
  }

  test('ajouter une tâche programme ses rappels', () async {
    await addedTask();

    expect(gateway.pending, hasLength(2));
    expect(startsOf().single.title, "C'est l'heure : Cours");
  });

  test('annuler une tâche retire ses rappels', () async {
    final task = await addedTask();

    await service.setStatus(task, TaskStatus.cancelled);

    expect(gateway.pending, isEmpty);
  });

  test('marquer une tâche faite retire ses rappels', () async {
    final task = await addedTask();

    await service.setStatus(task, TaskStatus.done);

    expect(gateway.pending, isEmpty);
  });

  test('supprimer une tâche retire ses rappels', () async {
    final task = await addedTask();

    await service.deleteTask(task);

    expect(gateway.pending, isEmpty);
  });

  test('décaler une tâche remplace ses rappels sans doublon', () async {
    final task = await addedTask();

    await service.shiftBy(task, 60);

    expect(gateway.pending, hasLength(2));
    expect(startsOf().single.instant, DateTime.utc(2026, 11, 10, 8));
    expect(gateway.cancelled, isEmpty);
  });

  test('changer de fuseau reprogramme à l\'heure locale du nouveau', () async {
    await addedTask();

    final current = await settings.current();
    await service.saveSettings(current.copyWith(timezone: 'America/New_York'));

    expect(startsOf().single.instant, DateTime.utc(2026, 11, 10, 13));
  });

  test('une reprogrammation n\'annule pas la notification de test', () async {
    gateway.pending[testNotificationId] = testNotification(clock.nowUtc());

    await addedTask();

    expect(gateway.pending, contains(testNotificationId));
  });

  test('sans alarmes exactes, les rappels restent programmés', () async {
    gateway.exact = false;

    await addedTask();

    expect(gateway.pending, hasLength(2));
    expect(gateway.exactModes, everyElement(isFalse));
  });

  test('avec alarmes exactes, le mode exact est utilisé', () async {
    await addedTask();

    expect(gateway.exactModes, everyElement(isTrue));
  });

  test('une date juste passée n\'interrompt pas la programmation', () async {
    gateway.scheduleError = ArgumentError('date passée');

    await expectLater(addedTask(), completes);
  });

  test('une erreur du système ne fait pas échouer la modification', () async {
    gateway.scheduleError = StateError('plugin indisponible');

    final task = await addedTask();

    expect(task.title, 'Cours');
  });

  test('des appels simultanés finissent sur l\'état le plus récent', () async {
    final task = await addedTask();

    final first = scheduler.rescheduleAll();
    await tasks.upsert(task.copyWith(status: TaskStatus.cancelled));
    await Future.wait([first, scheduler.rescheduleAll()]);

    expect(gateway.pending, isEmpty);
  });

  test('la migration conserve les réglages existants', () async {
    final legacy = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
              CREATE TABLE settings_entries (
                id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
                day_start TEXT NOT NULL, day_end TEXT NOT NULL,
                timezone TEXT NOT NULL,
                default_reminder_min INTEGER NOT NULL,
                morning_summary_enabled INTEGER NOT NULL,
                morning_summary_time TEXT NOT NULL,
                theme_mode TEXT NOT NULL, updated_at TEXT NOT NULL
              );
            ''');
            raw.execute('''
              INSERT INTO settings_entries VALUES (1, '06:30', '21:00',
                'Africa/Porto-Novo', 5, 1, '06:00', 'dark',
                '2026-11-09T10:00:00.000Z');
            ''');
            raw.execute('''
              CREATE TABLE tasks (
                id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL,
                date TEXT NOT NULL, start_time TEXT NOT NULL,
                end_time TEXT NOT NULL,
                category_id TEXT NOT NULL DEFAULT 'autre', notes TEXT,
                reminder_before_min INTEGER,
                status TEXT NOT NULL DEFAULT 'todo',
                shifted INTEGER NOT NULL DEFAULT 0,
                original_start_time TEXT,
                source TEXT NOT NULL DEFAULT 'manual', import_batch_id TEXT,
                created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
                deleted_at TEXT
              );
            ''');
            raw.execute('''
              INSERT INTO tasks (id, title, date, start_time, end_time,
                created_at, updated_at)
              VALUES ('ancienne', 'Cours', '2026-11-10', '08:00', '10:00',
                '2026-11-09T10:00:00.000Z', '2026-11-09T10:00:00.000Z');
            ''');
            raw.userVersion = 1;
          },
        ),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(legacy.close);
    final repository = SettingsRepository(legacy, clock);

    expect((await repository.current()).dayStart, const LocalTime(6, 30));
    expect(await repository.notificationPromptShown(), isFalse);
    expect(
      (await TaskRepository(legacy).pendingSync()).single.id,
      'ancienne',
      reason: 'les tâches existantes doivent partir au premier envoi',
    );
  });

  test(
    'la demande de permission reste marquée après un enregistrement',
    () async {
      await settings.markNotificationPromptShown();

      await settings.save(const AppSettings(defaultReminderMin: 30));

      expect(await settings.notificationPromptShown(), isTrue);
      expect((await settings.current()).defaultReminderMin, 30);
    },
  );

  test('marquer la demande fonctionne sans réglages enregistrés', () async {
    final empty = createTestDatabase();
    addTearDown(empty.close);
    final repository = SettingsRepository(empty, clock);

    await repository.markNotificationPromptShown();

    expect(await repository.notificationPromptShown(), isTrue);
  });
}
