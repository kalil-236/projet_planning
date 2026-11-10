import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../domain/local_date.dart';
import '../domain/task.dart';
import 'providers.dart';

/// Messager racine : affiche les rappels quel que soit l'écran ouvert.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Sur le web, rien ne sonne une fois l'onglet fermé (1, 10.7). Tant qu'il est
/// ouvert, un bandeau « C'est l'heure » s'affiche au début de chaque tâche.
final inAppRemindersEnabledProvider = Provider<bool>((ref) => kIsWeb);

const _reminderDuration = Duration(seconds: 15);

final inAppRemindersProvider = Provider<void>((ref) {
  if (!ref.watch(inAppRemindersEnabledProvider)) return;
  final shown = <String>{};
  ref.listen(nowProvider, (previous, now) async {
    if (previous == null || previous.time == now.time) return;
    final tasks = await ref
        .read(taskRepositoryProvider)
        .activeInRange(DateRange(now.date, now.date));
    for (final task in tasks) {
      final key = '${task.id}|${task.date}|${task.start}';
      if (task.status != TaskStatus.todo ||
          task.start != now.time ||
          !shown.add(key)) {
        continue;
      }
      rootMessengerKey.currentState?.showSnackBar(
        SnackBar(
          duration: _reminderDuration,
          showCloseIcon: true,
          content: Row(
            children: [
              const Icon(LucideIcons.bellRing),
              const SizedBox(width: 12),
              Expanded(child: Text("C'est l'heure : ${task.title}")),
            ],
          ),
        ),
      );
    }
  });
});

/// Mouvement réduit (8.5) : changement d'écran sans animation.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

final reducedMotionTransitions = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: NoTransitionsBuilder(),
  },
);
