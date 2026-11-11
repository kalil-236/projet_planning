import 'package:flutter/foundation.dart';

import '../core/french_format.dart';
import '../core/time_zones.dart';
import 'category.dart';
import 'local_date.dart';
import 'local_time.dart';
import 'task.dart';

/// Jours d'historique analysés pour les observations.
const insightHistoryDays = 28;

/// Nombre minimal de tâches pour tirer une conclusion.
const _minSamples = 3;

/// Écart moyen, en minutes, à partir duquel un débordement est signalé.
const _overrunThreshold = 10;

/// Une tâche marquée faite plus de 3 h après sa fin a été cochée après coup :
/// son heure de réalisation ne dit rien de sa durée.
const _lateCheckMinutes = 180;

/// Écart de taux (en points) qui distingue deux moments de la journée.
const _periodGap = 0.25;

enum InsightKind { overrun, underrun, timeOfDay, weekday, neglected }

/// Observation de F.R.I.D.A.Y : une phrase pour l'écran, une pour le prompt
/// envoyé à Claude, qui en tiendra compte au prochain planning.
@immutable
class Insight {
  const Insight({
    required this.kind,
    required this.message,
    required this.promptLine,
  });

  final InsightKind kind;
  final String message;
  final String promptLine;
}

/// Période de l'historique analysé, jusqu'à aujourd'hui inclus.
DateRange insightRange(LocalDate today) =>
    DateRange(today.addDays(1 - insightHistoryDays), today);

String _categoryName(TaskCategory category) => switch (category) {
  TaskCategory.cours => 'cours',
  TaskCategory.etude => "sessions d'étude",
  TaskCategory.activite => 'activités',
  TaskCategory.repos => 'pauses',
  TaskCategory.autre => 'tâches diverses',
};

/// Observations sur l'historique, des plus parlantes aux plus générales.
List<Insight> computeInsights({
  required List<Task> tasks,
  required LocalDate today,
  required LocalTime now,
  required String timezone,
}) {
  final range = insightRange(today);
  final history = tasks
      .where(
        (t) =>
            t.deletedAt == null &&
            t.status != TaskStatus.cancelled &&
            range.contains(t.date),
      )
      .toList();
  return [
    ..._durationInsights(history, timezone),
    ?_timeOfDayInsight(history, today, now),
    ?_weekdayInsight(history, today, now),
    ?_neglectedInsight(history, today, now),
  ];
}

bool _due(Task task, LocalDate today, LocalTime now) =>
    task.status == TaskStatus.done ||
    task.status == TaskStatus.missed ||
    task.date.isBefore(today) ||
    (task.date == today && !task.end.isAfter(now));

/// Écart entre l'heure où la tâche a été cochée et sa fin prévue.
List<Insight> _durationInsights(List<Task> history, String timezone) {
  final deltas = <TaskCategory, List<int>>{};
  for (final task in history) {
    final completedAt = task.completedAt;
    if (task.status != TaskStatus.done || completedAt == null) continue;
    final local = toLocalDateTime(completedAt, timezone);
    if (local.date != task.date) continue;
    final at = local.time.minutesSinceMidnight;
    final start = task.start.minutesSinceMidnight;
    final end = task.end.minutesSinceMidnight;
    // Cochée avant le début, ou longtemps après : pas une mesure de durée.
    if (at < start || at > end + _lateCheckMinutes) continue;
    deltas.putIfAbsent(task.category, () => []).add(at - end);
  }

  final result = <Insight>[];
  for (final entry in deltas.entries) {
    if (entry.value.length < _minSamples) continue;
    final average = (entry.value.reduce((a, b) => a + b) / entry.value.length)
        .round();
    final name = _categoryName(entry.key);
    final capitalized = name[0].toUpperCase() + name.substring(1);
    if (average >= _overrunThreshold) {
      final delay = formatDuration(average);
      result.add(
        Insight(
          kind: InsightKind.overrun,
          message:
              '$capitalized : vous terminez en moyenne $delay après '
              "l'heure prévue.",
          promptLine:
              'Mes $name débordent en moyenne de $delay : prévois-les plus '
              'longues.',
        ),
      );
    } else if (average <= -_overrunThreshold) {
      final early = formatDuration(-average);
      result.add(
        Insight(
          kind: InsightKind.underrun,
          message:
              '$capitalized : vous terminez en moyenne $early avant '
              "l'heure prévue.",
          promptLine:
              'Je termine mes $name en moyenne $early plus tôt que prévu : '
              'tu peux les raccourcir.',
        ),
      );
    }
  }
  return result;
}

String _percent(double rate) => '${(rate * 100).round()} %';

enum _Period {
  morning('le matin', 'du matin'),
  afternoon("l'après-midi", "de l'après-midi"),
  evening('le soir', 'du soir');

  const _Period(this.when, this.of);

  final String when;
  final String of;

  static _Period forStart(LocalTime start) => start.hour < 12
      ? morning
      : start.hour < 18
      ? afternoon
      : evening;
}

({int done, int due}) _tally(
  Iterable<Task> tasks,
  LocalDate today,
  LocalTime now,
) {
  var done = 0;
  var due = 0;
  for (final task in tasks) {
    if (!_due(task, today, now)) continue;
    due++;
    if (task.status == TaskStatus.done) done++;
  }
  return (done: done, due: due);
}

Insight? _timeOfDayInsight(List<Task> history, LocalDate today, LocalTime now) {
  final rates = <_Period, double>{};
  for (final period in _Period.values) {
    final tally = _tally(
      history.where((t) => _Period.forStart(t.start) == period),
      today,
      now,
    );
    if (tally.due >= _minSamples + 2) rates[period] = tally.done / tally.due;
  }
  if (rates.length < 2) return null;
  final sorted = rates.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final best = sorted.first;
  final worst = sorted.last;
  if (best.value - worst.value < _periodGap) return null;
  return Insight(
    kind: InsightKind.timeOfDay,
    message:
        'Vous accomplissez ${_percent(best.value)} de vos missions '
        '${best.key.of}, contre ${_percent(worst.value)} ${worst.key.when}.',
    promptLine:
        'Je suis plus efficace ${best.key.when} (${_percent(best.value)} de '
        'tâches faites) que ${worst.key.when} (${_percent(worst.value)}) : '
        'place les tâches exigeantes ${best.key.when}.',
  );
}

const _weekdayNames = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

Insight? _weekdayInsight(List<Task> history, LocalDate today, LocalTime now) {
  final rates = <int, double>{};
  for (var weekday = 1; weekday <= 7; weekday++) {
    final tally = _tally(
      history.where((t) => t.date.weekday == weekday),
      today,
      now,
    );
    if (tally.due >= _minSamples) rates[weekday] = tally.done / tally.due;
  }
  if (rates.length < 3) return null;
  final worst = rates.entries.reduce((a, b) => a.value <= b.value ? a : b);
  final average = rates.values.reduce((a, b) => a + b) / rates.length;
  if (average - worst.value < _periodGap / 2 || worst.value > 0.7) return null;
  final name = _weekdayNames[worst.key - 1];
  return Insight(
    kind: InsightKind.weekday,
    message:
        'Le $name est votre jour le plus difficile : '
        '${_percent(worst.value)} de missions accomplies.',
    promptLine:
        'Le $name, je ne fais que ${_percent(worst.value)} de ce qui est '
        'prévu : allège ce jour-là.',
  );
}

Insight? _neglectedInsight(List<Task> history, LocalDate today, LocalTime now) {
  Insight? found;
  var lowest = 1.0;
  for (final category in TaskCategory.values) {
    final tally = _tally(
      history.where((t) => t.category == category),
      today,
      now,
    );
    if (tally.due < _minSamples + 1) continue;
    final rate = tally.done / tally.due;
    if (rate < 0.5 && rate < lowest) {
      lowest = rate;
      final name = _categoryName(category);
      found = Insight(
        kind: InsightKind.neglected,
        message:
            'Vos $name passent souvent à la trappe : '
            '${_percent(rate)} seulement sont faites.',
        promptLine:
            "Je ne fais que ${_percent(rate)} de mes $name : prévois-en "
            'moins, ou de plus courtes.',
      );
    }
  }
  return found;
}

/// Plafond utilisé par le prompt : au-delà, la liste noierait la demande.
const maxPromptInsights = 4;
