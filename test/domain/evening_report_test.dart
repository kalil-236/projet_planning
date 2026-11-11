import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/device_preferences.dart';
import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

const _settings = AppSettings(morningSummaryEnabled: false);

List<PlannedNotification> _reports(
  List<Task> tasks, {
  DevicePreferences device = const DevicePreferences(),
}) => planNotifications(
  tasks: tasks,
  settings: _settings,
  clock: FakeClock.porto(tuesday, 6),
  device: device,
).where((n) => n.kind == NotificationKind.eveningReport).toList();

void main() {
  setUpAll(initAppFormats);

  test('un rapport par jour qui a des tâches, à la fin de journée', () {
    final reports = _reports([
      makeTask(id: 'a', title: 'Cours'),
      makeTask(id: 'b', title: 'Sport', date: wednesday),
    ]);
    expect(reports, hasLength(2));
    // 22h à Porto-Novo : 21h UTC.
    expect(reports.first.instant, DateTime.utc(2026, 11, 10, 21));
    expect(reports.first.reportDate, tuesday);
  });

  test('cite les tâches restantes et propose le report', () {
    final report = _reports([
      makeTask(id: 'a', title: 'Cours', status: TaskStatus.done),
      makeTask(id: 'b', title: 'Sport', start: '17:00', end: '18:00'),
      makeTask(id: 'c', title: 'Lecture', start: '20:00', end: '21:00'),
      makeTask(
        id: 'd',
        title: 'Annulée',
        start: '12:00',
        end: '13:00',
        status: TaskStatus.cancelled,
      ),
    ]).single;
    expect(report.body, contains('1 sur 3'));
    expect(report.body, contains('Restent : Sport, Lecture.'));
    expect(report.body, isNot(contains('Annulée')));
    expect(report.reportDate, tuesday);
  });

  test('tout est fait : félicitations, rien à reporter', () {
    final report = _reports([makeTask(status: TaskStatus.done)]).single;
    expect(report.reportDate, isNull);
    expect(report.body, isNot(contains('Reste')));
  });

  test('après la dernière tâche si elle finit après la fin de journée', () {
    final report = _reports([makeTask(start: '21:30', end: '23:15')]).single;
    expect(report.instant, DateTime.utc(2026, 11, 10, 22, 15));
  });

  test('jour sans tâche, ou réglage désactivé : aucun rapport', () {
    expect(_reports([makeTask(status: TaskStatus.cancelled)]), isEmpty);
    expect(
      _reports([
        makeTask(),
      ], device: const DevicePreferences(eveningReportEnabled: false)),
      isEmpty,
    );
  });

  test('beaucoup de tâches restantes : texte borné', () {
    final remaining = [
      for (var i = 0; i < 9; i++)
        makeTask(id: 't$i', title: 'Tâche numéro $i avec un titre long'),
    ];
    final body = eveningReportBody(0, 9, remaining);
    expect(body, contains('et 5 autres'));
    expect(body.length, lessThanOrEqualTo(300));
  });
}
