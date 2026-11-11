import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/time_zones.dart';
import '../domain/notification_plan.dart';
import 'notification_actions.dart';

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

  /// Charge utile de la notification qui a lancé l'application, s'il y en a.
  Future<String?> launchPayload();

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
  static const _reportChannelId = 'rapports';
  static const _reportChannelName = 'Rapports du soir et de la semaine';

  /// Ouvre l'application, qui lit le briefing à voix haute.
  static const _summaryActions = [
    AndroidNotificationAction(
      listenActionId,
      'Écouter',
      showsUserInterface: true,
    ),
  ];

  static const _reportActions = [
    AndroidNotificationAction(postponeActionId, 'Reporter à demain'),
  ];

  /// Sans interface : la tâche est modifiée sans ouvrir l'application.
  static const _taskActions = [
    AndroidNotificationAction(doneActionId, 'Fait'),
    AndroidNotificationAction(shiftActionId, 'Décaler $shiftActionMinutes min'),
  ];

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
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
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
    await _android.createNotificationChannel(
      const AndroidNotificationChannel(_reportChannelId, _reportChannelName),
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
  Future<String?> launchPayload() async {
    await _ready;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final response = details.notificationResponse;
    final actionId = response?.actionId;
    if (actionId == listenActionId) return listenPayload;
    // Les autres boutons agissent sans lancer l'application.
    if (actionId != null && actionId.isNotEmpty) return null;
    return response?.payload;
  }

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
      payload: _payloadFor(notification),
      notificationDetails: NotificationDetails(
        android: _detailsFor(notification),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  String? _payloadFor(PlannedNotification notification) {
    final reportDate = notification.reportDate;
    if (reportDate != null) return dayPayload(reportDate);
    return notification.taskId ?? notification.payload;
  }

  AndroidNotificationDetails _detailsFor(PlannedNotification notification) {
    final style = BigTextStyleInformation(notification.body);
    if (notification.kind == NotificationKind.eveningReport ||
        notification.kind == NotificationKind.weeklyReport) {
      return AndroidNotificationDetails(
        _reportChannelId,
        _reportChannelName,
        styleInformation: style,
        actions: notification.reportDate == null ? null : _reportActions,
      );
    }
    if (notification.kind == NotificationKind.morningSummary) {
      return AndroidNotificationDetails(
        _summaryChannelId,
        _summaryChannelName,
        styleInformation: style,
        actions: _summaryActions,
      );
    }
    final endsAt = notification.endsAt;
    final duration = endsAt?.difference(notification.instant);
    // Tâche en cours : notification persistante avec compte à rebours jusqu'à
    // la fin, mise en avant (« Live Update ») sur Android 16, retirée d'elle-
    // même à la fin prévue.
    final live =
        notification.kind == NotificationKind.start &&
        endsAt != null &&
        duration != null &&
        duration > Duration.zero;
    return AndroidNotificationDetails(
      _remindersChannelId,
      _remindersChannelName,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: style,
      actions: notification.taskId == null ? null : _taskActions,
      ongoing: live,
      requestPromotedOngoing: live,
      onlyAlertOnce: live,
      usesChronometer: live,
      chronometerCountDown: live,
      when: live ? endsAt.millisecondsSinceEpoch : null,
      timeoutAfter: live ? duration.inMilliseconds : null,
      shortCriticalText: live ? notification.endLabel : null,
      category: live ? AndroidNotificationCategory.event : null,
    );
  }
}
