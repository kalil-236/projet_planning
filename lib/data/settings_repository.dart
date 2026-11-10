import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../domain/app_settings.dart';
import '../domain/local_time.dart';
import 'database.dart';

class SettingsRepository {
  SettingsRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  Stream<AppSettings> watch() => _db
      .select(_db.settingsEntries)
      .watch()
      .map(
        (rows) => rows.isEmpty ? const AppSettings() : _toSettings(rows.first),
      );

  Future<AppSettings> current() async {
    final rows = await _db.select(_db.settingsEntries).get();
    return rows.isEmpty ? const AppSettings() : _toSettings(rows.first);
  }

  Future<void> save(AppSettings settings) {
    return _db
        .into(_db.settingsEntries)
        .insertOnConflictUpdate(
          SettingsEntriesCompanion.insert(
            id: const Value(1),
            dayStart: settings.dayStart.toHHmm(),
            dayEnd: settings.dayEnd.toHHmm(),
            timezone: settings.timezone,
            defaultReminderMin: settings.defaultReminderMin,
            morningSummaryEnabled: settings.morningSummaryEnabled,
            morningSummaryTime: settings.morningSummaryTime.toHHmm(),
            themeMode: settings.themeMode.name,
            updatedAt: _clock.nowUtc(),
          ),
        );
  }

  AppSettings _toSettings(SettingsRow row) => AppSettings(
    dayStart: LocalTime.parse(row.dayStart),
    dayEnd: LocalTime.parse(row.dayEnd),
    timezone: row.timezone,
    defaultReminderMin: row.defaultReminderMin,
    morningSummaryEnabled: row.morningSummaryEnabled,
    morningSummaryTime: LocalTime.parse(row.morningSummaryTime),
    themeMode: AppThemeMode.fromName(row.themeMode),
  );
}
