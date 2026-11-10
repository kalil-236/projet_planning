import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/time_zones.dart';
import '../domain/notification_plan.dart';

/// Accès au système de notifications, isolé pour les tests.
abstract interface class NotificationGateway {
  Future<bool> notificationsAllowed();

  /// Demande l'autorisation. Si Android ne peut plus afficher la demande et que
  /// [openSettingsIfBlocked] est vrai, ouvre les réglages de l'application.
  Future<bool> requestNotifications({bool openSettingsIfBlocked = false});

  Future<bool> canScheduleExact();

  /// Ouvre le réglage système « Alarmes et rappels ».
  Future<void> openExactAlarmSettings();

  Future<bool> batteryOptimizationIgnored();

  Future<void> requestIgnoreBatteryOptimization();

  Future<Set<int>> pendingIds();

  Future<void> cancel(int id);

  /// Lève une [ArgumentError] si l'instant vient juste de passer.
  Future<void> schedule(
    PlannedNotification notification, {
    required String timezone,
    required bool exact,
  });
}

class AndroidNotificationGateway implements NotificationGateway {
  static const _smallIcon = 'ic_notification';
  static const _remindersChannelId = 'rappels';
  static const _remindersChannelName = 'Rappels';
  static const _summaryChannelId = 'resume';
  static const _summaryChannelName = 'Résumé du matin';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final Future<void> _ready = _initialize();

  AndroidFlutterLocalNotificationsPlugin get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()!;

  Future<void> _initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_smallIcon),
      ),
    );
    await _android.createNotificationChannel(
      const AndroidNotificationChannel(
        _remindersChannelId,
        _remindersChannelName,
        importance: Importance.high,
      ),
    );
    await _android.createNotificationChannel(
      const AndroidNotificationChannel(_summaryChannelId, _summaryChannelName),
    );
  }

  @override
  Future<bool> notificationsAllowed() => Permission.notification.isGranted;

  @override
  Future<bool> requestNotifications({
    bool openSettingsIfBlocked = false,
  }) async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied && openSettingsIfBlocked) {
      await openAppSettings();
    }
    return status.isGranted;
  }

  @override
  Future<bool> canScheduleExact() async {
    await _ready;
    return await _android.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    await _ready;
    await _android.requestExactAlarmsPermission();
  }

  @override
  Future<bool> batteryOptimizationIgnored() =>
      Permission.ignoreBatteryOptimizations.isGranted;

  @override
  Future<void> requestIgnoreBatteryOptimization() =>
      Permission.ignoreBatteryOptimizations.request();

  @override
  Future<Set<int>> pendingIds() async {
    await _ready;
    final pending = await _plugin.pendingNotificationRequests();
    return {for (final request in pending) request.id};
  }

  @override
  Future<void> cancel(int id) async {
    await _ready;
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> schedule(
    PlannedNotification notification, {
    required String timezone,
    required bool exact,
  }) async {
    await _ready;
    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: toZoned(notification.instant, timezone),
      notificationDetails: NotificationDetails(
        android: _detailsFor(notification),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  AndroidNotificationDetails _detailsFor(PlannedNotification notification) {
    final style = BigTextStyleInformation(notification.body);
    if (notification.kind == NotificationKind.morningSummary) {
      return AndroidNotificationDetails(
        _summaryChannelId,
        _summaryChannelName,
        styleInformation: style,
      );
    }
    return AndroidNotificationDetails(
      _remindersChannelId,
      _remindersChannelName,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: style,
    );
  }
}
