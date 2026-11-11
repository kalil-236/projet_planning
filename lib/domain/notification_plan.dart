import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../core/french_format.dart';
import '../core/time_zones.dart';
import 'app_settings.dart';
import 'device_preferences.dart';
import 'local_date.dart';
import 'local_time.dart';
import 'notification_messages.dart';
import 'task.dart';
import 'week_stats.dart';

const notificationWindowDays = 7;
const maxPlannedNotifications = 200;

/// Réservé à la notification de test : jamais attribué par le calcul.
const testNotificationId = 0;

const _summaryMaxLength = 300;
const _ellipsis = '…';

enum NotificationKind {
  start,
  preReminder,
  morningSummary,
  eveningReport,
  weeklyReport,
  test,
}

/// Charge utile qui ouvre l'onglet Bilan.
const reportPayload = 'bilan';

/// Charge utile du résumé du matin : ouvre Aujourd'hui.
const briefingPayload = 'briefing';

/// Le bilan de la semaine suit le rapport du soir du dimanche.
const _weeklyAfterEvening = Duration(minutes: 5);

/// Tâches restantes citées par leur titre dans le rapport du soir.
const _eveningListedTasks = 4;

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
    this.reportDate,
    this.payload,
  });

  final int id;
  final NotificationKind kind;

  /// Fin de la tâche pour le rappel de début : la notification reste affichée
  /// avec un compte à rebours jusqu'à cet instant UTC, puis disparaît.
  final DateTime? endsAt;

  /// Heure de fin locale, « 15h30 » : affichée dans la pastille de la barre
  /// d'état quand Android met la notification en avant.
  final String? endLabel;

  /// Jour dont le rapport du soir propose de reporter les tâches restantes ;
  /// `null` quand il n'y a rien à reporter.
  final LocalDate? reportDate;

  /// Écran à ouvrir quand on touche la notification ([reportPayload],
  /// [briefingPayload]) ; les rappels de tâche portent leur [taskId].
  final String? payload;

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
  DevicePreferences device = const DevicePreferences(),
}) {
  final nowUtc = clock.nowUtc();
  final today = localNow(clock, settings.timezone).date;
  final window = notificationWindow(today);
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
    if (device.eveningReportEnabled)
      for (var i = 0; i < notificationWindowDays; i++)
        ?_eveningDraft(window.start.addDays(i), tasks, settings),
    if (device.weeklyReportEnabled)
      ?_weeklyDraft(today.monday, tasks, settings),
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
        reportDate: draft.reportDate,
        payload: draft.payload,
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
    this.reportDate,
    this.payload,
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
  final LocalDate? reportDate;
  final String? payload;
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
    payload: briefingPayload,
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

/// Rapport du soir d'un jour, envoyé à la fin de journée, ou après la dernière
/// tâche si elle finit plus tard. Aucun rapport pour un jour sans tâche.
_Draft? _eveningDraft(
  LocalDate date,
  Iterable<Task> tasks,
  AppSettings settings,
) {
  final day = tasks
      .where(
        (t) =>
            t.date == date &&
            t.deletedAt == null &&
            t.status != TaskStatus.cancelled,
      )
      .toList();
  if (day.isEmpty) return null;
  final done = day.where((t) => t.status == TaskStatus.done).length;
  final remaining = day.where((t) => t.status == TaskStatus.todo).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final at = _eveningTime(day, settings);
  final key = 'evening|$date';
  return _Draft(
    key: key,
    kind: NotificationKind.eveningReport,
    instant: toInstant(date, at, settings.timezone),
    title: eveningReportTitle(key),
    body: remaining.isEmpty
        ? eveningAllDone(key)
        : eveningReportBody(done, day.length, remaining, key: key),
    reportDate: remaining.isEmpty ? null : date,
  );
}

/// « Monsieur, 3 sur 5 missions accomplies. Restent : Sport, Lecture. … »
String eveningReportBody(
  int done,
  int total,
  List<Task> remaining, {
  String key = '',
}) {
  final listed = [
    for (final task in remaining.take(_eveningListedTasks)) task.title,
  ];
  final others = remaining.length - listed.length;
  final names = others > 0
      ? '${listed.join(', ')} et ${others == 1 ? 'une autre' : '$others autres'}'
      : listed.join(', ');
  final label = remaining.length == 1 ? 'Reste' : 'Restent';
  final full =
      '${eveningPartialOpening(done, total, key)} $label : $names.'
      '${eveningPartialClosing(key)}';
  if (full.length <= _summaryMaxLength) return full;
  return '${full.substring(0, _summaryMaxLength - _ellipsis.length).trimRight()}'
      '$_ellipsis';
}

/// Fin de journée, ou fin de la dernière tâche si elle est plus tardive.
LocalTime _eveningTime(Iterable<Task> dayTasks, AppSettings settings) {
  var at = settings.dayEnd;
  for (final task in dayTasks) {
    if (task.deletedAt == null &&
        task.status != TaskStatus.cancelled &&
        task.end.isAfter(at)) {
      at = task.end;
    }
  }
  return at;
}

/// Bilan de la semaine qui commence le lundi [monday], le dimanche soir peu
/// après le rapport du soir. Chiffres arrêtés à l'heure de l'envoi.
_Draft? _weeklyDraft(LocalDate monday, List<Task> tasks, AppSettings settings) {
  final sunday = monday.addDays(6);
  final time = _eveningTime(tasks.where((t) => t.date == sunday), settings);
  final stats = weekStats(
    tasks: tasks,
    monday: monday,
    today: sunday,
    now: time,
  );
  if (stats.isEmpty) return null;
  final key = 'weekly|$monday';
  return _Draft(
    key: key,
    kind: NotificationKind.weeklyReport,
    instant: toInstant(
      sunday,
      time,
      settings.timezone,
    ).add(_weeklyAfterEvening),
    title: weeklyReportTitle(key),
    body: weeklyReportBody(stats),
    payload: reportPayload,
  );
}

/// « Semaine bouclée, monsieur : 23 missions sur 30 (77 %). … »
String weeklyReportBody(WeekStats stats) {
  final rate = stats.rate;
  final score = rate == null
      ? 'aucune mission due'
      : '${stats.done} ${stats.done > 1 ? 'missions' : 'mission'} sur '
            '${stats.due} (${(rate * 100).round()} %)';
  CategoryStats? best;
  for (final category in stats.categories) {
    if (category.doneMinutes > 0 &&
        (best == null || category.doneMinutes > best.doneMinutes)) {
      best = category;
    }
  }
  final strength = best == null
      ? ''
      : ' Point fort : ${best.category.label.toLowerCase()}, '
            '${formatDuration(best.doneMinutes)} accomplies.';
  return 'Semaine bouclée, monsieur : $score. ${weekVerdict(rate)}$strength'
      ' Le détail vous attend dans le Bilan.';
}
