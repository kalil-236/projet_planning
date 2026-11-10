import 'package:flutter/foundation.dart';

/// Date calendaire sans fuseau. Le jour de la semaine en est toujours dérivé.
@immutable
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime value) =>
      LocalDate(value.year, value.month, value.day);

  static final _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Lit `YYYY-MM-DD` ; renvoie `null` si la date n'existe pas au calendrier.
  static LocalDate? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final check = DateTime.utc(year, month, day);
    if (check.month != month || check.day != day) return null;
    return LocalDate(year, month, day);
  }

  static LocalDate parse(String value) =>
      tryParse(value) ?? (throw FormatException('Date invalide', value));

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = lundi, 7 = dimanche.
  int get weekday => _utc.weekday;

  LocalDate get monday => addDays(1 - weekday);

  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(_utc.add(Duration(days: days)));

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Valeur pour les sélecteurs et les formats, à minuit heure de l'appareil.
  DateTime toDateTime() => DateTime(year, month, day);

  String toIso() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// Plage de dates, bornes incluses.
@immutable
class DateRange {
  const DateRange(this.start, this.end);

  final LocalDate start;
  final LocalDate end;

  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
