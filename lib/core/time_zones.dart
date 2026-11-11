import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/local_date.dart';
import '../domain/local_time.dart';
import 'clock.dart';

const defaultTimezone = 'Africa/Porto-Novo';

void initTimeZones() => tz_data.initializeTimeZones();

bool isKnownTimezone(String name) =>
    tz.timeZoneDatabase.locations.containsKey(name);

List<String> allTimezones() =>
    tz.timeZoneDatabase.locations.keys.toList()..sort();

tz.Location _location(String name) =>
    tz.getLocation(isKnownTimezone(name) ? name : defaultTimezone);

/// Date et heure actuelles dans [timezone].
LocalDateTime localNow(Clock clock, String timezone) {
  final now = tz.TZDateTime.from(clock.nowUtc(), _location(timezone));
  return LocalDateTime(
    LocalDate(now.year, now.month, now.day),
    LocalTime(now.hour, now.minute),
  );
}

/// Instant [utc] exprimé dans [timezone], pour la programmation des rappels.
tz.TZDateTime toZoned(DateTime utc, String timezone) =>
    tz.TZDateTime.from(utc, _location(timezone));

/// Instant absolu d'une heure locale. À réserver aux notifications (5.1).
DateTime toInstant(LocalDate date, LocalTime time, String timezone) {
  return tz.TZDateTime(
    _location(timezone),
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  ).toUtc();
}

/// Date et heure locales d'un instant [utc] dans [timezone].
LocalDateTime toLocalDateTime(DateTime utc, String timezone) {
  final local = tz.TZDateTime.from(utc, _location(timezone));
  return LocalDateTime(
    LocalDate(local.year, local.month, local.day),
    LocalTime(local.hour, local.minute),
  );
}
