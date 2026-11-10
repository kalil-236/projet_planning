import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../data/settings_repository.dart';
import '../data/task_repository.dart';
import '../notifications/reminder_scheduler.dart';
import 'sync_backend.dart';

enum SyncPhase { signedOut, syncing, upToDate, offline }

abstract interface class SyncTrigger {
  Future<void> requestSync();
}

class NoopSyncTrigger implements SyncTrigger {
  const NoopSyncTrigger();

  @override
  Future<void> requestSync() async {}
}

/// Synchronisation local d'abord (section 11). Les écritures restent marquées
/// tant que le serveur ne les a pas reçues.
class SyncService implements SyncTrigger {
  SyncService({
    required this._backend,
    required this._tasks,
    required this._settings,
    required this._scheduler,
    required this._clock,
    this._retryDelay = const Duration(minutes: 1),
  });

  /// Marge de relecture : deux transactions serveur peuvent se terminer dans
  /// un ordre différent de celui de leur `synced_at`.
  static const _cursorOverlap = Duration(minutes: 5);

  final SyncBackend _backend;
  final TaskRepository _tasks;
  final SettingsRepository _settings;
  final ReminderScheduler _scheduler;
  final Clock _clock;
  final Duration _retryDelay;

  final ValueNotifier<SyncPhase> phase = ValueNotifier(SyncPhase.signedOut);
  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier(null);

  Future<void>? _running;
  bool _rerun = false;
  bool _disposed = false;
  Timer? _retry;
  StreamSubscription<bool>? _auth;
  Future<void> Function()? _stopListening;

  void start() {
    _onAuthChanged(_backend.isSignedIn);
    _auth = _backend.signedInChanges.listen(_onAuthChanged);
  }

  void _onAuthChanged(bool signedIn) {
    if (!signedIn) {
      _retry?.cancel();
      unawaited(_stopListening?.call());
      _stopListening = null;
      phase.value = SyncPhase.signedOut;
      return;
    }
    _stopListening ??= _backend.subscribe(() => unawaited(requestSync()));
    unawaited(requestSync());
  }

  /// Une demande pendant un passage en déclenche un dernier.
  @override
  Future<void> requestSync() {
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
      await _syncOnce();
    } while (_rerun && !_disposed);
  }

  Future<void> _syncOnce() async {
    if (_disposed || !_backend.isSignedIn) return;
    _retry?.cancel();
    phase.value = SyncPhase.syncing;
    try {
      final tasksChanged = await _syncTasks();
      final settingsChanged = await _syncSettings();
      if (tasksChanged || settingsChanged) await _scheduler.rescheduleAll();
      if (_disposed) return;
      lastSyncedAt.value = _clock.nowUtc();
      phase.value = _backend.isSignedIn
          ? SyncPhase.upToDate
          : SyncPhase.signedOut;
    } on Exception catch (error) {
      debugPrint('Synchronisation impossible : $error');
      if (_disposed) return;
      phase.value = SyncPhase.offline;
      _retry = Timer(_retryDelay, () => unawaited(requestSync()));
    }
  }

  Future<bool> _syncTasks() async {
    final cursor = await _tasks.tasksCursor();
    final remote = await _backend.tasksSince(cursor?.subtract(_cursorOverlap));
    final changed = await _tasks.applyRemote(
      remote.map((item) => item.task).toList(),
    );
    if (remote.isNotEmpty) {
      await _tasks.saveTasksCursor(
        remote
            .map((item) => item.syncedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      );
    }
    final pending = await _tasks.pendingSync();
    if (pending.isNotEmpty) {
      await _backend.pushTasks(pending);
      await _tasks.markPushed(pending);
    }
    return changed > 0;
  }

  Future<bool> _syncSettings() async {
    final remote = await _backend.fetchSettings();
    final changed =
        remote != null &&
        await _settings.applyRemote(remote.settings, remote.updatedAt);
    final local = await _settings.localState();
    if (local != null && local.pending) {
      await _backend.pushSettings(local.settings, local.updatedAt);
      await _settings.markPushed(local.updatedAt);
    }
    return changed;
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    unawaited(_auth?.cancel());
    unawaited(_stopListening?.call());
    phase.dispose();
    lastSyncedAt.dispose();
  }
}
