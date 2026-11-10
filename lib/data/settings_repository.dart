import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../domain/app_settings.dart';
import '../domain/local_time.dart';
import 'database.dart';

/// Réglages locaux vus par la synchronisation.
class LocalSettingsState {
  const LocalSettingsState({
    required this.settings,
    required this.updatedAt,
    required this.pending,
  });

  final AppSettings settings;
  final DateTime updatedAt;
  final bool pending;
}

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

  Future<void> save(AppSettings settings) =>
      _write(settings, updatedAt: _clock.nowUtc(), pending: true);

  Future<void> _write(
    AppSettings settings, {
    required DateTime updatedAt,
    required bool pending,
  }) {
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
            updatedAt: updatedAt,
            pendingSync: Value(pending),
          ),
        );
  }

  Future<LocalSettingsState?> localState() async {
    final rows = await _db.select(_db.settingsEntries).get();
    if (rows.isEmpty) return null;
    return LocalSettingsState(
      settings: _toSettings(rows.first),
      updatedAt: rows.first.updatedAt.toUtc(),
      pending: rows.first.pendingSync,
    );
  }

  /// Le plus récent gagne. Renvoie `true` si les réglages locaux ont changé.
  Future<bool> applyRemote(AppSettings settings, DateTime updatedAt) {
    return _db.transaction(() async {
      final local = await localState();
      if (local != null && !updatedAt.isAfter(local.updatedAt)) return false;
      await _write(settings, updatedAt: updatedAt, pending: false);
      return true;
    });
  }

  /// Ne retire la marque que si les réglages n'ont pas changé depuis l'envoi.
  Future<void> markPushed(DateTime updatedAt) {
    return (_db.update(_db.settingsEntries)
          ..where((s) => s.updatedAt.equals(updatedAt)))
        .write(const SettingsEntriesCompanion(pendingSync: Value(false)));
  }

  Future<bool> notificationPromptShown() async {
    final rows = await _db.select(_db.settingsEntries).get();
    return rows.isNotEmpty && rows.first.notificationPromptShown;
  }

  Future<void> markNotificationPromptShown() async {
    final rows = await _db.select(_db.settingsEntries).get();
    // Date ancienne : cette ligne technique ne doit pas écraser les réglages
    // déjà présents sur le serveur.
    if (rows.isEmpty) {
      await _write(
        const AppSettings(),
        updatedAt: DateTime.utc(1970),
        pending: false,
      );
    }
    await _db
        .update(_db.settingsEntries)
        .write(
          const SettingsEntriesCompanion(notificationPromptShown: Value(true)),
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
