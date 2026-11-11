import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../core/time_zones.dart';
import '../data/device_prefs_repository.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../domain/device_preferences.dart';
import '../domain/local_date.dart';
import '../domain/notification_plan.dart';
import 'notification_gateway.dart';

/// Reprogrammation des rappels, appelée après chaque changement (section 10.2).
abstract interface class ReminderScheduler {
  Future<void> rescheduleAll();
}

/// Sans effet là où il n'y a pas de rappels programmés (web, section 10.7).
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> rescheduleAll() async {}
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({
    required this._tasks,
    required this._settings,
    required this._clock,
    required this._gateway,
    this._devicePrefs,
  });

  final TaskRepository _tasks;
  final SettingsRepository _settings;
  final Clock _clock;
  final NotificationGateway _gateway;

  /// `null` : préférences par défaut (rapport du soir activé).
  final DevicePrefsRepository? _devicePrefs;

  Future<void>? _running;
  bool _rerun = false;

  /// Les appels pendant un passage en cours déclenchent un passage de plus :
  /// le dernier lit toujours l'état le plus récent. N'échoue jamais, pour ne
  /// pas faire échouer la modification de tâche qui l'a déclenché.
  @override
  Future<void> rescheduleAll() {
    final running = _running;
    if (running != null) {
      _rerun = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _rerun = false;
      try {
        await _reschedule();
      } on Object catch (error, stack) {
        debugPrint('Programmation des rappels impossible : $error\n$stack');
      }
    } while (_rerun);
  }

  Future<void> _reschedule() async {
    final settings = await _settings.current();
    final today = localNow(_clock, settings.timezone).date;
    final plan = planNotifications(
      // Depuis lundi : le bilan du dimanche porte sur toute la semaine.
      tasks: await _tasks.activeInRange(
        DateRange(today.monday, notificationWindow(today).end),
      ),
      settings: settings,
      clock: _clock,
      device: await _devicePrefs?.current() ?? const DevicePreferences(),
    );
    final exact = await _gateway.canScheduleExact();

    // Ni `cancelAll`, qui effacerait les rappels déjà affichés, ni annulation
    // préalable : reprogrammer un même identifiant remplace l'ancienne alarme.
    final wanted = {for (final notification in plan) notification.id};
    for (final id in await _gateway.pendingIds()) {
      if (id != testNotificationId && !wanted.contains(id)) {
        await _gateway.cancel(id);
      }
    }
    for (final notification in plan) {
      try {
        await _gateway.schedule(
          notification,
          timezone: settings.timezone,
          exact: exact,
        );
      } on ArgumentError {
        // L'instant vient de passer : l'alarme précédente, intacte, se déclenche.
      }
    }
  }
}
