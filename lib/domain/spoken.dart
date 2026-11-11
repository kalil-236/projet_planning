import 'local_time.dart';
import 'notification_messages.dart';
import 'task.dart';

/// Heure dite à voix haute : « 8 heures », « 14 heures 30 », « midi ».
String spokenHour(LocalTime time) {
  if (time.hour == 12 && time.minute == 0) return 'midi';
  if (time.hour == 0 && time.minute == 0) return 'minuit';
  final hours = time.hour == 1 ? '1 heure' : '${time.hour} heures';
  return time.minute == 0 ? hours : '$hours ${time.minute}';
}

/// Briefing lu par F.R.I.D.A.Y : les tâches à faire qui ne sont pas encore
/// terminées, sans limite de longueur, avec les heures en toutes lettres.
String spokenBriefing({
  required List<Task> todayTasks,
  required LocalTime now,
  String key = '',
}) {
  final remaining =
      todayTasks
          .where(
            (t) =>
                t.deletedAt == null &&
                t.status == TaskStatus.todo &&
                t.end.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  if (remaining.isEmpty) {
    return todayTasks.any((t) => t.status == TaskStatus.done)
        ? 'Tout est accompli pour aujourd\'hui, monsieur. Je reste en veille.'
        : morningBriefingEmpty(key);
  }
  final items = [
    for (final task in remaining)
      task.start.isAfter(now)
          ? '${task.title} à ${spokenHour(task.start)}'
          : '${task.title}, en cours jusqu\'à ${spokenHour(task.end)}',
  ];
  final list = items.length == 1
      ? items.single
      : '${items.sublist(0, items.length - 1).join(', ')}, et enfin '
            '${items.last}';
  return '${morningBriefingOpening(remaining.length, key)}$list.'
      '${morningBriefingClosing(key)}';
}
