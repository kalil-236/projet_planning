import 'package:flutter/foundation.dart';

import 'local_date.dart';
import 'plan_parser.dart';
import 'task.dart';

enum ImportMode { replace, merge }

/// Deux tâches du fichier qui se chevauchent (avertissement non bloquant).
@immutable
class TaskOverlap {
  const TaskOverlap(this.first, this.second);

  final ParsedTask first;
  final ParsedTask second;
}

/// Contenu de l'écran d'aperçu (section 6.5).
@immutable
class ImportPreview {
  const ImportPreview({
    required this.pastCount,
    required this.todayCount,
    required this.upcomingCount,
    required this.importableCount,
    required this.duplicates,
    required this.overlaps,
    required this.fileTimezoneMismatch,
  });

  final int pastCount;
  final int todayCount;
  final int upcomingCount;

  /// Nombre de tâches qui seront réellement importées.
  final int importableCount;
  final List<ParsedTask> duplicates;
  final List<TaskOverlap> overlaps;

  /// Fuseau du fichier s'il diffère des réglages, sinon `null`.
  final String? fileTimezoneMismatch;
}

@immutable
class ImportChanges {
  const ImportChanges({
    required this.toInsert,
    required this.toRemove,
    required this.skippedDuplicates,
  });

  final List<Task> toInsert;
  final List<Task> toRemove;
  final int skippedDuplicates;
}

String _keyOf(ParsedTask task) =>
    Task.duplicateKeyOf(task.title, task.date, task.start);

({List<ParsedTask> unique, List<ParsedTask> duplicates}) _splitDuplicates(
  List<ParsedTask> tasks,
) {
  final seen = <String>{};
  final unique = <ParsedTask>[];
  final duplicates = <ParsedTask>[];
  for (final task in tasks) {
    (seen.add(_keyOf(task)) ? unique : duplicates).add(task);
  }
  return (unique: unique, duplicates: duplicates);
}

List<ParsedTask> _retained(
  List<ParsedTask> unique,
  LocalDate today, {
  required bool fromToday,
}) => fromToday
    ? unique.where((task) => !task.date.isBefore(today)).toList()
    : unique;

List<TaskOverlap> _findOverlaps(List<ParsedTask> tasks) {
  final sorted = [...tasks]
    ..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.start.compareTo(b.start);
    });
  final overlaps = <TaskOverlap>[];
  for (var i = 0; i < sorted.length; i++) {
    for (var j = i + 1; j < sorted.length; j++) {
      final a = sorted[i];
      final b = sorted[j];
      if (a.date != b.date || !b.start.isBefore(a.end)) break;
      overlaps.add(TaskOverlap(a, b));
    }
  }
  return overlaps;
}

ImportPreview buildImportPreview({
  required ParsedPlan plan,
  required LocalDate today,
  required String settingsTimezone,
  required bool fromToday,
}) {
  final split = _splitDuplicates(plan.tasks);
  final retained = _retained(split.unique, today, fromToday: fromToday);
  final fileTimezone = plan.timezone;
  return ImportPreview(
    pastCount: split.unique.where((t) => t.date.isBefore(today)).length,
    todayCount: split.unique.where((t) => t.date == today).length,
    upcomingCount: split.unique.where((t) => t.date.isAfter(today)).length,
    importableCount: retained.length,
    duplicates: split.duplicates,
    overlaps: _findOverlaps(retained),
    fileTimezoneMismatch:
        (fileTimezone != null && fileTimezone != settingsTimezone)
        ? fileTimezone
        : null,
  );
}

/// Plage concernée par l'import, ou `null` s'il n'y a rien à importer.
///
/// Elle couvre les dates déclarées et celles des tâches ; avec [fromToday],
/// rien n'est touché avant aujourd'hui.
DateRange? importRange({
  required ParsedPlan plan,
  required LocalDate today,
  required bool fromToday,
}) {
  final split = _splitDuplicates(plan.tasks);
  final retained = _retained(split.unique, today, fromToday: fromToday);
  if (retained.isEmpty) return null;

  var start = retained.first.date;
  var end = retained.first.date;
  for (final date in [
    ...retained.map((t) => t.date),
    ?plan.planStart,
    ?plan.planEnd,
  ]) {
    if (date.isBefore(start)) start = date;
    if (date.isAfter(end)) end = date;
  }
  if (fromToday && start.isBefore(today)) start = today;
  return DateRange(start, end);
}

/// Calcule les écritures d'un import. [existing] contient les tâches actives
/// de la plage renvoyée par [importRange].
ImportChanges prepareImport({
  required ParsedPlan plan,
  required List<Task> existing,
  required LocalDate today,
  required ImportMode mode,
  required bool fromToday,
  required String batchId,
  required DateTime nowUtc,
  required String Function() newId,
}) {
  final split = _splitDuplicates(plan.tasks);
  final retained = _retained(split.unique, today, fromToday: fromToday);

  final toRemove = mode == ImportMode.replace
      ? existing.where((t) => t.status == TaskStatus.todo).toList()
      : <Task>[];
  final removedIds = toRemove.map((t) => t.id).toSet();
  final keptKeys = existing
      .where((t) => !removedIds.contains(t.id))
      .map((t) => t.duplicateKey)
      .toSet();

  final toInsert = <Task>[];
  var skipped = 0;
  for (final task in retained) {
    if (keptKeys.contains(_keyOf(task))) {
      skipped++;
      continue;
    }
    toInsert.add(
      Task(
        id: newId(),
        title: task.title,
        date: task.date,
        start: task.start,
        end: task.end,
        category: task.category,
        notes: task.notes,
        reminderBeforeMin: task.reminderBeforeMin,
        status: task.date.isBefore(today) ? TaskStatus.missed : TaskStatus.todo,
        source: TaskSource.import,
        importBatchId: batchId,
        createdAt: nowUtc,
        updatedAt: nowUtc,
      ),
    );
  }
  return ImportChanges(
    toInsert: toInsert,
    toRemove: toRemove,
    skippedDuplicates: skipped,
  );
}
