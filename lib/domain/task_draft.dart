import 'package:flutter/foundation.dart';

import 'category.dart';
import 'local_date.dart';
import 'local_time.dart';

/// Tâche pas encore créée : préremplit le formulaire d'ajout.
@immutable
class TaskDraft {
  const TaskDraft({
    required this.date,
    required this.start,
    required this.end,
    this.title = '',
    this.category = TaskCategory.autre,
  });

  final String title;
  final LocalDate date;
  final LocalTime start;
  final LocalTime end;
  final TaskCategory category;

  @override
  bool operator ==(Object other) =>
      other is TaskDraft &&
      other.title == title &&
      other.date == date &&
      other.start == start &&
      other.end == end &&
      other.category == category;

  @override
  int get hashCode => Object.hash(title, date, start, end, category);

  @override
  String toString() => 'TaskDraft($title, $date, $start-$end, $category)';
}
