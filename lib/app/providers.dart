import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../core/clock.dart';
import '../core/time_zones.dart';
import '../data/database.dart';
import '../data/planning_service.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../domain/app_settings.dart';
import '../domain/local_date.dart';
import '../domain/local_time.dart';
import '../domain/task.dart';
import '../notifications/notification_gateway.dart';
import '../notifications/reminder_scheduler.dart';
import '../sync/supabase_sync_backend.dart';
import '../sync/sync_backend.dart';
import '../sync/sync_service.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openAppDatabase());
  ref.onDispose(database.close);
  return database;
});

/// `null` hors d'Android : les rappels programmés n'existent pas sur le web.
final notificationGatewayProvider = Provider<NotificationGateway?>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? AndroidNotificationGateway()
      : null,
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      SettingsRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final gateway = ref.watch(notificationGatewayProvider);
  if (gateway == null) return const NoopReminderScheduler();
  return LocalReminderScheduler(
    tasks: ref.watch(taskRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    gateway: gateway,
  );
});

/// Reprogramme au lancement et au retour au premier plan (section 10.2).
final reminderLifecycleProvider = Provider<void>((ref) {
  final scheduler = ref.watch(reminderSchedulerProvider);
  unawaited(scheduler.rescheduleAll());
  final lifecycle = AppLifecycleListener(
    onResume: () => unawaited(scheduler.rescheduleAll()),
  );
  ref.onDispose(lifecycle.dispose);
});

/// `null` tant que Supabase n'est pas configuré : l'application reste locale.
final syncBackendProvider = Provider<SyncBackend?>(
  (ref) => SupabaseConfig.ready
      ? SupabaseSyncBackend(Supabase.instance.client)
      : null,
);

/// Sur le web, les données sont liées au compte : la connexion est obligatoire.
/// Sur Android, l'application et les rappels restent utilisables sans compte.
final loginRequiredProvider = Provider<bool>((ref) => kIsWeb);

final syncServiceProvider = Provider<SyncService?>((ref) {
  final backend = ref.watch(syncBackendProvider);
  if (backend == null) return null;
  final service = SyncService(
    backend: backend,
    tasks: ref.watch(taskRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Synchronise au lancement et au retour au premier plan (section 11.5).
final syncLifecycleProvider = Provider<void>((ref) {
  final service = ref.watch(syncServiceProvider);
  if (service == null) return;
  service.start();
  final lifecycle = AppLifecycleListener(
    onResume: () => unawaited(service.requestSync()),
  );
  ref.onDispose(lifecycle.dispose);
});

final planningServiceProvider = Provider<PlanningService>(
  (ref) => PlanningService(
    tasks: ref.watch(taskRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    sync: ref.watch(syncServiceProvider) ?? const NoopSyncTrigger(),
  ),
);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// Réglages disponibles immédiatement, valeurs par défaut pendant le chargement.
final currentSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsProvider).value ?? const AppSettings(),
);

/// Date et heure locales. Recalculées à chaque minute pile (donc à minuit), au
/// retour au premier plan et au changement de fuseau (section 5.1).
class NowNotifier extends Notifier<LocalDateTime> {
  Timer? _timer;

  @override
  LocalDateTime build() {
    final clock = ref.watch(clockProvider);
    final timezone = ref.watch(
      currentSettingsProvider.select((settings) => settings.timezone),
    );

    void tick() => state = localNow(clock, timezone);

    void arm() {
      _timer?.cancel();
      _timer = Timer(untilNextMinute(clock.nowUtc()), () {
        tick();
        arm();
      });
    }

    final lifecycle = AppLifecycleListener(onResume: tick);
    ref.onDispose(() {
      _timer?.cancel();
      lifecycle.dispose();
    });

    arm();
    return localNow(clock, timezone);
  }
}

final nowProvider = NotifierProvider<NowNotifier, LocalDateTime>(
  NowNotifier.new,
);

final todayProvider = Provider<LocalDate>(
  (ref) => ref.watch(nowProvider.select((now) => now.date)),
);

final tasksInRangeProvider = StreamProvider.autoDispose
    .family<List<Task>, DateRange>(
      (ref, range) => ref.watch(taskRepositoryProvider).watchRange(range),
    );

final taskByIdProvider = StreamProvider.autoDispose.family<Task?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchById(id),
);

/// Tâche affichée dans le panneau de détail en largeur PC.
class SelectedTaskNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedTaskIdProvider = NotifierProvider<SelectedTaskNotifier, String?>(
  SelectedTaskNotifier.new,
);

/// Jour choisi dans Semaine ; `null` suit la date du jour.
class WeekSelectedDayNotifier extends Notifier<LocalDate?> {
  @override
  LocalDate? build() => null;

  void select(LocalDate? day) => state = day;
}

final weekSelectedDayProvider =
    NotifierProvider<WeekSelectedDayNotifier, LocalDate?>(
      WeekSelectedDayNotifier.new,
    );
