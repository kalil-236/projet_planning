import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/insights.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/plan_prompt.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

/// Tâche d'étude de 14h à 15h, cochée à [checkedAt] (heure de Porto-Novo).
Task studyDone(int index, String checkedAt, {LocalDate? date}) {
  final day = date ?? tuesday.addDays(-index - 1);
  final time = LocalTime.parse(checkedAt);
  return makeTask(
    id: 'e$index',
    date: day,
    start: '14:00',
    end: '15:00',
    category: TaskCategory.etude,
    status: TaskStatus.done,
  ).copyWith(
    completedAt: DateTime.utc(
      day.year,
      day.month,
      day.day,
      time.hour - 1,
      time.minute,
    ),
  );
}

List<Insight> insightsOf(List<Task> tasks) => computeInsights(
  tasks: tasks,
  today: tuesday,
  now: const LocalTime(12, 0),
  timezone: 'Africa/Porto-Novo',
);

void main() {
  setUpAll(initAppFormats);

  test('débordement moyen par catégorie', () {
    final insights = insightsOf([
      studyDone(0, '15:20'),
      studyDone(1, '15:10'),
      studyDone(2, '15:30'),
    ]);
    final overrun = insights.singleWhere((i) => i.kind == InsightKind.overrun);
    expect(overrun.message, contains("Sessions d'étude"));
    expect(overrun.message, contains('20 min'));
    expect(overrun.promptLine, contains('prévois-les plus longues'));
  });

  test('fini en avance : propose de raccourcir', () {
    final insights = insightsOf([
      studyDone(0, '14:40'),
      studyDone(1, '14:45'),
      studyDone(2, '14:35'),
    ]);
    expect(insights.single.kind, InsightKind.underrun);
    expect(insights.single.message, contains('20 min avant'));
  });

  test('cochée après coup ou trop peu de mesures : rien', () {
    expect(
      insightsOf([
        studyDone(0, '15:20'),
        studyDone(1, '15:20'),
        studyDone(2, '21:00'),
      ]).where((i) => i.kind == InsightKind.overrun),
      isEmpty,
    );
  });

  test('matin efficace, soir difficile', () {
    final tasks = <Task>[
      for (var i = 0; i < 6; i++)
        makeTask(
          id: 'm$i',
          date: tuesday.addDays(-i - 1),
          start: '08:00',
          end: '09:00',
          status: TaskStatus.done,
        ),
      for (var i = 0; i < 6; i++)
        makeTask(
          id: 's$i',
          date: tuesday.addDays(-i - 1),
          start: '20:00',
          end: '21:00',
          status: i == 0 ? TaskStatus.done : TaskStatus.todo,
        ),
    ];
    final insight = insightsOf(tasks)
        .singleWhere((i) => i.kind == InsightKind.timeOfDay);
    expect(insight.message, contains('100 %'));
    expect(insight.message, contains('17 % le soir'));
  });

  test('catégorie délaissée', () {
    final tasks = [
      for (var i = 0; i < 5; i++)
        makeTask(
          id: 'a$i',
          date: tuesday.addDays(-i - 1),
          category: TaskCategory.activite,
          status: i == 0 ? TaskStatus.done : TaskStatus.todo,
        ),
    ];
    final insight = insightsOf(tasks)
        .singleWhere((i) => i.kind == InsightKind.neglected);
    expect(insight.message, contains('activités'));
    expect(insight.message, contains('20 %'));
  });

  test('historique hors des 4 dernières semaines ignoré', () {
    expect(
      insightsOf([
        for (var i = 0; i < 3; i++)
          studyDone(i, '15:30', date: tuesday.addDays(-40 - i)),
      ]),
      isEmpty,
    );
  });

  test('les observations rejoignent le prompt', () {
    final prompt = buildPlanPrompt(
      today: tuesday,
      settings: const AppSettings(),
      insights: insightsOf([
        studyDone(0, '15:20'),
        studyDone(1, '15:10'),
        studyDone(2, '15:30'),
      ]),
    );
    expect(prompt, contains('Observations de mon application'));
    expect(prompt, contains("- Mes sessions d'étude débordent"));
    expect(
      buildPlanPrompt(today: tuesday, settings: const AppSettings()),
      isNot(contains('Observations')),
    );
  });
}
