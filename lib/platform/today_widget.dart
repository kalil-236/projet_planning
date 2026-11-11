import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../domain/local_date.dart';
import '../domain/task.dart';

/// Données du widget d'accueil, transmises à `TodayWidgetProvider.kt`.
abstract interface class TodayWidgetPublisher {
  Future<void> publish({
    required List<Task> tasks,
    required LocalDate today,
    required String timezone,
  });
}

/// Tâches à faire d'aujourd'hui et de demain, heures en minutes depuis minuit.
/// Le widget choisit lui-même la tâche en cours ou la suivante.
String todayWidgetJson({
  required List<Task> tasks,
  required LocalDate today,
  required String timezone,
}) {
  Map<String, Object> day(LocalDate date) {
    final dayTasks =
        tasks
            .where(
              (t) =>
                  t.date == date &&
                  t.deletedAt == null &&
                  t.status == TaskStatus.todo,
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    return {
      'date': date.toIso(),
      'tasks': [
        for (final task in dayTasks)
          {
            'title': task.title,
            'start': task.start.minutesSinceMidnight,
            'end': task.end.minutesSinceMidnight,
          },
      ],
    };
  }

  return jsonEncode({
    'tz': timezone,
    'days': [day(today), day(today.addDays(1))],
  });
}

class AndroidTodayWidgetPublisher implements TodayWidgetPublisher {
  const AndroidTodayWidgetPublisher();

  static const _provider =
      'com.kalil236.assistant_planning.TodayWidgetProvider';

  @override
  Future<void> publish({
    required List<Task> tasks,
    required LocalDate today,
    required String timezone,
  }) async {
    await HomeWidget.saveWidgetData<String>(
      'plan',
      todayWidgetJson(tasks: tasks, today: today, timezone: timezone),
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
  }
}
