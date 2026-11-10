import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../domain/local_time.dart';
import '../../domain/task.dart';

/// Échelle verticale d'une frise, calée sur des heures pleines.
@immutable
class TimelineScale {
  const TimelineScale._(this.startMinutes, this.endMinutes);

  /// Couvre la journée configurée, élargie aux tâches qui en sortent.
  factory TimelineScale.covering({
    required LocalTime dayStart,
    required LocalTime dayEnd,
    required Iterable<Task> tasks,
  }) {
    var start = dayStart.minutesSinceMidnight;
    var end = dayEnd.minutesSinceMidnight;
    for (final task in tasks) {
      start = math.min(start, task.start.minutesSinceMidnight);
      end = math.max(end, task.end.minutesSinceMidnight);
    }
    return TimelineScale._(
      start - start % 60,
      math.min((end + 59) - (end + 59) % 60, LocalTime.minutesPerDay),
    );
  }

  static const pixelsPerMinute = 1.4;

  final int startMinutes;
  final int endMinutes;

  double get height => (endMinutes - startMinutes) * pixelsPerMinute;

  double yOf(LocalTime time) =>
      (time.minutesSinceMidnight - startMinutes) * pixelsPerMinute;

  bool contains(LocalTime time) {
    final minutes = time.minutesSinceMidnight;
    return minutes >= startMinutes && minutes <= endMinutes;
  }

  /// Heures pleines de la frise, en minutes depuis minuit.
  Iterable<int> get hours sync* {
    for (var m = startMinutes; m <= endMinutes; m += 60) {
      yield m;
    }
  }

  double yOfMinutes(int minutes) => (minutes - startMinutes) * pixelsPerMinute;
}

/// Position d'un bloc : les tâches qui se recouvrent sont côte à côte.
@immutable
class TimelineItem {
  const TimelineItem({
    required this.task,
    required this.top,
    required this.height,
    required this.column,
    required this.columnCount,
  });

  final Task task;
  final double top;
  final double height;
  final int column;
  final int columnCount;
}

class _Placed {
  _Placed(this.task, this.top, this.height, this.column);

  final Task task;
  final double top;
  final double height;
  final int column;

  double get bottom => top + height;
}

List<TimelineItem> layoutTimeline({
  required List<Task> tasks,
  required TimelineScale scale,
  required double minHeight,
}) {
  final sorted = [...tasks]
    ..sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.end.compareTo(b.end);
    });

  final result = <TimelineItem>[];
  var cluster = <_Placed>[];
  var clusterBottom = double.negativeInfinity;

  void closeCluster() {
    final count = cluster.fold<int>(
      0,
      (max, item) => math.max(max, item.column + 1),
    );
    for (final item in cluster) {
      result.add(
        TimelineItem(
          task: item.task,
          top: item.top,
          height: item.height,
          column: item.column,
          columnCount: count,
        ),
      );
    }
    cluster = [];
  }

  for (final task in sorted) {
    final top = scale.yOf(task.start);
    final height = math.max(scale.yOf(task.end) - top, minHeight);
    if (top >= clusterBottom) closeCluster();

    var column = 0;
    while (cluster.any((p) => p.column == column && p.bottom > top)) {
      column++;
    }
    final placed = _Placed(task, top, height, column);
    cluster.add(placed);
    clusterBottom = math.max(
      cluster.length == 1 ? placed.bottom : clusterBottom,
      placed.bottom,
    );
  }
  closeCluster();
  return result;
}
