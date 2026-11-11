import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_settings.dart';
import '../domain/task.dart';
import 'remote_mapping.dart';
import 'sync_backend.dart';

/// Valeurs fournies à la compilation (`--dart-define-from-file=env.json`).
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool ready = false;

  /// Un échec laisse l'application en mode local : les rappels restent actifs.
  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) return;
    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      ready = true;
    } on Exception catch (error) {
      debugPrint('Initialisation de Supabase impossible : $error');
    }
  }
}

class SupabaseSyncBackend implements SyncBackend {
  SupabaseSyncBackend(this._client);

  static const _pageSize = 1000;
  static const _pushBatchSize = 500;

  final SupabaseClient _client;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  String? get email => _client.auth.currentUser?.email;

  @override
  Stream<bool> get signedInChanges => _client.auth.onAuthStateChange
      .map((state) => state.session != null)
      .distinct();

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthRetryableFetchException {
      throw const SignInFailure(SignInFailureReason.network);
    } on AuthException {
      throw const SignInFailure(SignInFailureReason.invalidCredentials);
    } on Exception {
      throw const SignInFailure(SignInFailureReason.network);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<List<RemoteTask>> tasksSince(DateTime? cursor) async {
    final tasks = <RemoteTask>[];
    while (true) {
      var query = _client.from('tasks').select();
      if (cursor != null) {
        query = query.gt('synced_at', cursor.toUtc().toIso8601String());
      }
      final page = await query
          .order('synced_at', ascending: true)
          .order('id', ascending: true)
          .range(tasks.length, tasks.length + _pageSize - 1);
      tasks.addAll(page.map(remoteTaskFromRow));
      if (page.length < _pageSize) return tasks;
    }
  }

  @override
  Future<void> pushTasks(List<Task> tasks) async {
    for (var i = 0; i < tasks.length; i += _pushBatchSize) {
      final end = i + _pushBatchSize < tasks.length
          ? i + _pushBatchSize
          : tasks.length;
      final rows = tasks.sublist(i, end).map(taskToRow).toList();
      try {
        await _upsertTasks(rows);
      } on PostgrestException catch (error) {
        // Serveur pas encore migré (supabase/migrations/002) : la colonne
        // `completed_at` est inconnue. La synchronisation continue sans elle.
        if (!_completedAtSupported || !error.message.contains('completed_at')) {
          rethrow;
        }
        _completedAtSupported = false;
        debugPrint('Colonne completed_at absente sur le serveur.');
        await _upsertTasks(rows);
      }
    }
  }

  bool _completedAtSupported = true;

  Future<void> _upsertTasks(List<Map<String, Object?>> rows) =>
      _client.from('tasks').upsert([
        for (final row in rows)
          if (_completedAtSupported)
            row
          else
            Map.of(row)..remove('completed_at'),
      ], onConflict: 'id');

  @override
  Future<RemoteSettings?> fetchSettings() async {
    final row = await _client.from('settings').select().maybeSingle();
    return row == null ? null : remoteSettingsFromRow(row);
  }

  @override
  Future<void> pushSettings(AppSettings settings, DateTime updatedAt) async {
    await _client.from('settings').upsert({
      ...settingsToRow(settings, updatedAt),
      'user_id': _client.auth.currentUser!.id,
    }, onConflict: 'user_id');
  }

  @override
  Future<void> Function() subscribe(VoidCallback onChange) {
    final channel = _client.channel('planning');
    for (final table in const ['tasks', 'settings']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => onChange(),
      );
    }
    channel.subscribe((status, [error]) {
      // Au rétablissement du canal, rattrape ce qui a été manqué entre-temps.
      if (status == RealtimeSubscribeStatus.subscribed) onChange();
    });
    return () => _client.removeChannel(channel);
  }
}
