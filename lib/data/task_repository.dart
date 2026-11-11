import 'package:drift/drift.dart';

import '../domain/category.dart';
import '../domain/local_date.dart';
import '../domain/local_time.dart';
import '../domain/plan_import.dart';
import '../domain/task.dart';
import 'database.dart';

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$TasksTable, TaskRow> _activeInRange(DateRange range) {
    return _db.select(_db.tasks)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.date.isBetweenValues(range.start.toIso(), range.end.toIso()),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.date),
        (t) => OrderingTerm(expression: t.startTime),
      ]);
  }

  Stream<List<Task>> watchRange(DateRange range) =>
      _activeInRange(range).watch().map((rows) => rows.map(_toTask).toList());

  Future<List<Task>> activeInRange(DateRange range) async =>
      (await _activeInRange(range).get()).map(_toTask).toList();

  Stream<Task?> watchById(String id) {
    final query = _db.select(_db.tasks)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toTask(row),
    );
  }

  Future<Task?> byId(String id) async {
    final query = _db.select(_db.tasks)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toTask(row);
  }

  Future<void> upsert(Task task) =>
      _db.into(_db.tasks).insertOnConflictUpdate(_toCompanion(task));

  Future<void> upsertAll(Iterable<Task> tasks) => _db.batch((batch) {
    batch.insertAllOnConflictUpdate(
      _db.tasks,
      tasks.map(_toCompanion).toList(),
    );
  });

  Future<void> softDelete(String id, DateTime at) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        deletedAt: Value(at),
        updatedAt: Value(at),
        pendingSync: const Value(true),
      ),
    );
  }

  /// Tâches à envoyer au serveur, y compris les suppressions logiques.
  Future<List<Task>> pendingSync() async {
    final query = _db.select(_db.tasks)
      ..where((t) => t.pendingSync.equals(true));
    return (await query.get()).map(_toTask).toList();
  }

  /// Ne retire la marque que si la tâche n'a pas changé depuis son envoi.
  Future<void> markPushed(List<Task> pushed) => _db.transaction(() async {
    for (final task in pushed) {
      await (_db.update(_db.tasks)..where(
            (t) => t.id.equals(task.id) & t.updatedAt.equals(task.updatedAt),
          ))
          .write(const TasksCompanion(pendingSync: Value(false)));
    }
  });

  /// Applique les tâches du serveur : le plus récent gagne (section 11.3).
  /// Renvoie le nombre de tâches modifiées localement.
  Future<int> applyRemote(List<Task> remote) => _db.transaction(() async {
    final local = await _updatedAtById(remote.map((task) => task.id).toList());
    final newer = remote.where((task) {
      final current = local[task.id];
      return current == null || task.updatedAt.isAfter(current);
    }).toList();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.tasks, [
        for (final task in newer)
          _toCompanion(task).copyWith(pendingSync: const Value(false)),
      ]);
    });
    return newer.length;
  });

  Future<DateTime?> tasksCursor() async {
    final row = await _db.select(_db.syncCursors).getSingleOrNull();
    return row?.tasksSyncedAt?.toUtc();
  }

  Future<void> saveTasksCursor(DateTime cursor) => _db
      .into(_db.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          id: const Value(1),
          tasksSyncedAt: Value(cursor),
        ),
      );

  Future<Map<String, DateTime>> _updatedAtById(List<String> ids) async {
    const chunk = 500;
    final result = <String, DateTime>{};
    for (var i = 0; i < ids.length; i += chunk) {
      final end = i + chunk < ids.length ? i + chunk : ids.length;
      final query = _db.select(_db.tasks)
        ..where((t) => t.id.isIn(ids.sublist(i, end)));
      for (final row in await query.get()) {
        result[row.id] = row.updatedAt;
      }
    }
    return result;
  }

  Future<void> applyImport(ImportChanges changes, DateTime at) {
    return _db.transaction(() async {
      for (final task in changes.toRemove) {
        await softDelete(task.id, at);
      }
      await upsertAll(changes.toInsert);
    });
  }

  Task _toTask(TaskRow row) => Task(
    id: row.id,
    title: row.title,
    date: LocalDate.parse(row.date),
    start: LocalTime.parse(row.startTime),
    end: LocalTime.parse(row.endTime),
    category: TaskCategory.fromId(row.categoryId),
    notes: row.notes,
    reminderBeforeMin: row.reminderBeforeMin,
    status: TaskStatus.values.byName(row.status),
    shifted: row.shifted,
    originalStart: row.originalStartTime == null
        ? null
        : LocalTime.parse(row.originalStartTime!),
    source: TaskSource.values.byName(row.source),
    importBatchId: row.importBatchId,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    completedAt: row.completedAt?.toUtc(),
  );

  TasksCompanion _toCompanion(Task task) => TasksCompanion.insert(
    id: task.id,
    title: task.title,
    date: task.date.toIso(),
    startTime: task.start.toHHmm(),
    endTime: task.end.toHHmm(),
    categoryId: Value(task.category.id),
    notes: Value(task.notes),
    reminderBeforeMin: Value(task.reminderBeforeMin),
    status: Value(task.status.name),
    shifted: Value(task.shifted),
    originalStartTime: Value(task.originalStart?.toHHmm()),
    source: Value(task.source.name),
    importBatchId: Value(task.importBatchId),
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    deletedAt: Value(task.deletedAt),
    completedAt: Value(task.completedAt),
    pendingSync: const Value(true),
  );
}
