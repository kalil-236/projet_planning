import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('TaskRow')
@TableIndex(name: 'tasks_date_idx', columns: {#date})
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get date => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get categoryId => text().withDefault(const Constant('autre'))();
  TextColumn get notes => text().nullable()();
  IntColumn get reminderBeforeMin => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  BoolColumn get shifted => boolean().withDefault(const Constant(false))();
  TextColumn get originalStartTime => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get importBatchId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Vrai tant que la dernière écriture locale n'a pas été envoyée au serveur.
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SettingsRow')
class SettingsEntries extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get dayStart => text()();
  TextColumn get dayEnd => text()();
  TextColumn get timezone => text()();
  IntColumn get defaultReminderMin => integer()();
  BoolColumn get morningSummaryEnabled => boolean()();
  TextColumn get morningSummaryTime => text()();
  TextColumn get themeMode => text()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Propre à l'appareil : ne fait pas partie des réglages synchronisés.
  BoolColumn get notificationPromptShown =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Une seule ligne : position de lecture des tâches sur le serveur.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  DateTimeColumn get tasksSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Une seule ligne : préférences propres à l'appareil, jamais synchronisées.
@DataClassName('DevicePrefsRow')
class DevicePrefsEntries extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get eveningReport => boolean().withDefault(const Constant(true))();
  BoolColumn get weeklyReport => boolean().withDefault(const Constant(true))();
  TextColumn get voiceName => text().nullable()();
  TextColumn get voiceLocale => text().nullable()();
  RealColumn get speechRate => real().withDefault(const Constant(0.5))();
  RealColumn get speechPitch => real().withDefault(const Constant(1.0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Tasks, SettingsEntries, SyncCursors, DevicePrefsEntries],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          settingsEntries,
          settingsEntries.notificationPromptShown,
        );
      }
      if (from < 3) {
        // Valeur par défaut vraie : les données existantes seront envoyées.
        await migrator.addColumn(tasks, tasks.pendingSync);
        await migrator.addColumn(settingsEntries, settingsEntries.pendingSync);
        await migrator.createTable(syncCursors);
      }
      if (from < 4) {
        await migrator.addColumn(tasks, tasks.completedAt);
      }
      if (from < 5) {
        await migrator.createTable(devicePrefsEntries);
      }
    },
  );
}

/// Base partagée entre isolats : les boutons des notifications écrivent depuis
/// un moteur Flutter séparé, et l'application ouverte voit leurs changements.
QueryExecutor openAppDatabase() => driftDatabase(
  name: 'planning',
  native: const DriftNativeOptions(shareAcrossIsolates: true),
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
);
