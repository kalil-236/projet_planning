import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Planning reçu d'une autre application : fichier ouvert avec F.R.I.D.A.Y,
/// ou fichier et texte partagés vers elle.
@immutable
class SharedPlan {
  const SharedPlan({required this.name, this.text, this.error});

  final String name;
  final String? text;

  /// Lecture impossible côté Android : affichée à la place de l'aperçu.
  final String? error;

  static SharedPlan? fromPlatform(Object? value) {
    if (value is! Map) return null;
    return SharedPlan(
      name: value['name'] as String? ?? 'Fichier partagé',
      text: value['text'] as String?,
      error: value['error'] as String?,
    );
  }
}

abstract interface class SharedPlanSource {
  /// Contenu qui a lancé l'application, lu une seule fois.
  Future<SharedPlan?> initial();

  /// Contenus reçus pendant que l'application est ouverte.
  Stream<SharedPlan> get incoming;
}

/// Pont avec `MainActivity.kt`.
class AndroidSharedPlanSource implements SharedPlanSource {
  AndroidSharedPlanSource() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'shared') return;
      final plan = SharedPlan.fromPlatform(call.arguments);
      if (plan != null) _controller.add(plan);
    });
  }

  static const _channel = MethodChannel('friday/shared_plan');

  final _controller = StreamController<SharedPlan>.broadcast();

  @override
  Future<SharedPlan?> initial() async =>
      SharedPlan.fromPlatform(await _channel.invokeMethod<Object?>('initial'));

  @override
  Stream<SharedPlan> get incoming => _controller.stream;
}

/// `null` hors d'Android.
final sharedPlanSourceProvider = Provider<SharedPlanSource?>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? AndroidSharedPlanSource()
      : null,
);

/// Dernier planning reçu, en attente d'affichage par l'écran Importer.
class PendingSharedPlanNotifier extends Notifier<SharedPlan?> {
  @override
  SharedPlan? build() {
    final source = ref.watch(sharedPlanSourceProvider);
    if (source == null) return null;
    final subscription = source.incoming.listen(receive);
    ref.onDispose(subscription.cancel);
    unawaited(
      source.initial().then((plan) {
        if (plan != null) receive(plan);
      }, onError: (Object error) => debugPrint('Partage illisible : $error')),
    );
    return null;
  }

  void receive(SharedPlan plan) => state = plan;

  /// Renvoie le planning en attente et le retire.
  SharedPlan? take() {
    final plan = state;
    state = null;
    return plan;
  }
}

final pendingSharedPlanProvider =
    NotifierProvider<PendingSharedPlanNotifier, SharedPlan?>(
      PendingSharedPlanNotifier.new,
    );
