import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/clock.dart';
import '../core/french_format.dart';
import '../core/time_zones.dart';
import '../data/database.dart';
import '../data/device_prefs_repository.dart';
import '../data/planning_service.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../domain/local_date.dart';
import '../domain/task.dart';
import 'notification_gateway.dart';
import 'reminder_scheduler.dart';

/// Boutons des rappels (10.6).
const doneActionId = 'fait';
const shiftActionId = 'decaler_15';
const shiftActionMinutes = 15;

/// Bouton « Reporter à demain » du rapport du soir.
const postponeActionId = 'reporter_demain';

/// Charge utile d'un rapport du soir : le jour concerné.
const _dayPayloadPrefix = 'jour:';

String dayPayload(LocalDate date) => '$_dayPayloadPrefix${date.toIso()}';

/// Applique un bouton de notification. [payload] est l'identifiant de la
/// tâche, ou le jour du rapport du soir. Renvoie `false` si rien n'a changé :
/// tâche introuvable ou déjà traitée, décalage qui passerait minuit, ou rien
/// à reporter.
Future<bool> applyNotificationAction({
  required String actionId,
  required String payload,
  required TaskRepository tasks,
  required PlanningService service,
}) async {
  if (actionId == postponeActionId) {
    if (!payload.startsWith(_dayPayloadPrefix)) return false;
    final date = LocalDate.tryParse(
      payload.substring(_dayPayloadPrefix.length),
    );
    return date != null && await service.postponeToNextDay(date) > 0;
  }
  final task = await tasks.byId(payload);
  if (task == null || task.status != TaskStatus.todo) return false;
  switch (actionId) {
    case doneActionId:
      await service.setStatus(task, TaskStatus.done);
      return true;
    case shiftActionId:
      return service.shiftBy(task, shiftActionMinutes);
  }
  return false;
}

/// Point d'entrée des boutons, appelé par Android dans un moteur Flutter
/// séparé, même quand l'application est fermée. La base est partagée avec
/// l'application si elle tourne : ses écrans se mettent à jour d'eux-mêmes.
/// Les changements seront envoyés au serveur à la prochaine synchronisation.
@pragma('vm:entry-point')
Future<void> onNotificationResponse(NotificationResponse response) async {
  final payload = response.payload;
  final actionId = response.actionId;
  if (payload == null || actionId == null || actionId.isEmpty) return;

  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  initTimeZones();
  await initFrenchFormats();

  final db = AppDatabase(openAppDatabase());
  try {
    const clock = SystemClock();
    final tasks = TaskRepository(db);
    final settings = SettingsRepository(db, clock);
    await applyNotificationAction(
      actionId: actionId,
      payload: payload,
      tasks: tasks,
      service: PlanningService(
        tasks: tasks,
        settings: settings,
        clock: clock,
        scheduler: LocalReminderScheduler(
          tasks: tasks,
          settings: settings,
          clock: clock,
          gateway: AndroidNotificationGateway(),
          devicePrefs: DevicePrefsRepository(db),
        ),
      ),
    );
  } on Object catch (error, stack) {
    debugPrint('Action de notification impossible : $error\n$stack');
  } finally {
    await db.close();
  }
}
