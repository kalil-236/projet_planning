import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/clock.dart';
import '../core/french_format.dart';
import '../core/time_zones.dart';
import '../data/database.dart';
import '../data/planning_service.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';
import 'notification_gateway.dart';
import 'reminder_scheduler.dart';

/// Boutons des rappels (10.6).
const doneActionId = 'fait';
const shiftActionId = 'decaler_15';
const shiftActionMinutes = 15;

/// Applique un bouton de notification. Renvoie `false` si rien n'a changé :
/// tâche introuvable ou déjà traitée, ou décalage qui passerait minuit.
Future<bool> applyNotificationAction({
  required String actionId,
  required String taskId,
  required TaskRepository tasks,
  required PlanningService service,
}) async {
  final task = await tasks.byId(taskId);
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
  final taskId = response.payload;
  final actionId = response.actionId;
  if (taskId == null || actionId == null || actionId.isEmpty) return;

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
      taskId: taskId,
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
        ),
      ),
    );
  } on Object catch (error, stack) {
    debugPrint('Action de notification impossible : $error\n$stack');
  } finally {
    await db.close();
  }
}
