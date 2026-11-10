import 'package:assistant_planning/core/clock.dart';
import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/notifications/notification_gateway.dart';

/// Lundi 2026-11-09 : le mardi de référence de la spécification est le 10.
const monday = LocalDate(2026, 11, 9);
const tuesday = LocalDate(2026, 11, 10);
const wednesday = LocalDate(2026, 11, 11);

class FakeClock implements Clock {
  FakeClock(this._now);

  /// Heure locale à Porto-Novo (UTC+1).
  factory FakeClock.porto(LocalDate date, int hour, [int minute = 0]) =>
      FakeClock(
        DateTime.utc(date.year, date.month, date.day, hour - 1, minute),
      );

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

class FakeNotificationGateway implements NotificationGateway {
  final Map<int, PlannedNotification> pending = {};
  final List<int> cancelled = [];
  final List<bool> exactModes = [];
  bool allowed = false;
  bool exact = true;
  bool batteryIgnored = false;
  int permissionRequests = 0;
  int exactSettingsOpened = 0;
  Object? scheduleError;

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> requestNotifications({
    bool openSettingsIfBlocked = false,
  }) async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<void> openExactAlarmSettings() async => exactSettingsOpened++;

  @override
  Future<bool> batteryOptimizationIgnored() async => batteryIgnored;

  @override
  Future<void> requestIgnoreBatteryOptimization() async =>
      batteryIgnored = true;

  @override
  Future<Set<int>> pendingIds() async => pending.keys.toSet();

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<void> schedule(
    PlannedNotification notification, {
    required String timezone,
    required bool exact,
  }) async {
    final error = scheduleError;
    if (error != null) throw error;
    exactModes.add(exact);
    pending[notification.id] = notification;
  }
}

final fixedInstant = DateTime.utc(2026, 11, 10, 7);

Task makeTask({
  String id = 't1',
  String title = 'Tâche',
  LocalDate date = tuesday,
  String start = '08:00',
  String end = '10:00',
  TaskStatus status = TaskStatus.todo,
  TaskSource source = TaskSource.manual,
  bool shifted = false,
  String? originalStart,
  TaskCategory category = TaskCategory.autre,
}) {
  return Task(
    id: id,
    title: title,
    date: date,
    start: LocalTime.parse(start),
    end: LocalTime.parse(end),
    category: category,
    status: status,
    source: source,
    shifted: shifted,
    originalStart: originalStart == null
        ? null
        : LocalTime.parse(originalStart),
    createdAt: fixedInstant,
    updatedAt: fixedInstant,
  );
}
