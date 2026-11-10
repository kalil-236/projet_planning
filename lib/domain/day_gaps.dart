import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'local_time.dart';
import 'task.dart';

/// Durée minimale d'un créneau libre affiché.
const minFreeSlotMinutes = 30;

/// Les créneaux commencent sur un multiple de 5 minutes.
const _slotStep = 5;

@immutable
class FreeSlot {
  const FreeSlot(this.start, this.end);

  final LocalTime start;
  final LocalTime end;

  int get minutes => end.minutesSinceMidnight - start.minutesSinceMidnight;

  @override
  bool operator ==(Object other) =>
      other is FreeSlot && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'FreeSlot($start-$end)';
}

/// Une tâche annulée ou supprimée libère sa place ; une tâche faite l'occupe.
bool _occupies(Task task) =>
    task.deletedAt == null &&
    task.status != TaskStatus.cancelled &&
    task.status != TaskStatus.missed;

/// Trous d'au moins [minMinutes] entre [dayStart] et [dayEnd], à partir de
/// [from] (l'heure actuelle pour aujourd'hui) arrondie aux 5 minutes.
List<FreeSlot> freeSlots({
  required List<Task> tasks,
  required LocalTime dayStart,
  required LocalTime dayEnd,
  LocalTime? from,
  int minMinutes = minFreeSlotMinutes,
}) {
  var cursor = dayStart.minutesSinceMidnight;
  if (from != null) {
    final rounded =
        (from.minutesSinceMidnight + _slotStep - 1) ~/ _slotStep * _slotStep;
    cursor = math.max(cursor, rounded);
  }
  final end = dayEnd.minutesSinceMidnight;
  final busy = tasks.where(_occupies).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  final slots = <FreeSlot>[];
  void addSlot(int slotStart, int slotEnd) {
    if (slotEnd - slotStart >= minMinutes) {
      slots.add(
        FreeSlot(
          LocalTime.fromMinutes(slotStart),
          LocalTime.fromMinutes(slotEnd),
        ),
      );
    }
  }

  for (final task in busy) {
    if (cursor >= end) break;
    final taskStart = task.start.minutesSinceMidnight;
    addSlot(cursor, math.min(taskStart, end));
    cursor = math.max(cursor, task.end.minutesSinceMidnight);
  }
  if (cursor < end) addSlot(cursor, end);
  return slots;
}

/// Identifiants des tâches à faire qui en chevauchent une autre à faire.
Set<String> overlappingTaskIds(List<Task> tasks) {
  final active =
      tasks
          .where((t) => t.deletedAt == null && t.status == TaskStatus.todo)
          .toList()
        ..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.start.compareTo(b.start);
        });
  final result = <String>{};
  for (var i = 0; i < active.length; i++) {
    for (var j = i + 1; j < active.length; j++) {
      final a = active[i];
      final b = active[j];
      if (a.date != b.date || !b.start.isBefore(a.end)) break;
      result
        ..add(a.id)
        ..add(b.id);
    }
  }
  return result;
}
