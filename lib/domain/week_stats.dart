import 'package:flutter/foundation.dart';

import 'category.dart';
import 'local_date.dart';
import 'local_time.dart';
import 'task.dart';

/// Une journée est « réussie » à partir de ce taux de tâches faites.
const successfulDayRate = 0.8;

/// Chiffres d'un jour. Une tâche est « due » quand elle est faite, ou à faire
/// et déjà terminée : le taux ne pénalise pas ce qui n'a pas encore eu lieu.
@immutable
class DayStats {
  const DayStats({
    required this.date,
    required this.done,
    required this.missed,
    required this.upcoming,
  });

  final LocalDate date;
  final int done;

  /// À faire, mais l'heure de fin est passée.
  final int missed;

  /// À faire, pas encore terminée.
  final int upcoming;

  int get due => done + missed;
  int get total => done + missed + upcoming;

  /// `null` tant qu'aucune tâche n'est due.
  double? get rate => due == 0 ? null : done / due;

  bool get successful => rate != null && rate! >= successfulDayRate;
}

@immutable
class CategoryStats {
  const CategoryStats({
    required this.category,
    required this.plannedMinutes,
    required this.doneMinutes,
  });

  final TaskCategory category;
  final int plannedMinutes;
  final int doneMinutes;
}

@immutable
class WeekStats {
  const WeekStats({
    required this.monday,
    required this.days,
    required this.categories,
    required this.plannedMinutes,
    required this.doneMinutes,
  });

  final LocalDate monday;

  /// Du lundi au dimanche.
  final List<DayStats> days;

  /// Catégories qui ont au moins une tâche, par temps prévu décroissant.
  final List<CategoryStats> categories;
  final int plannedMinutes;
  final int doneMinutes;

  int get done => days.fold(0, (sum, day) => sum + day.done);
  int get due => days.fold(0, (sum, day) => sum + day.due);
  int get total => days.fold(0, (sum, day) => sum + day.total);
  int get upcoming => days.fold(0, (sum, day) => sum + day.upcoming);
  double? get rate => due == 0 ? null : done / due;
  bool get isEmpty => total == 0;
}

int _minutes(Task task) =>
    task.end.minutesSinceMidnight - task.start.minutesSinceMidnight;

/// Tâches comptées : ni supprimées, ni annulées.
bool _counts(Task task) =>
    task.deletedAt == null && task.status != TaskStatus.cancelled;

bool _ended(Task task, LocalDate today, LocalTime now) =>
    task.date.isBefore(today) || (task.date == today && !task.end.isAfter(now));

DayStats dayStats(
  LocalDate date,
  Iterable<Task> tasks,
  LocalDate today,
  LocalTime now,
) {
  var done = 0;
  var missed = 0;
  var upcoming = 0;
  for (final task in tasks) {
    if (task.date != date || !_counts(task)) continue;
    if (task.status == TaskStatus.done) {
      done++;
    } else if (task.status == TaskStatus.missed || _ended(task, today, now)) {
      missed++;
    } else {
      upcoming++;
    }
  }
  return DayStats(date: date, done: done, missed: missed, upcoming: upcoming);
}

WeekStats weekStats({
  required List<Task> tasks,
  required LocalDate monday,
  required LocalDate today,
  required LocalTime now,
}) {
  final days = [
    for (var i = 0; i < 7; i++) dayStats(monday.addDays(i), tasks, today, now),
  ];
  final week = DateRange(monday, monday.addDays(6));
  final planned = <TaskCategory, int>{};
  final done = <TaskCategory, int>{};
  for (final task in tasks) {
    if (!week.contains(task.date) || !_counts(task)) continue;
    planned.update(
      task.category,
      (v) => v + _minutes(task),
      ifAbsent: () => _minutes(task),
    );
    if (task.status == TaskStatus.done) {
      done.update(
        task.category,
        (v) => v + _minutes(task),
        ifAbsent: () => _minutes(task),
      );
    }
  }
  final categories = [
    for (final entry in planned.entries)
      CategoryStats(
        category: entry.key,
        plannedMinutes: entry.value,
        doneMinutes: done[entry.key] ?? 0,
      ),
  ]..sort((a, b) => b.plannedMinutes.compareTo(a.plannedMinutes));
  return WeekStats(
    monday: monday,
    days: days,
    categories: categories,
    plannedMinutes: planned.values.fold(0, (a, b) => a + b),
    doneMinutes: done.values.fold(0, (a, b) => a + b),
  );
}

/// Jours réussis d'affilée, en remontant depuis aujourd'hui (si aujourd'hui
/// n'a encore rien de dû, la série part d'hier). Un jour sans tâche due ne
/// casse pas la série, il est sauté.
int successStreak({
  required List<Task> tasks,
  required LocalDate today,
  required LocalTime now,
  int maxDays = 60,
}) {
  var streak = 0;
  for (var i = 0; i < maxDays; i++) {
    final day = dayStats(today.addDays(-i), tasks, today, now);
    if (day.due == 0) continue;
    if (!day.successful) {
      // Aujourd'hui n'est pas encore fini : il ne casse pas la série.
      if (i == 0 && day.upcoming > 0) continue;
      break;
    }
    streak++;
  }
  return streak;
}
