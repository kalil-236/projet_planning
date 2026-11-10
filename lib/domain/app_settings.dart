import 'package:flutter/foundation.dart';

import '../core/time_zones.dart';
import 'local_time.dart';

enum AppThemeMode {
  system('Système'),
  light('Clair'),
  dark('Sombre');

  const AppThemeMode(this.label);

  final String label;

  static AppThemeMode fromName(String name) =>
      values.firstWhere((mode) => mode.name == name, orElse: () => system);
}

@immutable
class AppSettings {
  const AppSettings({
    this.dayStart = const LocalTime(7, 0),
    this.dayEnd = const LocalTime(22, 0),
    this.timezone = defaultTimezone,
    this.defaultReminderMin = 10,
    this.morningSummaryEnabled = true,
    this.morningSummaryTime = const LocalTime(7, 0),
    this.themeMode = AppThemeMode.system,
  });

  final LocalTime dayStart;
  final LocalTime dayEnd;
  final String timezone;
  final int defaultReminderMin;
  final bool morningSummaryEnabled;
  final LocalTime morningSummaryTime;
  final AppThemeMode themeMode;

  AppSettings copyWith({
    LocalTime? dayStart,
    LocalTime? dayEnd,
    String? timezone,
    int? defaultReminderMin,
    bool? morningSummaryEnabled,
    LocalTime? morningSummaryTime,
    AppThemeMode? themeMode,
  }) {
    return AppSettings(
      dayStart: dayStart ?? this.dayStart,
      dayEnd: dayEnd ?? this.dayEnd,
      timezone: timezone ?? this.timezone,
      defaultReminderMin: defaultReminderMin ?? this.defaultReminderMin,
      morningSummaryEnabled:
          morningSummaryEnabled ?? this.morningSummaryEnabled,
      morningSummaryTime: morningSummaryTime ?? this.morningSummaryTime,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.dayStart == dayStart &&
      other.dayEnd == dayEnd &&
      other.timezone == timezone &&
      other.defaultReminderMin == defaultReminderMin &&
      other.morningSummaryEnabled == morningSummaryEnabled &&
      other.morningSummaryTime == morningSummaryTime &&
      other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(
    dayStart,
    dayEnd,
    timezone,
    defaultReminderMin,
    morningSummaryEnabled,
    morningSummaryTime,
    themeMode,
  );
}
