import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification_plan.dart';
import '../notifications/notification_actions.dart';
import 'destinations.dart';
import 'providers.dart';
import 'router.dart';

/// Demandes de lecture du briefing (bouton « Écouter » du résumé du matin).
class BriefingRequestNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final briefingRequestProvider = NotifierProvider<BriefingRequestNotifier, int>(
  BriefingRequestNotifier.new,
);

/// Ouvre l'écran que désigne une notification touchée : Bilan pour le bilan
/// de la semaine, Aujourd'hui pour le reste.
final notificationNavigationProvider = Provider<void>((ref) {
  final gateway = ref.watch(notificationGatewayProvider);
  if (gateway == null) return;

  void open(String payload) {
    final router = ref.read(routerProvider);
    if (payload == reportPayload) {
      router.go(AppDestination.report.path);
      return;
    }
    router.go(AppDestination.today.path);
    if (payload == listenPayload) {
      ref.read(briefingRequestProvider.notifier).request();
    }
  }

  final subscription = notificationTaps.stream.listen(open);
  ref.onDispose(subscription.cancel);
  unawaited(
    gateway.launchPayload().then((payload) {
      if (payload != null) open(payload);
    }, onError: (Object error) => debugPrint('Lancement : $error')),
  );
});
