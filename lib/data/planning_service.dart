import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../core/text_sanitizer.dart';
import '../core/time_zones.dart';
import '../domain/app_settings.dart';
import '../domain/category.dart';
import '../domain/local_date.dart';
import '../domain/local_time.dart';
import '../domain/plan_import.dart';
import '../domain/plan_parser.dart';
import '../domain/task.dart';
import '../domain/task_ops.dart';
import '../notifications/reminder_scheduler.dart';
import '../sync/sync_service.dart';
import 'settings_repository.dart';
import 'task_repository.dart';

@immutable
class ImportSummary {
  const ImportSummary({
    required this.inserted,
    required this.replaced,
    required this.skippedDuplicates,
  });

  final int inserted;
  final int replaced;
  final int skippedDuplicates;
}

/// Toutes les écritures de l'application passent par ce service, qui
/// reprogramme ensuite les rappels (section 10.2).
class PlanningService {
  PlanningService({
    required this._tasks,
    required this._settings,
    required this._clock,
    required this._scheduler,
    this._sync = const NoopSyncTrigger(),
  });

  final TaskRepository _tasks;
  final SettingsRepository _settings;
  final Clock _clock;
  final ReminderScheduler _scheduler;
  final SyncTrigger _sync;
  final Uuid _uuid = const Uuid();

  Future<void> addTask({
    required String title,
    required LocalDate date,
    required LocalTime start,
    required LocalTime end,
    required TaskCategory category,
    required String? notes,
    required int? reminderBeforeMin,
  }) async {
    final now = _clock.nowUtc();
    await _tasks.upsert(
      Task(
        id: _uuid.v4(),
        title: sanitizeText(title),
        date: date,
        start: start,
        end: end,
        category: category,
        notes: _cleanNotes(notes),
        reminderBeforeMin: reminderBeforeMin,
        status: TaskStatus.todo,
        source: TaskSource.manual,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _afterWrite();
  }

  /// Enregistre une édition. Changer l'heure d'une tâche importée la marque
  /// comme décalée.
  Future<void> updateTask(Task original, Task edited) async {
    final movedImport =
        original.source == TaskSource.import && edited.start != original.start;
    await _save(
      edited.copyWith(
        title: sanitizeText(edited.title),
        notes: _cleanNotes(edited.notes),
        shifted: movedImport ? true : edited.shifted,
        originalStart: movedImport
            ? (original.originalStart ?? original.start)
            : edited.originalStart,
      ),
    );
  }

  Future<void> setStatus(Task task, TaskStatus status) =>
      _save(task.copyWith(status: status));

  /// Renvoie `false` si la tâche traverserait minuit.
  Future<bool> shiftBy(Task task, int minutes) =>
      _saveShift(shiftTaskBy(task, minutes, _clock.nowUtc()));

  /// Renvoie `false` si la tâche traverserait minuit.
  Future<bool> shiftTo(Task task, LocalTime newStart) =>
      _saveShift(shiftTaskTo(task, newStart, _clock.nowUtc()));

  Future<bool> _saveShift(Task? moved) async {
    if (moved == null) return false;
    await _tasks.upsert(moved);
    await _afterWrite();
    return true;
  }

  Future<DayShiftPlan> previewDayShift(int minutes) async {
    final settings = await _settings.current();
    final now = localNow(_clock, settings.timezone);
    return planDayShift(
      tasks: await _tasks.activeInRange(DateRange(now.date, now.date)),
      now: now,
      minutes: minutes,
      dayEnd: settings.dayEnd,
      nowUtc: _clock.nowUtc(),
    );
  }

  Future<void> applyDayShift(DayShiftPlan plan) async {
    if (!plan.canApply) return;
    await _tasks.upsertAll(plan.shifted);
    await _afterWrite();
  }

  Future<void> deleteTask(Task task) async {
    await _tasks.softDelete(task.id, _clock.nowUtc());
    await _afterWrite();
  }

  Future<ImportSummary> importPlan({
    required ParsedPlan plan,
    required ImportMode mode,
    required bool fromToday,
    required bool applyDayBounds,
  }) async {
    final settings = await _settings.current();
    final today = localNow(_clock, settings.timezone).date;
    final range = importRange(plan: plan, today: today, fromToday: fromToday);
    final nowUtc = _clock.nowUtc();
    final changes = prepareImport(
      plan: plan,
      existing: range == null ? const [] : await _tasks.activeInRange(range),
      today: today,
      mode: mode,
      fromToday: fromToday,
      batchId: _uuid.v4(),
      nowUtc: nowUtc,
      newId: _uuid.v4,
    );
    await _tasks.applyImport(changes, nowUtc);

    final dayStart = plan.dayStart;
    final dayEnd = plan.dayEnd;
    if (applyDayBounds && dayStart != null && dayEnd != null) {
      await _settings.save(
        settings.copyWith(dayStart: dayStart, dayEnd: dayEnd),
      );
    }
    await _afterWrite();
    return ImportSummary(
      inserted: changes.toInsert.length,
      replaced: changes.toRemove.length,
      skippedDuplicates: changes.skippedDuplicates,
    );
  }

  /// Les tâches gardent leur date locale ; seuls les rappels sont recalculés.
  Future<void> saveSettings(AppSettings settings) async {
    await _settings.save(settings);
    await _afterWrite();
  }

  Future<void> _save(Task task) async {
    await _tasks.upsert(task.copyWith(updatedAt: _clock.nowUtc()));
    await _afterWrite();
  }

  /// La synchronisation n'est pas attendue : l'écriture locale fait foi.
  Future<void> _afterWrite() async {
    await _scheduler.rescheduleAll();
    unawaited(_sync.requestSync());
  }

  String? _cleanNotes(String? notes) {
    if (notes == null) return null;
    final cleaned = sanitizeText(notes);
    return cleaned.isEmpty ? null : cleaned;
  }
}
