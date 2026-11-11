import 'package:flutter/foundation.dart';

import 'category.dart';
import 'local_date.dart';
import 'local_time.dart';

enum TaskStatus {
  todo('À faire'),
  done('Faite'),
  cancelled('Annulée'),
  missed('Passée');

  const TaskStatus(this.label);

  final String label;
}

enum TaskSource { import, manual }

/// État affiché d'une tâche ; toujours présenté avec une icône et un texte.
enum TaskDisplayState {
  todo('À faire'),
  done('Faite'),
  cancelled('Annulée'),
  shifted('Décalée'),
  missed('Passée');

  const TaskDisplayState(this.label);

  final String label;
}

const Object _unset = Object();

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.date,
    required this.start,
    required this.end,
    required this.category,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.reminderBeforeMin,
    this.shifted = false,
    this.originalStart,
    this.importBatchId,
    this.deletedAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final LocalDate date;
  final LocalTime start;
  final LocalTime end;
  final TaskCategory category;
  final String? notes;

  /// `null` : valeur par défaut des réglages. `0` : pas de pré-rappel.
  final int? reminderBeforeMin;
  final TaskStatus status;
  final bool shifted;
  final LocalTime? originalStart;
  final TaskSource source;
  final String? importBatchId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Instant UTC où la tâche a été marquée faite : comparé à l'heure de fin
  /// prévue pour apprendre le rythme réel (bilan). `null` si elle n'est pas
  /// faite.
  final DateTime? completedAt;

  TaskDisplayState get displayState => switch (status) {
    TaskStatus.done => TaskDisplayState.done,
    TaskStatus.cancelled => TaskDisplayState.cancelled,
    TaskStatus.missed => TaskDisplayState.missed,
    TaskStatus.todo =>
      shifted ? TaskDisplayState.shifted : TaskDisplayState.todo,
  };

  /// Clé de détection des doublons (section 6.5).
  String get duplicateKey => duplicateKeyOf(title, date, start);

  static String duplicateKeyOf(String title, LocalDate date, LocalTime start) =>
      '$title|$date|$start';

  Task copyWith({
    String? title,
    LocalDate? date,
    LocalTime? start,
    LocalTime? end,
    TaskCategory? category,
    Object? notes = _unset,
    Object? reminderBeforeMin = _unset,
    TaskStatus? status,
    bool? shifted,
    Object? originalStart = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
    Object? completedAt = _unset,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      category: category ?? this.category,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      reminderBeforeMin: identical(reminderBeforeMin, _unset)
          ? this.reminderBeforeMin
          : reminderBeforeMin as int?,
      status: status ?? this.status,
      shifted: shifted ?? this.shifted,
      originalStart: identical(originalStart, _unset)
          ? this.originalStart
          : originalStart as LocalTime?,
      source: source,
      importBatchId: importBatchId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: identical(deletedAt, _unset)
          ? this.deletedAt
          : deletedAt as DateTime?,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.date == date &&
      other.start == start &&
      other.end == end &&
      other.category == category &&
      other.notes == notes &&
      other.reminderBeforeMin == reminderBeforeMin &&
      other.status == status &&
      other.shifted == shifted &&
      other.originalStart == originalStart &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt, status, date, start);
}
