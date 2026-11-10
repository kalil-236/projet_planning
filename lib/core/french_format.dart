import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../domain/local_date.dart';
import '../domain/local_time.dart';

const _locale = 'fr_FR';

Future<void> initFrenchFormats() => initializeDateFormatting(_locale);

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

String _dayNumber(LocalDate date) => date.day == 1 ? '1er' : '${date.day}';

/// « mardi »
String weekdayName(LocalDate date) =>
    DateFormat('EEEE', _locale).format(date.toDateTime());

/// « lun. »
String weekdayShort(LocalDate date) =>
    DateFormat('E', _locale).format(date.toDateTime());

/// « Mardi 10 novembre 2026 »
String formatFullDate(LocalDate date) {
  final monthYear = DateFormat('MMMM y', _locale).format(date.toDateTime());
  return _capitalize('${weekdayName(date)} ${_dayNumber(date)} $monthYear');
}

/// « 10 novembre »
String formatDayMonth(LocalDate date) =>
    '${_dayNumber(date)} ${DateFormat('MMMM', _locale).format(date.toDateTime())}';

/// « 9 – 15 novembre 2026 » ou « 30 novembre – 6 décembre 2026 »
String formatWeekRange(LocalDate monday) {
  final sunday = monday.addDays(6);
  final end =
      '${_dayNumber(sunday)} '
      '${DateFormat('MMMM y', _locale).format(sunday.toDateTime())}';
  if (monday.month == sunday.month) return '${_dayNumber(monday)} – $end';
  final start =
      '${_dayNumber(monday)} '
      '${DateFormat('MMMM', _locale).format(monday.toDateTime())}';
  return '$start – $end';
}

/// « 8h » ou « 14h30 »
String formatHour(LocalTime time) => time.minute == 0
    ? '${time.hour}h'
    : '${time.hour}h${time.minute.toString().padLeft(2, '0')}';

/// « 08:00 – 10:00 »
String formatTimeRange(LocalTime start, LocalTime end) =>
    '${start.toHHmm()} – ${end.toHHmm()}';
