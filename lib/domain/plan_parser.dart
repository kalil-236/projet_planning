import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/text_sanitizer.dart';
import 'category.dart';
import 'local_date.dart';
import 'local_time.dart';

/// Le fichier entier est refusé ; [message] indique la ligne ou le champ.
class ImportRejected implements Exception {
  const ImportRejected(this.message);

  final String message;

  @override
  String toString() => message;
}

@immutable
class ParsedTask {
  const ParsedTask({
    required this.title,
    required this.date,
    required this.start,
    required this.end,
    required this.category,
    this.notes,
    this.reminderBeforeMin,
  });

  final String title;
  final LocalDate date;
  final LocalTime start;
  final LocalTime end;
  final TaskCategory category;
  final String? notes;
  final int? reminderBeforeMin;
}

/// Tâche exclue de l'import, avec la raison affichée à l'aperçu.
@immutable
class InvalidTask {
  const InvalidTask({required this.position, required this.reasons});

  /// Position dans le fichier, à partir de 1.
  final int position;
  final List<String> reasons;
}

@immutable
class ParsedPlan {
  const ParsedPlan({
    required this.tasks,
    required this.invalidTasks,
    required this.notices,
    this.timezone,
    this.planStart,
    this.planEnd,
    this.dayStart,
    this.dayEnd,
  });

  final List<ParsedTask> tasks;
  final List<InvalidTask> invalidTasks;

  /// Remarques non bloquantes sur des champs facultatifs.
  final List<String> notices;
  final String? timezone;
  final LocalDate? planStart;
  final LocalDate? planEnd;
  final LocalTime? dayStart;
  final LocalTime? dayEnd;
}

const _maxTitleLength = 120;
const _supportedSchemaVersion = 1;

final _codeFence = RegExp(r'```(?:json)?\s*\n([\s\S]*?)\n?```');

/// Planning collé ou partagé depuis le chat : la réponse peut entourer le JSON
/// d'un bloc de code ou d'une phrase. Le premier objet trouvé est lu.
ParsedPlan parsePastedPlan(String pasted) {
  final text = pasted.trim();
  if (text.startsWith('{')) return parsePlanJson(text);
  final fenced = _codeFence.firstMatch(text);
  if (fenced != null) return parsePlanJson(fenced.group(1)!.trim());
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const ImportRejected(
      'Le texte ne contient pas de planning au format JSON.',
    );
  }
  return parsePlanJson(text.substring(start, end + 1));
}

ParsedPlan parsePlanJson(String source) {
  final text = source.startsWith('﻿') ? source.substring(1) : source;
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException catch (error) {
    throw ImportRejected(_describeSyntaxError(text, error));
  }

  if (root is! Map<String, dynamic>) {
    throw const ImportRejected('Le fichier doit contenir un objet JSON.');
  }
  final version = root['schema_version'];
  if (version == null) {
    throw const ImportRejected('Champ « schema_version » manquant.');
  }
  if (version is! int || version != _supportedSchemaVersion) {
    throw ImportRejected(
      'Champ « schema_version » : version inconnue ($version). '
      'Seule la version $_supportedSchemaVersion est prise en charge.',
    );
  }
  final rawTasks = root['tasks'];
  if (rawTasks is! List) {
    throw const ImportRejected(
      'Champ « tasks » manquant ou qui n\'est pas une liste.',
    );
  }

  final notices = <String>[];
  final tasks = <ParsedTask>[];
  final invalid = <InvalidTask>[];
  for (final (index, raw) in rawTasks.indexed) {
    final reasons = <String>[];
    final task = _parseTask(raw, index, reasons, notices);
    if (task != null) {
      tasks.add(task);
    } else {
      invalid.add(InvalidTask(position: index + 1, reasons: reasons));
    }
  }

  final timezone = _optionalString(root, 'timezone', notices);
  final bounds = _parseDayBounds(root['day_bounds'], notices);
  return ParsedPlan(
    tasks: tasks,
    invalidTasks: invalid,
    notices: notices,
    timezone: timezone,
    planStart: _optionalDate(root, 'plan_start', notices),
    planEnd: _optionalDate(root, 'plan_end', notices),
    dayStart: bounds?.$1,
    dayEnd: bounds?.$2,
  );
}

String _describeSyntaxError(String text, FormatException error) {
  final offset = error.offset;
  if (offset == null) return 'JSON invalide : ${error.message}.';
  final before = text.substring(0, offset.clamp(0, text.length));
  final line = '\n'.allMatches(before).length + 1;
  final column = offset - (before.lastIndexOf('\n') + 1) + 1;
  return 'JSON invalide, ligne $line, colonne $column : ${error.message}.';
}

ParsedTask? _parseTask(
  Object? raw,
  int index,
  List<String> reasons,
  List<String> notices,
) {
  final field = 'tasks[$index]';
  if (raw is! Map<String, dynamic>) {
    reasons.add('$field : doit être un objet.');
    return null;
  }

  final title = _parseTitle(raw['title'], field, reasons);
  final date = _parseRequiredDate(raw['date'], '$field.date', reasons);
  final start = _parseRequiredTime(raw['start'], '$field.start', reasons);
  final end = _parseRequiredTime(raw['end'], '$field.end', reasons);
  if (start != null && end != null && !end.isAfter(start)) {
    reasons.add('$field.end : doit être après le début ($start).');
  }
  if (reasons.isNotEmpty) return null;

  final rawCategory = raw['category'];
  final category = TaskCategory.fromId(
    rawCategory is String ? rawCategory : null,
  );
  if (rawCategory != null && category.id != rawCategory) {
    notices.add(
      '$field.category : « $rawCategory » inconnue, remplacée par Autre.',
    );
  }

  final rawNotes = raw['notes'];
  final notes = rawNotes is String ? sanitizeText(rawNotes) : null;

  final rawReminder = raw['reminder_before_min'];
  int? reminder;
  if (rawReminder is int && rawReminder >= 0) {
    reminder = rawReminder;
  } else if (rawReminder != null) {
    notices.add(
      '$field.reminder_before_min : valeur ignorée, le rappel par défaut '
      's\'appliquera.',
    );
  }

  return ParsedTask(
    title: title!,
    date: date!,
    start: start!,
    end: end!,
    category: category,
    notes: (notes == null || notes.isEmpty) ? null : notes,
    reminderBeforeMin: reminder,
  );
}

String? _parseTitle(Object? raw, String field, List<String> reasons) {
  final title = raw is String ? sanitizeText(raw) : '';
  if (title.isEmpty) {
    reasons.add('$field.title : texte obligatoire.');
    return null;
  }
  if (title.length > _maxTitleLength) {
    reasons.add('$field.title : $_maxTitleLength caractères au maximum.');
    return null;
  }
  return title;
}

LocalDate? _parseRequiredDate(Object? raw, String field, List<String> reasons) {
  final date = raw is String ? LocalDate.tryParse(raw) : null;
  if (date == null) reasons.add('$field : date attendue au format AAAA-MM-JJ.');
  return date;
}

LocalTime? _parseRequiredTime(Object? raw, String field, List<String> reasons) {
  final time = raw is String ? LocalTime.tryParse(raw) : null;
  if (time == null) reasons.add('$field : heure attendue au format HH:mm.');
  return time;
}

String? _optionalString(
  Map<String, dynamic> root,
  String key,
  List<String> notices,
) {
  final value = root[key];
  if (value == null || value is String) return value as String?;
  notices.add('$key : valeur ignorée, texte attendu.');
  return null;
}

LocalDate? _optionalDate(
  Map<String, dynamic> root,
  String key,
  List<String> notices,
) {
  final value = root[key];
  if (value == null) return null;
  final date = value is String ? LocalDate.tryParse(value) : null;
  if (date == null) notices.add('$key : valeur ignorée, date mal formée.');
  return date;
}

(LocalTime, LocalTime)? _parseDayBounds(Object? raw, List<String> notices) {
  if (raw == null) return null;
  LocalTime? read(String key) {
    if (raw is! Map<String, dynamic>) return null;
    final value = raw[key];
    return value is String ? LocalTime.tryParse(value) : null;
  }

  final start = read('start');
  final end = read('end');
  if (start == null || end == null || !end.isAfter(start)) {
    notices.add('day_bounds : valeur ignorée, horaires invalides.');
    return null;
  }
  return (start, end);
}
