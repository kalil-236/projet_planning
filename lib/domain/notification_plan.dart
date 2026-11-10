import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../core/french_format.dart';
import '../core/time_zones.dart';
import 'app_settings.dart';
import 'local_date.dart';
import 'task.dart';

const notificationWindowDays = 7;
const maxPlannedNotifications = 200;

/// Réservé à la notification de test : jamais attribué par le calcul.
const testNotificationId = 0;

const _summaryMaxLength = 300;
const _ellipsis = '…';

enum NotificationKind { start, preReminder, morningSummary, test }

@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.instant,
    required this.title,
    required this.body,
  });

  final int id;
  final NotificationKind kind;

  /// Instant absolu en UTC.
  final DateTime instant;
  final String title;
  final String body;
}

/// Jours couverts par la programmation : aujourd'hui et les 6 suivants.
DateRange notificationWindow(LocalDate today) =>
    DateRange(today, today.addDays(notificationWindowDays - 1));

/// Liste complète des notifications à programmer (sections 10.1 à 10.4).
List<PlannedNotification> planNotifications({
  required List<Task> tasks,
  required AppSettings settings,
  required Clock clock,
}) {
  final nowUtc = clock.nowUtc();
  final window = notificationWindow(localNow(clock, settings.timezone).date);
  final active = tasks.where(
    (task) =>
        task.status == TaskStatus.todo &&
        task.deletedAt == null &&
        window.contains(task.date),
  );

  final drafts = <_Draft>[
    for (final task in active) ..._draftsForTask(task, settings),
    if (settings.morningSummaryEnabled)
      for (var i = 0; i < notificationWindowDays; i++)
        _summaryDraft(window.start.addDays(i), active, settings),
  ];

  final upcoming = drafts.where((d) => d.instant.isAfter(nowUtc)).toList()
    ..sort(_bySchedule);
  final usedIds = <int>{testNotificationId};
  return [
    for (final draft in upcoming.take(maxPlannedNotifications))
      PlannedNotification(
        id: _uniqueId(draft.key, usedIds),
        kind: draft.kind,
        instant: draft.instant,
        title: draft.title,
        body: draft.body,
      ),
  ];
}

PlannedNotification testNotification(DateTime nowUtc) => PlannedNotification(
  id: testNotificationId,
  kind: NotificationKind.test,
  instant: nowUtc.add(const Duration(minutes: 1)),
  title: 'Notification de test',
  body: 'Les rappels fonctionnent sur ce téléphone.',
);

/// Texte du résumé d'un jour. Les tâches doivent être triées par heure.
String morningSummaryBody(List<Task> dayTasks) {
  if (dayTasks.isEmpty) return "Rien de prévu aujourd'hui";
  const prefix = "Aujourd'hui : ";
  final items = [
    for (final task in dayTasks) '${task.title} à ${formatHour(task.start)}',
  ];
  final full = prefix + items.join(', ');
  if (full.length <= _summaryMaxLength) return full;

  final limit = _summaryMaxLength - _ellipsis.length;
  var text = prefix;
  for (final (index, item) in items.indexed) {
    final next = index == 0 ? text + item : '$text, $item';
    if (next.length > limit) {
      if (index > 0) return text + _ellipsis;
      return text +
          item.substring(0, limit - text.length).trimRight() +
          _ellipsis;
    }
    text = next;
  }
  return text;
}

class _Draft {
  const _Draft({
    required this.key,
    required this.kind,
    required this.instant,
    required this.title,
    required this.body,
  });

  /// Identité stable d'une notification d'une programmation à l'autre.
  final String key;
  final NotificationKind kind;
  final DateTime instant;
  final String title;
  final String body;
}

int _bySchedule(_Draft a, _Draft b) {
  final byInstant = a.instant.compareTo(b.instant);
  return byInstant != 0 ? byInstant : a.key.compareTo(b.key);
}

Iterable<_Draft> _draftsForTask(Task task, AppSettings settings) sync* {
  final start = toInstant(task.date, task.start, settings.timezone);
  final schedule = formatTimeRange(task.start, task.end);
  yield _Draft(
    key: '${task.id}|start',
    kind: NotificationKind.start,
    instant: start,
    title: "C'est l'heure : ${task.title}",
    body: schedule,
  );
  final before = task.reminderBeforeMin ?? settings.defaultReminderMin;
  if (before > 0) {
    yield _Draft(
      key: '${task.id}|pre',
      kind: NotificationKind.preReminder,
      instant: start.subtract(Duration(minutes: before)),
      title: 'Dans ${_formatDelay(before)} : ${task.title}',
      body: schedule,
    );
  }
}

_Draft _summaryDraft(
  LocalDate date,
  Iterable<Task> tasks,
  AppSettings settings,
) {
  final dayTasks = tasks.where((task) => task.date == date).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return _Draft(
    key: 'summary|$date',
    kind: NotificationKind.morningSummary,
    instant: toInstant(date, settings.morningSummaryTime, settings.timezone),
    title: 'Résumé du matin',
    body: morningSummaryBody(dayTasks),
  );
}

/// « 10 min », « 1 h » ou « 1 h 30 »
String _formatDelay(int minutes) {
  if (minutes < 60) return '$minutes min';
  final rest = minutes % 60;
  final hours = minutes ~/ 60;
  return rest == 0 ? '$hours h' : '$hours h $rest';
}

/// FNV-1a sur 31 bits : `String.hashCode` varie d'une exécution à l'autre.
int _uniqueId(String key, Set<int> used) {
  const offsetBasis = 0x811c9dc5;
  const prime = 0x01000193;
  const mask = 0x7fffffff;
  var hash = offsetBasis;
  for (final unit in key.codeUnits) {
    hash = ((hash ^ unit) * prime) & mask;
  }
  while (!used.add(hash)) {
    hash = (hash + 1) & mask;
  }
  return hash;
}
