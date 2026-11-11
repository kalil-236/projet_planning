import 'package:assistant_planning/data/database.dart';
import 'package:assistant_planning/data/planning_service.dart';
import 'package:assistant_planning/data/settings_repository.dart';
import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/notifications/notification_actions.dart';
import 'package:assistant_planning/notifications/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(initAppFormats);

  late AppDatabase db;
  late TaskRepository tasks;
  late FakeNotificationGateway gateway;
  late PlanningService service;

  setUp(() async {
    db = createTestDatabase();
    tasks = TaskRepository(db);
    gateway = FakeNotificationGateway();
    final clock = FakeClock.porto(tuesday, 7);
    final settings = SettingsRepository(db, clock);
    await settings.save(const AppSettings(morningSummaryEnabled: false));
    service = PlanningService(
      tasks: tasks,
      settings: settings,
      clock: clock,
      scheduler: LocalReminderScheduler(
        tasks: tasks,
        settings: settings,
        clock: clock,
        gateway: gateway,
      ),
    );
    await tasks.upsert(makeTask(title: 'Cours'));
  });

  tearDown(() => db.close());

  Future<bool> act(String actionId, {String taskId = 't1'}) =>
      applyNotificationAction(
        actionId: actionId,
        payload: taskId,
        tasks: tasks,
        service: service,
      );

  test('« Fait » termine la tâche et retire ses rappels', () async {
    expect(await act(doneActionId), isTrue);

    expect((await tasks.byId('t1'))!.status, TaskStatus.done);
    expect(
      gateway.pending.values.where((n) => n.taskId != null),
      isEmpty,
      reason: 'seul le rapport du soir reste programmé',
    );
  });

  test('« Décaler 15 min » déplace la tâche et ses rappels', () async {
    expect(await act(shiftActionId), isTrue);

    final task = (await tasks.byId('t1'))!;
    expect(task.start, const LocalTime(8, 15));
    expect(task.end, const LocalTime(10, 15));
    expect(task.shifted, isTrue);
    final start = gateway.pending.values.singleWhere(
      (n) => n.kind == NotificationKind.start,
    );
    expect(start.instant, DateTime.utc(2026, 11, 10, 7, 15));
  });

  test('la modification attend la prochaine synchronisation', () async {
    await act(doneActionId);

    expect((await tasks.pendingSync()).single.status, TaskStatus.done);
  });

  test('une tâche déjà traitée n\'est pas modifiée', () async {
    await tasks.upsert(makeTask(title: 'Cours', status: TaskStatus.cancelled));

    expect(await act(doneActionId), isFalse);
    expect((await tasks.byId('t1'))!.status, TaskStatus.cancelled);
  });

  test('une tâche supprimée ou inconnue est ignorée', () async {
    await tasks.softDelete('t1', fixedInstant);

    expect(await act(doneActionId), isFalse);
    expect(await act(doneActionId, taskId: 'inconnue'), isFalse);
  });

  test('un décalage qui passerait minuit est refusé', () async {
    await tasks.upsert(makeTask(start: '23:00', end: '23:50'));

    expect(await act(shiftActionId), isFalse);
    expect((await tasks.byId('t1'))!.start, const LocalTime(23, 0));
  });

  test('« Reporter à demain » du rapport du soir', () async {
    expect(await act(postponeActionId, taskId: dayPayload(tuesday)), isTrue);
    expect((await tasks.byId('t1'))!.date, wednesday);
    expect(await act(postponeActionId, taskId: dayPayload(tuesday)), isFalse);
    expect(await act(postponeActionId, taskId: 'jour:pas-une-date'), isFalse);
  });

  test('le rapport du soir porte le jour à reporter', () async {
    await service.setStatus((await tasks.byId('t1'))!, TaskStatus.todo);
    final report = gateway.pending.values.singleWhere(
      (n) => n.kind == NotificationKind.eveningReport,
    );
    expect(report.reportDate, tuesday);
  });

  test('un bouton inconnu est ignoré', () async {
    expect(await act('autre'), isFalse);
    expect((await tasks.byId('t1'))!.status, TaskStatus.todo);
  });

  test('seuls les rappels de tâche portent la tâche visée', () {
    final plan = planNotifications(
      tasks: [makeTask(title: 'Cours')],
      settings: const AppSettings(),
      clock: FakeClock.porto(tuesday, 6),
    );

    for (final notification in plan) {
      expect(notification.taskId, switch (notification.kind) {
        NotificationKind.morningSummary ||
        NotificationKind.eveningReport => isNull,
        _ => 't1',
      }, reason: notification.kind.name);
    }
  });
}
