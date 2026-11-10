import 'package:flutter/foundation.dart';

import '../core/text_sanitizer.dart';
import 'category.dart';
import 'local_date.dart';
import 'local_time.dart';
import 'task_draft.dart';

/// Durée d'une tâche sans durée ni heure de fin.
const quickTaskDefaultMinutes = 60;

/// Résultat de l'ajout express : un brouillon, ou une explication.
@immutable
class QuickTaskParse {
  const QuickTaskParse.ok(TaskDraft this.draft) : error = null;

  const QuickTaskParse.error(String this.error) : draft = null;

  final TaskDraft? draft;
  final String? error;
}

// Bornes de mot qui tiennent compte des lettres accentuées.
const _b = r'(?<![\p{L}\d])';
const _e = r'(?![\p{L}\d])';

/// « 18h », « 18 h 30 », « 18h30 », « 18:30 », « midi ».
const _clock =
    r'(?:\d{1,2}\s*h(?:eures?)?(?:\s*\d{2}(?!\d|\s*(?:min|mn)))?|'
    r'\d{1,2}:\d{2}|midi)';

/// « 45 min », « 1h », « 1 h 30 ».
const _duration =
    r'(?:\d{1,2}\s*h(?:eures?)?\s*(?:\d{2})?|\d{1,3}\s*(?:min(?:utes?)?|mn))';

const _months = [
  'janvier',
  'février|fevrier',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août|aout',
  'septembre',
  'octobre',
  'novembre',
  'décembre|decembre',
];

const _weekdays = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

RegExp _re(String pattern) =>
    RegExp(pattern, caseSensitive: false, unicode: true);

final _rangeRe = _re(
  '$_b(?:de|entre|from)?\\s*($_clock)\\s*(?:-|–|à|a|et|jusqu\'à)\\s*($_clock)$_e',
);
final _durationRe = _re('$_b(?:pendant|pour|durant)?\\s*($_duration)$_e');
final _startRe = _re('$_b(?:à|a|vers|dès)?\\s*($_clock)$_e');
final _relativeDayRe = _re(
  "$_b(aujourd'hui|aujourd’hui|auj|ce soir|ce matin|cet après-midi|"
  'cet apres-midi|après-demain|apres-demain|après demain|apres demain|'
  'demain)$_e',
);
final _weekdayRe = _re(
  '$_b(?:ce\\s+)?(${_weekdays.join('|')})(\\s+prochain)?$_e',
);
final _numericDateRe = _re(
  '$_b(?:le\\s+)?(\\d{1,2})/(\\d{1,2})(?:/(\\d{2,4}))?$_e',
);
final _monthDateRe = _re(
  '$_b(?:le\\s+)?(\\d{1,2})(?:er)?\\s+(${_months.join('|')})$_e',
);
final _dayOfMonthRe = _re('${_b}le\\s+(\\d{1,2})(?:er)?$_e');
final _leftoverRe = _re(
  '^(?:à|a|de|du|le|la|les|pour|pendant|vers|et|,|-)\\s+|'
  '\\s+(?:à|a|de|du|le|la|les|pour|pendant|vers|et|,|-)\$',
);

const _categoryWords = <TaskCategory, List<String>>{
  TaskCategory.cours: [
    'cours',
    'td',
    'tp',
    'amphi',
    'examen',
    'partiel',
    'conférence',
    'conference',
    'séminaire',
    'seminaire',
  ],
  TaskCategory.etude: [
    'révision',
    'révisions',
    'revision',
    'revisions',
    'réviser',
    'reviser',
    'étude',
    'etude',
    'étudier',
    'etudier',
    'devoir',
    'devoirs',
    'exercices',
    'lecture',
    'lire',
    'mémoire',
    'memoire',
    'projet',
  ],
  TaskCategory.activite: [
    'sport',
    'foot',
    'football',
    'basket',
    'course',
    'footing',
    'jogging',
    'running',
    'muscu',
    'musculation',
    'gym',
    'natation',
    'piscine',
    'marche',
    'vélo',
    'velo',
    'yoga',
    'danse',
    'boxe',
    'tennis',
    'entraînement',
    'entrainement',
  ],
  TaskCategory.repos: [
    'pause',
    'sieste',
    'repos',
    'repas',
    'déjeuner',
    'dejeuner',
    'dîner',
    'diner',
    'petit-déjeuner',
    'goûter',
    'gouter',
    'détente',
    'detente',
  ],
};

/// Analyse une phrase comme « sport demain 18h 1h » ou « révisions de 14h à
/// 16h ». Sans date, la tâche est pour aujourd'hui, ou demain si l'heure est
/// passée. Sans heure, elle commence à l'heure pleine suivante.
QuickTaskParse parseQuickTask(
  String input, {
  required LocalDate today,
  required LocalTime now,
}) {
  var text = ' ${sanitizeText(input)} ';

  String take(RegExpMatch match) {
    text = text.replaceRange(match.start, match.end, ' ');
    return match[0]!;
  }

  // Date.
  LocalDate? date;
  final relative = _relativeDayRe.firstMatch(text);
  final numeric = _numericDateRe.firstMatch(text);
  final monthDate = _monthDateRe.firstMatch(text);
  final weekday = _weekdayRe.firstMatch(text);
  if (relative != null) {
    take(relative);
    final word = relative[1]!.toLowerCase();
    date = word.startsWith('apr')
        ? today.addDays(2)
        : word == 'demain'
        ? today.addDays(1)
        : today;
  } else if (numeric != null) {
    take(numeric);
    final year = numeric[3];
    date = _dateFrom(
      today,
      int.parse(numeric[1]!),
      int.parse(numeric[2]!),
      year == null ? null : _fullYear(int.parse(year)),
    );
    if (date == null) return const QuickTaskParse.error('Date inconnue.');
  } else if (monthDate != null) {
    take(monthDate);
    final word = monthDate[2]!.toLowerCase();
    final month = _months.indexWhere((m) => m.split('|').contains(word)) + 1;
    date = _dateFrom(today, int.parse(monthDate[1]!), month, null);
    if (date == null) return const QuickTaskParse.error('Date inconnue.');
  } else if (weekday != null) {
    take(weekday);
    final target = _weekdays.indexOf(weekday[1]!.toLowerCase()) + 1;
    var ahead = (target - today.weekday) % 7;
    if (weekday[2] != null && ahead == 0) ahead = 7;
    date = today.addDays(ahead);
  } else {
    final dayOfMonth = _dayOfMonthRe.firstMatch(text);
    if (dayOfMonth != null) {
      take(dayOfMonth);
      date = _dateFrom(today, int.parse(dayOfMonth[1]!), null, null);
      if (date == null) return const QuickTaskParse.error('Date inconnue.');
    }
  }

  // Horaires : plage, sinon début puis durée.
  LocalTime? start;
  LocalTime? end;
  int? minutes;
  final range = _rangeRe
      .allMatches(text)
      .where((match) => !_afterDurationWord(match, text))
      .firstOrNull;
  if (range != null) {
    take(range);
    start = _parseClock(range[1]!);
    end = _parseClock(range[2]!);
    if (start == null || end == null) {
      return const QuickTaskParse.error('Heure inconnue.');
    }
  } else {
    final startMatch = _startRe
        .allMatches(text)
        .where((match) => !_afterDurationWord(match, text))
        .firstOrNull;
    if (startMatch != null) {
      take(startMatch);
      start = _parseClock(startMatch[1]!);
      if (start == null) return const QuickTaskParse.error('Heure inconnue.');
    }
    final durationMatch = _durationRe.firstMatch(text);
    if (durationMatch != null) {
      take(durationMatch);
      minutes = _parseDuration(durationMatch[1]!);
      if (minutes == 0) {
        return const QuickTaskParse.error('Durée inconnue.');
      }
    }
  }

  // Titre : ce qui reste.
  var title = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (var previous = ''; previous != title;) {
    previous = title;
    title = title.replaceAll(_leftoverRe, '').trim();
  }
  if (title.isEmpty) {
    return const QuickTaskParse.error(
      'Ajoutez un titre, par exemple « Sport ».',
    );
  }
  title = title[0].toUpperCase() + title.substring(1);
  if (title.length > 120) title = title.substring(0, 120).trimRight();

  final nextHour = LocalTime.fromMinutes(
    (now.minutesSinceMidnight ~/ 60 + 1) * 60 % LocalTime.minutesPerDay,
  );
  final day =
      date ?? (start != null && !start.isAfter(now) ? today.addDays(1) : today);
  final begin = start ?? nextHour;
  final finish = end ?? begin.plusMinutes(minutes ?? quickTaskDefaultMinutes);
  if (finish == null) {
    return const QuickTaskParse.error('La tâche dépasserait minuit.');
  }
  if (!finish.isAfter(begin)) {
    return const QuickTaskParse.error(
      "L'heure de fin doit suivre l'heure de début.",
    );
  }
  return QuickTaskParse.ok(
    TaskDraft(
      title: title,
      date: day,
      start: begin,
      end: finish,
      category: _guessCategory(title),
    ),
  );
}

final _durationWordRe = _re(r'(?:pendant|pour|durant)\s*$');

/// « pendant 1h » : une durée, pas une heure de début.
bool _afterDurationWord(RegExpMatch match, String text) =>
    _durationWordRe.hasMatch(text.substring(0, match.start));

LocalTime? _parseClock(String value) {
  final lower = value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (lower == 'midi') return const LocalTime(12, 0);
  final match = RegExp(r'^(\d{1,2})(?:h(?:eures?)?|:)(\d{2})?$')
      .firstMatch(lower);
  if (match == null) return null;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2] ?? '0');
  if (hour > 23 || minute > 59) return null;
  return LocalTime(hour, minute);
}

int _parseDuration(String value) {
  final lower = value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final minutesOnly = RegExp(r'^(\d{1,3})(?:min(?:utes?)?|mn)$')
      .firstMatch(lower);
  if (minutesOnly != null) return int.parse(minutesOnly[1]!);
  final hours = RegExp(r'^(\d{1,2})h(?:eures?)?(\d{2})?$').firstMatch(lower);
  if (hours == null) return 0;
  return int.parse(hours[1]!) * 60 + int.parse(hours[2] ?? '0');
}

int _fullYear(int year) => year < 100 ? 2000 + year : year;

/// Jour [day] du mois [month], ou du prochain mois où il n'est pas passé.
LocalDate? _dateFrom(LocalDate today, int day, int? month, int? year) {
  if (month != null && (month < 1 || month > 12)) return null;
  var candidate = _valid(year ?? today.year, month ?? today.month, day);
  if (year == null && (candidate == null || candidate.isBefore(today))) {
    final next = month == null
        ? _valid(
            today.month == 12 ? today.year + 1 : today.year,
            today.month % 12 + 1,
            day,
          )
        : _valid(today.year + 1, month, day);
    candidate = candidate == null || candidate.isBefore(today)
        ? next
        : candidate;
  }
  return candidate;
}

LocalDate? _valid(int year, int month, int day) {
  if (day < 1 || day > 31) return null;
  final value = DateTime.utc(year, month, day);
  if (value.month != month) return null;
  return LocalDate(year, month, day);
}

TaskCategory _guessCategory(String title) {
  final words = title
      .toLowerCase()
      .split(RegExp(r"[^\p{L}\-]+", unicode: true))
      .toSet();
  for (final entry in _categoryWords.entries) {
    if (entry.value.any(words.contains)) return entry.key;
  }
  return TaskCategory.autre;
}
