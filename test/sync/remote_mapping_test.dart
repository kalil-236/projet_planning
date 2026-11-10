import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/sync/remote_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  Map<String, dynamic> serverRow(Task task) => {
    ...taskToRow(task),
    'start_time': '${task.start.toHHmm()}:00',
    'end_time': '${task.end.toHHmm()}:00',
    'updated_at': '2026-11-10T07:00:00.123456+00:00',
    'synced_at': '2026-11-10T07:00:01.5+00:00',
  };

  test('une tâche survit à l\'aller-retour et aux heures de Postgres', () {
    final task = makeTask(
      title: 'Cours',
      status: TaskStatus.cancelled,
      source: TaskSource.import,
      shifted: true,
      originalStart: '07:30',
    ).copyWith(notes: 'Salle 2', reminderBeforeMin: 15);

    final remote = remoteTaskFromRow(serverRow(task));

    expect(remote.task.title, 'Cours');
    expect(remote.task.start, const LocalTime(8, 0));
    expect(remote.task.end, const LocalTime(10, 0));
    expect(remote.task.status, TaskStatus.cancelled);
    expect(remote.task.source, TaskSource.import);
    expect(remote.task.shifted, isTrue);
    expect(remote.task.originalStart, const LocalTime(7, 30));
    expect(remote.task.notes, 'Salle 2');
    expect(remote.task.reminderBeforeMin, 15);
    expect(remote.task.date, tuesday);
  });

  test('les instants du serveur sont lus en UTC', () {
    final remote = remoteTaskFromRow(serverRow(makeTask()));

    expect(remote.task.updatedAt.isUtc, isTrue);
    expect(remote.task.updatedAt.hour, 7);
    expect(remote.syncedAt, DateTime.utc(2026, 11, 10, 7, 0, 1, 500));
  });

  test('une suppression logique est transmise', () {
    final deleted = makeTask().copyWith(deletedAt: fixedInstant);

    expect(remoteTaskFromRow(serverRow(deleted)).task.deletedAt, fixedInstant);
    expect(taskToRow(makeTask())['deleted_at'], isNull);
  });

  test('user_id et synced_at restent à la charge du serveur', () {
    final row = taskToRow(makeTask());

    expect(row.containsKey('user_id'), isFalse);
    expect(row.containsKey('synced_at'), isFalse);
  });

  test('les réglages survivent à l\'aller-retour', () {
    const settings = AppSettings(
      dayStart: LocalTime(6, 30),
      defaultReminderMin: 5,
      morningSummaryEnabled: false,
      themeMode: AppThemeMode.dark,
    );
    final row = <String, dynamic>{
      ...settingsToRow(settings, fixedInstant),
      'day_start': '06:30:00',
      'day_end': '22:00:00',
      'morning_summary_time': '07:00:00',
    };

    final remote = remoteSettingsFromRow(row);

    expect(remote.settings, settings);
    expect(remote.updatedAt, fixedInstant);
  });
}
