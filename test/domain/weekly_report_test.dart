import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/device_preferences.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

const _sunday = LocalDate(2026, 11, 15);

List<PlannedNotification> _weekly(
  List<Task> tasks, {
  DevicePreferences device = const DevicePreferences(),
}) => planNotifications(
  tasks: tasks,
  settings: const AppSettings(morningSummaryEnabled: false),
  clock: FakeClock.porto(tuesday, 6),
  device: device,
).where((n) => n.kind == NotificationKind.weeklyReport).toList();

void main() {
  setUpAll(initAppFormats);

  test('le dimanche, 5 minutes après le rapport du soir', () {
    final report = _weekly([
      makeTask(id: 'a', date: monday, status: TaskStatus.done),
      makeTask(id: 'b', date: _sunday),
    ]).single;
    // Dimanche 22h05 à Porto-Novo : 21h05 UTC.
    expect(report.instant, DateTime.utc(2026, 11, 15, 21, 5));
    expect(report.payload, reportPayload);
    expect(report.taskId, isNull);
  });

  test('chiffres arrêtés au dimanche soir, point fort cité', () {
    final report = _weekly([
      makeTask(
        id: 'a',
        date: monday,
        start: '07:00',
        end: '10:00',
        category: TaskCategory.activite,
        status: TaskStatus.done,
      ),
      makeTask(id: 'b', date: wednesday),
      makeTask(id: 'c', date: _sunday, status: TaskStatus.done),
    ]).single;
    expect(report.body, contains('2 missions sur 3 (67 %)'));
    expect(report.body, contains('Point fort : activité'));
  });

  test('semaine sans tâche ou réglage désactivé : rien', () {
    expect(_weekly(const []), isEmpty);
    expect(
      _weekly([
        makeTask(),
      ], device: const DevicePreferences(weeklyReportEnabled: false)),
      isEmpty,
    );
  });

  test('le résumé du matin ouvre Aujourd\'hui', () {
    final summary = planNotifications(
      tasks: [makeTask()],
      settings: const AppSettings(),
      clock: FakeClock.porto(tuesday, 6),
    ).firstWhere((n) => n.kind == NotificationKind.morningSummary);
    expect(summary.payload, briefingPayload);
  });
}
