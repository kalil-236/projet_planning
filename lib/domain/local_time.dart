import 'package:flutter/foundation.dart';

import 'local_date.dart';

/// Heure locale `HH:mm`, sans date ni fuseau.
@immutable
class LocalTime implements Comparable<LocalTime> {
  const LocalTime(this.hour, this.minute);

  /// [minutes] doit être compris entre 0 et 1439.
  const LocalTime.fromMinutes(int minutes)
    : hour = minutes ~/ 60,
      minute = minutes % 60;

  static const minutesPerDay = 1440;
  static final _pattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  static LocalTime? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    return LocalTime(int.parse(match[1]!), int.parse(match[2]!));
  }

  static LocalTime parse(String value) =>
      tryParse(value) ?? (throw FormatException('Heure invalide', value));

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  /// Renvoie `null` si le résultat sort de la journée.
  LocalTime? plusMinutes(int minutes) {
    final total = minutesSinceMidnight + minutes;
    if (total < 0 || total >= minutesPerDay) return null;
    return LocalTime.fromMinutes(total);
  }

  bool isBefore(LocalTime other) => compareTo(other) < 0;
  bool isAfter(LocalTime other) => compareTo(other) > 0;

  String toHHmm() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toHHmm();
}

/// Date et heure locales dans le fuseau configuré.
@immutable
class LocalDateTime {
  const LocalDateTime(this.date, this.time);

  final LocalDate date;
  final LocalTime time;

  @override
  bool operator ==(Object other) =>
      other is LocalDateTime && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => '$date $time';
}
