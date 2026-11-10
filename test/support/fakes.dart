import 'package:assistant_planning/core/clock.dart';
import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/task.dart';

/// Lundi 2026-11-09 : le mardi de référence de la spécification est le 10.
const monday = LocalDate(2026, 11, 9);
const tuesday = LocalDate(2026, 11, 10);
const wednesday = LocalDate(2026, 11, 11);

class FakeClock implements Clock {
  FakeClock(this._now);

  /// Heure locale à Porto-Novo (UTC+1).
  factory FakeClock.porto(LocalDate date, int hour, [int minute = 0]) =>
      FakeClock(
        DateTime.utc(date.year, date.month, date.day, hour - 1, minute),
      );

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

final fixedInstant = DateTime.utc(2026, 11, 10, 7);

Task makeTask({
  String id = 't1',
  String title = 'Tâche',
  LocalDate date = tuesday,
  String start = '08:00',
  String end = '10:00',
  TaskStatus status = TaskStatus.todo,
  TaskSource source = TaskSource.manual,
  bool shifted = false,
  String? originalStart,
  TaskCategory category = TaskCategory.autre,
}) {
  return Task(
    id: id,
    title: title,
    date: date,
    start: LocalTime.parse(start),
    end: LocalTime.parse(end),
    category: category,
    status: status,
    source: source,
    shifted: shifted,
    originalStart: originalStart == null
        ? null
        : LocalTime.parse(originalStart),
    createdAt: fixedInstant,
    updatedAt: fixedInstant,
  );
}
