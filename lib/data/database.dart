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

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Tasks, SettingsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(
          settingsEntries,
          settingsEntries.notificationPromptShown,
        );
      }
    },
  );
}

QueryExecutor openAppDatabase() => driftDatabase(
  name: 'planning',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
);
