import 'package:drift/drift.dart';

import '../domain/device_preferences.dart';
import 'database.dart';

class DevicePrefsRepository {
  DevicePrefsRepository(this._db);

  final AppDatabase _db;

  Stream<DevicePreferences> watch() => _db
      .select(_db.devicePrefsEntries)
      .watch()
      .map(
        (rows) => rows.isEmpty ? const DevicePreferences() : _from(rows.first),
      );

  Future<DevicePreferences> current() async {
    final rows = await _db.select(_db.devicePrefsEntries).get();
    return rows.isEmpty ? const DevicePreferences() : _from(rows.first);
  }

  Future<void> save(DevicePreferences prefs) => _db
      .into(_db.devicePrefsEntries)
      .insertOnConflictUpdate(
        DevicePrefsEntriesCompanion.insert(
          id: const Value(1),
          eveningReport: Value(prefs.eveningReportEnabled),
          weeklyReport: Value(prefs.weeklyReportEnabled),
          voiceName: Value(prefs.voiceName),
          voiceLocale: Value(prefs.voiceLocale),
          speechRate: Value(prefs.speechRate),
          speechPitch: Value(prefs.speechPitch),
        ),
      );

  DevicePreferences _from(DevicePrefsRow row) => DevicePreferences(
    eveningReportEnabled: row.eveningReport,
    weeklyReportEnabled: row.weeklyReport,
    voiceName: row.voiceName,
    voiceLocale: row.voiceLocale,
    speechRate: row.speechRate,
    speechPitch: row.speechPitch,
  );
}
