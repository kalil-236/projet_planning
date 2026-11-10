import 'package:assistant_planning/data/database.dart';
import 'package:assistant_planning/data/settings_repository.dart';
import 'package:assistant_planning/data/task_repository.dart';
import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/notifications/reminder_scheduler.dart';
import 'package:assistant_planning/sync/sync_backend.dart';
import 'package:assistant_planning/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_sync_backend.dart';
import '../support/fakes.dart';
import '../support/test_app.dart';

class _CountingScheduler implements ReminderScheduler {
  int calls = 0;

  @override
  Future<void> rescheduleAll() async => calls++;
}

class _Device {
  _Device(FakeServer server, {bool signedIn = true})
    : db = createTestDatabase() {
    backend = FakeSyncBackend(server, signedIn: signedIn);
    tasks = TaskRepository(db);
    settings = SettingsRepository(db, clock);
    service = SyncService(
      backend: backend,
      tasks: tasks,
      settings: settings,
      scheduler: scheduler,
      clock: clock,
      retryDelay: const Duration(hours: 1),
    );
  }

  final AppDatabase db;
  final FakeClock clock = FakeClock.porto(tuesday, 9);
  final _CountingScheduler scheduler = _CountingScheduler();
  late final FakeSyncBackend backend;
  late final TaskRepository tasks;
  late final SettingsRepository settings;
  late final SyncService service;

  Future<void> close() async {
    service.dispose();
    await db.close();
  }

  Future<Task?> find(String id) async {
    final all = await tasks.activeInRange(DateRange(tuesday, tuesday));
    return all.where((task) => task.id == id).firstOrNull;
  }
}

DateTime _at(int hour) => DateTime.utc(2026, 11, 10, hour);

Task _task(String title, int hour, {String id = 't1'}) =>
    makeTask(id: id, title: title).copyWith(updatedAt: _at(hour));

void main() {
  late FakeServer server;
  late _Device phone;
  late _Device pc;

  setUp(() {
    server = FakeServer();
    phone = _Device(server);
    pc = _Device(server);
  });

  tearDown(() async {
    await phone.close();
    await pc.close();
  });

  test('une tâche modifiée sur un appareil arrive sur l\'autre', () async {
    await phone.tasks.upsert(_task('Depuis le téléphone', 8));
    await phone.service.requestSync();
    await pc.service.requestSync();
    expect((await pc.find('t1'))?.title, 'Depuis le téléphone');

    await pc.tasks.upsert(_task('Depuis le PC', 9));
    await pc.service.requestSync();
    await phone.service.requestSync();
    expect((await phone.find('t1'))?.title, 'Depuis le PC');
  });

  test('le premier envoi retire la marque de synchronisation', () async {
    await phone.tasks.upsert(_task('Cours', 8));
    expect(await phone.tasks.pendingSync(), hasLength(1));

    await phone.service.requestSync();

    expect(await phone.tasks.pendingSync(), isEmpty);
    expect(server.tasks, contains('t1'));
    expect(phone.service.phase.value, SyncPhase.upToDate);
  });

  test('le plus récent du serveur remplace une écriture locale', () async {
    await pc.tasks.upsert(_task('Récent', 10));
    await pc.service.requestSync();
    await phone.tasks.upsert(_task('Ancien', 8));

    await phone.service.requestSync();

    expect((await phone.find('t1'))?.title, 'Récent');
    expect(server.tasks['t1']?.task.title, 'Récent');
    expect(await phone.tasks.pendingSync(), isEmpty);
  });

  test('une écriture locale plus récente est conservée et envoyée', () async {
    await pc.tasks.upsert(_task('Ancien', 8));
    await pc.service.requestSync();
    await phone.tasks.upsert(_task('Récent', 10));

    await phone.service.requestSync();

    expect((await phone.find('t1'))?.title, 'Récent');
    expect(server.tasks['t1']?.task.title, 'Récent');
  });

  test('une modification faite hors ligne, datée d\'avant, arrive '
      'quand même sur l\'autre appareil', () async {
    await phone.tasks.upsert(_task('Base', 8));
    await phone.service.requestSync();
    await pc.service.requestSync();

    await pc.tasks.upsert(_task('Autre', 11, id: 't2'));
    await pc.service.requestSync();
    await phone.service.requestSync();

    // Écrite hors ligne avant t2, envoyée après la lecture du PC.
    await phone.tasks.upsert(_task('Hors ligne', 9, id: 't3'));
    await phone.service.requestSync();
    await pc.service.requestSync();

    expect((await pc.find('t3'))?.title, 'Hors ligne');
  });

  test('une suppression se propage', () async {
    await phone.tasks.upsert(_task('Cours', 8));
    await phone.service.requestSync();
    await pc.service.requestSync();
    expect(await pc.find('t1'), isNotNull);

    await phone.tasks.softDelete('t1', _at(9));
    await phone.service.requestSync();
    await pc.service.requestSync();

    expect(await pc.find('t1'), isNull);
    expect(server.tasks['t1']?.task.deletedAt, isNotNull);
  });

  test('hors ligne, rien n\'est perdu et l\'envoi reprend', () async {
    server.online = false;
    await phone.tasks.upsert(_task('Cours', 8));

    await phone.service.requestSync();

    expect(phone.service.phase.value, SyncPhase.offline);
    expect(await phone.find('t1'), isNotNull);
    expect(await phone.tasks.pendingSync(), hasLength(1));

    server.online = true;
    await phone.service.requestSync();

    expect(phone.service.phase.value, SyncPhase.upToDate);
    expect(await phone.tasks.pendingSync(), isEmpty);
    expect(server.tasks, contains('t1'));
  });

  test('une tâche modifiée pendant l\'envoi reste à synchroniser', () async {
    await phone.tasks.upsert(_task('Avant', 8));
    server.onPush = () {
      server.onPush = null;
      phone.tasks.upsert(_task('Pendant', 9));
    };

    await phone.service.requestSync();
    await pumpEventQueue();

    expect((await phone.tasks.pendingSync()).single.title, 'Pendant');

    await phone.service.requestSync();
    expect(server.tasks['t1']?.task.title, 'Pendant');
    expect(await phone.tasks.pendingSync(), isEmpty);
  });

  test(
    'les rappels sont reprogrammés seulement si quelque chose a changé',
    () async {
      await pc.tasks.upsert(_task('Cours', 8));
      await pc.service.requestSync();

      await phone.service.requestSync();
      expect(phone.scheduler.calls, 1);

      await phone.service.requestSync();
      expect(phone.scheduler.calls, 1);
    },
  );

  test('la position de lecture garde une marge de relecture', () async {
    await pc.tasks.upsert(_task('Cours', 8));
    await pc.service.requestSync();
    await phone.service.requestSync();
    expect(phone.backend.cursors.single, isNull);

    await phone.service.requestSync();

    final saved = await phone.tasks.tasksCursor();
    expect(
      phone.backend.cursors.last,
      saved!.subtract(const Duration(minutes: 5)),
    );
  });

  test('sans session, rien n\'est échangé', () async {
    final signedOut = _Device(server, signedIn: false);
    addTearDown(signedOut.close);
    await signedOut.tasks.upsert(_task('Cours', 8));

    await signedOut.service.requestSync();

    expect(server.tasks, isEmpty);
    expect(await signedOut.tasks.pendingSync(), hasLength(1));
  });

  test('un changement en direct déclenche une synchronisation', () async {
    phone.service.start();
    await pumpEventQueue();

    await pc.tasks.upsert(_task('En direct', 8));
    await pc.service.requestSync();
    await pumpEventQueue();

    expect((await phone.find('t1'))?.title, 'En direct');
  });

  group('réglages', () {
    const dark = AppSettings(themeMode: AppThemeMode.dark);
    const light = AppSettings(themeMode: AppThemeMode.light);

    test('les réglages circulent et le plus récent gagne', () async {
      await phone.settings.save(dark);
      await phone.service.requestSync();
      await pc.service.requestSync();
      expect((await pc.settings.current()).themeMode, AppThemeMode.dark);

      pc.clock.advance(const Duration(hours: 1));
      await pc.settings.save(light);
      await pc.service.requestSync();
      await phone.service.requestSync();

      expect((await phone.settings.current()).themeMode, AppThemeMode.light);
      expect((await phone.settings.localState())!.pending, isFalse);
    });

    test('la demande de permission locale n\'écrase pas le serveur', () async {
      server.settings = RemoteSettings(settings: dark, updatedAt: _at(1));
      await phone.settings.markNotificationPromptShown();

      await phone.service.requestSync();

      expect((await phone.settings.current()).themeMode, AppThemeMode.dark);
      expect(server.settings?.settings.themeMode, AppThemeMode.dark);
    });

    test('la demande de permission reste propre à l\'appareil', () async {
      await phone.settings.markNotificationPromptShown();
      server.settings = RemoteSettings(settings: dark, updatedAt: _at(1));

      await phone.service.requestSync();

      expect(await phone.settings.notificationPromptShown(), isTrue);
    });
  });
}
