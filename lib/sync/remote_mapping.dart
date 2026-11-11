import '../domain/app_settings.dart';
import '../domain/category.dart';
import '../domain/local_date.dart';
import '../domain/local_time.dart';
import '../domain/task.dart';
import 'sync_backend.dart';

/// `user_id` est absent : le serveur le renseigne avec `auth.uid()`.
Map<String, Object?> taskToRow(Task task) => {
  'id': task.id,
  'title': task.title,
  'date': task.date.toIso(),
  'start_time': task.start.toHHmm(),
  'end_time': task.end.toHHmm(),
  'category_id': task.category.id,
  'notes': task.notes,
  'reminder_before_min': task.reminderBeforeMin,
  'status': task.status.name,
  'shifted': task.shifted,
  'original_start_time': task.originalStart?.toHHmm(),
  'source': task.source.name,
  'import_batch_id': task.importBatchId,
  'created_at': _instant(task.createdAt),
  'updated_at': _instant(task.updatedAt),
  'deleted_at': task.deletedAt == null ? null : _instant(task.deletedAt!),
  'completed_at': task.completedAt == null ? null : _instant(task.completedAt!),
};

RemoteTask remoteTaskFromRow(Map<String, dynamic> row) {
  final originalStart = row['original_start_time'] as String?;
  final deletedAt = row['deleted_at'] as String?;
  // Absente tant que la migration 002 n'a pas été exécutée sur le serveur.
  final completedAt = row['completed_at'] as String?;
  return RemoteTask(
    syncedAt: _parseInstant(row['synced_at'] as String),
    task: Task(
      id: row['id'] as String,
      title: row['title'] as String,
      date: LocalDate.parse(row['date'] as String),
      start: _parseTime(row['start_time'] as String),
      end: _parseTime(row['end_time'] as String),
      category: TaskCategory.fromId(row['category_id'] as String?),
      notes: row['notes'] as String?,
      reminderBeforeMin: row['reminder_before_min'] as int?,
      status: TaskStatus.values.byName(row['status'] as String),
      shifted: row['shifted'] as bool,
      originalStart: originalStart == null ? null : _parseTime(originalStart),
      source: TaskSource.values.byName(row['source'] as String),
      importBatchId: row['import_batch_id'] as String?,
      createdAt: _parseInstant(row['created_at'] as String),
      updatedAt: _parseInstant(row['updated_at'] as String),
      deletedAt: deletedAt == null ? null : _parseInstant(deletedAt),
      completedAt: completedAt == null ? null : _parseInstant(completedAt),
    ),
  );
}

Map<String, Object?> settingsToRow(AppSettings settings, DateTime updatedAt) =>
    {
      'day_start': settings.dayStart.toHHmm(),
      'day_end': settings.dayEnd.toHHmm(),
      'timezone': settings.timezone,
      'default_reminder_min': settings.defaultReminderMin,
      'morning_summary_enabled': settings.morningSummaryEnabled,
      'morning_summary_time': settings.morningSummaryTime.toHHmm(),
      'theme_mode': settings.themeMode.name,
      'updated_at': _instant(updatedAt),
    };

RemoteSettings remoteSettingsFromRow(Map<String, dynamic> row) =>
    RemoteSettings(
      updatedAt: _parseInstant(row['updated_at'] as String),
      settings: AppSettings(
        dayStart: _parseTime(row['day_start'] as String),
        dayEnd: _parseTime(row['day_end'] as String),
        timezone: row['timezone'] as String,
        defaultReminderMin: row['default_reminder_min'] as int,
        morningSummaryEnabled: row['morning_summary_enabled'] as bool,
        morningSummaryTime: _parseTime(row['morning_summary_time'] as String),
        themeMode: AppThemeMode.fromName(row['theme_mode'] as String),
      ),
    );

String _instant(DateTime value) => value.toUtc().toIso8601String();

DateTime _parseInstant(String value) => DateTime.parse(value).toUtc();

/// Postgres renvoie `HH:mm:ss`.
LocalTime _parseTime(String value) => LocalTime.parse(value.substring(0, 5));
