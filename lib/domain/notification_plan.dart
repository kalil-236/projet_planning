import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../core/french_format.dart';
import '../core/time_zones.dart';
import 'app_settings.dart';
import 'local_date.dart';
import 'notification_messages.dart';
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
    this.taskId,
    this.endsAt,
    this.endLabel,
  });

  final int id;
  final NotificationKind kind;

  /// Fin de la tâche pour le rappel de début : la notification reste affichée
  /// avec un compte à rebours jusqu'à cet instant UTC, puis disparaît.
  final DateTime? endsAt;

  /// Heure de fin locale, « 15h30 » : affichée dans la pastille de la barre
  /// d'état quand Android met la notification en avant.
  final String? endLabel;

  /// Tâche visée par un rappel : ses boutons agissent sur elle (10.6).
  final String? taskId;

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
        taskId: draft.taskId,
        endsAt: draft.endsAt,
        endLabel: draft.endLabel,
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

/// Briefing d'un jour. Les tâches doivent être triées par heure.
String morningSummaryBody(List<Task> dayTasks, {String key = ''}) {
  if (dayTasks.isEmpty) return morningBriefingEmpty(key);
  final prefix = morningBriefingOpening(dayTasks.length, key);
  final items = [
    for (final task in dayTasks) '${task.title} à ${formatHour(task.start)}',
  ];
  final full = '$prefix${items.join(', ')}.${morningBriefingClosing(key)}';
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
    this.taskId,
    this.endsAt,
    this.endLabel,
  });

  /// Identité stable d'une notification d'une programmation à l'autre.
  final String key;
  final NotificationKind kind;
  final DateTime instant;
  final String title;
  final String body;
  final String? taskId;
  final DateTime? endsAt;
  final String? endLabel;
}

int _bySchedule(_Draft a, _Draft b) {
  final byInstant = a.instant.compareTo(b.instant);
  return byInstant != 0 ? byInstant : a.key.compareTo(b.key);
}

Iterable<_Draft> _draftsForTask(Task task, AppSettings settings) sync* {
  final start = toInstant(task.date, task.start, settings.timezone);
  final schedule = formatTimeRange(task.start, task.end);
  final startKey = '${task.id}|start';
  yield _Draft(
    key: startKey,
    kind: NotificationKind.start,
    instant: start,
    title: "C'est l'heure : ${task.title}",
    body: '${startReminderMessage(task.title, startKey)}\n$schedule',
    taskId: task.id,
    endsAt: toInstant(task.date, task.end, settings.timezone),
    endLabel: formatHour(task.end),
  );
  final before = task.reminderBeforeMin ?? settings.defaultReminderMin;
  if (before > 0) {
    final delay = formatDuration(before);
    final preKey = '${task.id}|pre';
    yield _Draft(
      key: preKey,
      kind: NotificationKind.preReminder,
      instant: start.subtract(Duration(minutes: before)),
      title: 'Dans $delay : ${task.title}',
      body: '${preReminderMessage(task.title, delay, preKey)}\n$schedule',
      taskId: task.id,
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
  final key = 'summary|$date';
  return _Draft(
    key: key,
    kind: NotificationKind.morningSummary,
    instant: toInstant(date, settings.morningSummaryTime, settings.timezone),
    title: morningSummaryTitle(key),
    body: morningSummaryBody(dayTasks, key: key),
  );
}

int _uniqueId(String key, Set<int> used) {
  const mask = 0x7fffffff;
  var hash = stableHash(key);
  while (!used.add(hash)) {
    hash = (hash + 1) & mask;
  }
  return hash;
}
