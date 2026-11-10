import 'package:flutter/foundation.dart';

import '../core/french_format.dart';
import 'local_date.dart';
import 'local_time.dart';
import 'task.dart';

Task? _moved(Task task, LocalTime newStart, DateTime nowUtc) {
  final duration =
      task.end.minutesSinceMidnight - task.start.minutesSinceMidnight;
  final newEnd = newStart.plusMinutes(duration);
  if (newEnd == null) return null;
  return task.copyWith(
    start: newStart,
    end: newEnd,
    shifted: true,
    originalStart: task.originalStart ?? task.start,
    updatedAt: nowUtc,
  );
}

/// Renvoie `null` si la tâche sortirait de la journée.
Task? shiftTaskBy(Task task, int minutes, DateTime nowUtc) {
  final newStart = task.start.plusMinutes(minutes);
  return newStart == null ? null : _moved(task, newStart, nowUtc);
}

/// Renvoie `null` si la tâche sortirait de la journée.
Task? shiftTaskTo(Task task, LocalTime newStart, DateTime nowUtc) =>
    _moved(task, newStart, nowUtc);

/// Résultat prévu de « Décaler toute la journée ».
@immutable
class DayShiftPlan {
  const DayShiftPlan({
    required this.shifted,
    required this.blockedByMidnight,
    required this.latestEnd,
    required this.exceedsDayEnd,
  });

  final List<Task> shifted;

  /// Tâches qui traverseraient minuit : le décalage est alors refusé.
  final List<Task> blockedByMidnight;
  final LocalTime? latestEnd;
  final bool exceedsDayEnd;

  bool get canApply => shifted.isNotEmpty && blockedByMidnight.isEmpty;
}

/// Prévoit le décalage des tâches `todo` du jour qui ne sont pas terminées.
DayShiftPlan planDayShift({
  required List<Task> tasks,
  required LocalDateTime now,
  required int minutes,
  required LocalTime dayEnd,
  required DateTime nowUtc,
}) {
  final shifted = <Task>[];
  final blocked = <Task>[];
  for (final task in tasks) {
    if (task.date != now.date ||
        task.status != TaskStatus.todo ||
        task.deletedAt != null ||
        !task.end.isAfter(now.time)) {
      continue;
    }
    final moved = shiftTaskBy(task, minutes, nowUtc);
    if (moved == null) {
      blocked.add(task);
    } else {
      shifted.add(moved);
    }
  }

  LocalTime? latestEnd;
  for (final task in shifted) {
    if (latestEnd == null || task.end.isAfter(latestEnd)) latestEnd = task.end;
  }
  return DayShiftPlan(
    shifted: shifted,
    blockedByMidnight: blocked,
    latestEnd: latestEnd,
    exceedsDayEnd: latestEnd != null && latestEnd.isAfter(dayEnd),
  );
}

/// Tâches affichées dans « Aujourd'hui », jamais les tâches `missed`.
List<Task> tasksForToday(List<Task> tasks, LocalDate today) => tasks
    .where(
      (t) =>
          t.date == today &&
          t.deletedAt == null &&
          t.status != TaskStatus.missed,
    )
    .toList();

/// Ligne de résumé : « 3 tâches restantes, prochaine à 14h ».
String daySummary(List<Task> todayTasks, LocalTime now) {
  final remaining = todayTasks
      .where((t) => t.status == TaskStatus.todo && t.end.isAfter(now))
      .toList();
  if (remaining.isEmpty) return 'Aucune tâche restante';

  final count = remaining.length;
  final label = count == 1 ? '1 tâche restante' : '$count tâches restantes';
  final upcoming = remaining.where((t) => t.start.isAfter(now)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (upcoming.isEmpty) return label;
  return '$label, prochaine à ${formatHour(upcoming.first.start)}';
}
