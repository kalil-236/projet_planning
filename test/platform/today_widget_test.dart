import 'dart:convert';

import 'package:assistant_planning/data/settings_repository.dart';
import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/notifications/reminder_scheduler.dart';
import 'package:assistant_planning/platform/today_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

class _RecordingPublisher implements TodayWidgetPublisher {
  final calls = <String>[];

  @override
  Future<void> publish({
    required List<Task> tasks,
    required LocalDate today,
    required String timezone,
  }) async {
    calls.add(todayWidgetJson(tasks: tasks, today: today, timezone: timezone));
  }
}

void main() {
  setUpAll(initAppFormats);

  test("aujourd'hui et demain, tâches à faire seulement, dans l'ordre", () {
    final json = jsonDecode(
      todayWidgetJson(
        tasks: [
          makeTask(id: 'b', title: 'Sport', start: '17:00', end: '18:00'),
          makeTask(id: 'a', title: 'Cours', start: '08:00', end: '10:30'),
          makeTask(id: 'c', title: 'Faite', status: TaskStatus.done),
          makeTask(id: 'd', title: 'Demain', date: wednesday),
          makeTask(id: 'e', title: 'Plus tard', date: wednesday.addDays(1)),
        ],
        today: tuesday,
        timezone: 'Africa/Porto-Novo',
      ),
    ) as Map<String, dynamic>;
    expect(json['tz'], 'Africa/Porto-Novo');
    final days = json['days'] as List<dynamic>;
    expect(days, hasLength(2));
    final today = days.first as Map<String, dynamic>;
    expect(today['date'], '2026-11-10');
    expect(today['tasks'], [
      {'title': 'Cours', 'start': 480, 'end': 630},
      {'title': 'Sport', 'start': 1020, 'end': 1080},
    ]);
    expect((days.last as Map<String, dynamic>)['tasks'], hasLength(1));
  });

  test('chaque reprogrammation met le widget à jour', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final clock = FakeClock.porto(tuesday, 7);
    final tasks = TaskRepository(db);
    await tasks.upsert(makeTask(title: 'Cours'));
    final publisher = _RecordingPublisher();
    await LocalReminderScheduler(
      tasks: tasks,
      settings: SettingsRepository(db, clock),
      clock: clock,
      gateway: FakeNotificationGateway(),
      widget: publisher,
    ).rescheduleAll();
    expect(publisher.calls.single, contains('"title":"Cours"'));
  });
}
