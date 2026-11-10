import 'dart:async';
import 'dart:ui';

import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/sync/sync_backend.dart';

/// Serveur en mémoire, partagé entre plusieurs appareils simulés. Reproduit le
/// déclencheur de `supabase/schema.sql` : le plus récent gagne.
class FakeServer {
  final Map<String, RemoteTask> tasks = {};
  RemoteSettings? settings;
  bool online = true;
  void Function()? onPush;
  final Set<VoidCallback> _listeners = {};
  DateTime _clock = DateTime.utc(2026, 11, 10);

  DateTime _nextSyncedAt() => _clock = _clock.add(const Duration(minutes: 10));

  void _ensureOnline() {
    if (!online) throw Exception('hors ligne');
  }

  void _notify() {
    for (final listener in _listeners.toList()) {
      listener();
    }
  }
}

class FakeSyncBackend implements SyncBackend {
  FakeSyncBackend(this.server, {this._signedIn = true});

  final FakeServer server;
  final StreamController<bool> _changes = StreamController.broadcast();
  bool _signedIn;
  int pushes = 0;
  SignInFailure? signInFailure;
  List<DateTime?> cursors = [];

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get email => _signedIn ? 'moi@exemple.fr' : null;

  @override
  Stream<bool> get signedInChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    final failure = signInFailure;
    if (failure != null) throw failure;
    _signedIn = true;
    _changes.add(true);
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _changes.add(false);
  }

  @override
  Future<List<RemoteTask>> tasksSince(DateTime? cursor) async {
    server._ensureOnline();
    cursors.add(cursor);
    return server.tasks.values
        .where((item) => cursor == null || item.syncedAt.isAfter(cursor))
        .toList();
  }

  @override
  Future<void> pushTasks(List<Task> tasks) async {
    server._ensureOnline();
    server.onPush?.call();
    pushes++;
    for (final task in tasks) {
      final existing = server.tasks[task.id];
      if (existing != null &&
          task.updatedAt.isBefore(existing.task.updatedAt)) {
        continue;
      }
      server.tasks[task.id] = RemoteTask(
        task: task,
        syncedAt: server._nextSyncedAt(),
      );
    }
    server._notify();
  }

  @override
  Future<RemoteSettings?> fetchSettings() async {
    server._ensureOnline();
    return server.settings;
  }

  @override
  Future<void> pushSettings(AppSettings settings, DateTime updatedAt) async {
    server._ensureOnline();
    final existing = server.settings;
    if (existing != null && updatedAt.isBefore(existing.updatedAt)) return;
    server.settings = RemoteSettings(settings: settings, updatedAt: updatedAt);
    server._notify();
  }

  @override
  Future<void> Function() subscribe(VoidCallback onChange) {
    server._listeners.add(onChange);
    return () async => server._listeners.remove(onChange);
  }
}
