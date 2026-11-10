import 'package:flutter/foundation.dart';

import '../domain/app_settings.dart';
import '../domain/task.dart';

@immutable
class RemoteTask {
  const RemoteTask({required this.task, required this.syncedAt});

  final Task task;

  /// Instant de réception par le serveur.
  final DateTime syncedAt;
}

@immutable
class RemoteSettings {
  const RemoteSettings({required this.settings, required this.updatedAt});

  final AppSettings settings;
  final DateTime updatedAt;
}

enum SignInFailureReason { invalidCredentials, network }

class SignInFailure implements Exception {
  const SignInFailure(this.reason);

  final SignInFailureReason reason;
}

/// Accès au serveur de synchronisation, isolé pour les tests.
abstract interface class SyncBackend {
  bool get isSignedIn;

  String? get email;

  Stream<bool> get signedInChanges;

  /// Lève une [SignInFailure] si la connexion échoue.
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Tâches reçues par le serveur après [cursor], suppressions comprises.
  Future<List<RemoteTask>> tasksSince(DateTime? cursor);

  Future<void> pushTasks(List<Task> tasks);

  Future<RemoteSettings?> fetchSettings();

  Future<void> pushSettings(AppSettings settings, DateTime updatedAt);

  /// Écoute les changements en direct. Renvoie la fonction d'arrêt.
  Future<void> Function() subscribe(VoidCallback onChange);
}
