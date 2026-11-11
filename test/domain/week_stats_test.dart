import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/domain/week_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  const noon = LocalTime(12, 0);

  test('faites, manquées et à venir ; taux sur les tâches dues', () {
    final stats = weekStats(
      tasks: [
        makeTask(id: 'a', date: monday, status: TaskStatus.done),
        makeTask(id: 'b', date: monday),
        makeTask(id: 'c', status: TaskStatus.done),
        makeTask(id: 'd', start: '14:00', end: '15:00'),
        makeTask(id: 'e', status: TaskStatus.cancelled),
        makeTask(id: 'f', date: wednesday),
      ],
      monday: monday,
      today: tuesday,
      now: noon,
    );
    expect(stats.done, 2);
    expect(stats.due, 3);
    expect(stats.upcoming, 2);
    expect(stats.rate, closeTo(2 / 3, 1e-9));
    expect(stats.days.first.missed, 1);
    expect(stats.days[1].upcoming, 1);
  });

  test('temps par catégorie, du plus prévu au moins prévu', () {
    final stats = weekStats(
      tasks: [
        makeTask(
          id: 'a',
          category: TaskCategory.etude,
          start: '08:00',
          end: '11:00',
          status: TaskStatus.done,
        ),
        makeTask(
          id: 'b',
          category: TaskCategory.activite,
          start: '17:00',
          end: '18:00',
        ),
      ],
      monday: monday,
      today: tuesday,
      now: noon,
    );
    expect(stats.categories.first.category, TaskCategory.etude);
    expect(stats.categories.first.doneMinutes, 180);
    expect(stats.categories.last.doneMinutes, 0);
    expect(stats.plannedMinutes, 240);
    expect(stats.doneMinutes, 180);
  });

  test('semaine vide', () {
    final stats = weekStats(
      tasks: const [],
      monday: monday,
      today: tuesday,
      now: noon,
    );
    expect(stats.isEmpty, isTrue);
    expect(stats.rate, isNull);
  });

  group('série de jours réussis', () {
    List<Task> day(
      LocalDate date, {
      required int done,
      required int missed,
    }) => [
      for (var i = 0; i < done; i++)
        makeTask(id: '$date-d$i', date: date, status: TaskStatus.done),
      for (var i = 0; i < missed; i++) makeTask(id: '$date-m$i', date: date),
    ];

    test("compte les jours d'affilée, saute les jours sans tâche", () {
      final tasks = [
        ...day(monday.addDays(-3), done: 1, missed: 1),
        ...day(monday.addDays(-2), done: 4, missed: 1),
        ...day(monday, done: 2, missed: 0),
        ...day(tuesday, done: 1, missed: 0),
      ];
      expect(
        successStreak(tasks: tasks, today: tuesday, now: noon),
        3,
        reason: 'dimanche sans tâche ne casse pas la série',
      );
    });

    test("aujourd'hui pas encore fini ne casse pas la série", () {
      final tasks = [
        ...day(monday, done: 1, missed: 0),
        makeTask(id: 'soir', start: '20:00', end: '21:00'),
      ];
      expect(successStreak(tasks: tasks, today: tuesday, now: noon), 1);
    });

    test('un jour raté arrête la série', () {
      final tasks = day(monday, done: 1, missed: 1);
      expect(successStreak(tasks: tasks, today: tuesday, now: noon), 0);
    });
  });
}
