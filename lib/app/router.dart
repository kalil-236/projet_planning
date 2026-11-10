import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/import_plan/import_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/today_screen.dart';
import '../features/week/week_screen.dart';
import 'adaptive_shell.dart';
import 'destinations.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppDestination.today.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdaptiveShell(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            ref.read(selectedTaskIdProvider.notifier).select(null);
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          child: navigationShell,
        ),
        branches: [
          for (final destination in AppDestination.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: destination.path,
                  builder: (context, state) => _screenFor(destination),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Widget _screenFor(AppDestination destination) => switch (destination) {
  AppDestination.today => const TodayScreen(),
  AppDestination.week => const WeekScreen(),
  AppDestination.importPlan => const ImportScreen(),
  AppDestination.settings => const SettingsScreen(),
};
