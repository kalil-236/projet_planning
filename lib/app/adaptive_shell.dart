import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/breakpoints.dart';
import '../features/task_editor/task_detail.dart';
import 'destinations.dart';
import 'providers.dart';

/// Cadre commun : barre du bas, rail ou barre latérale selon la largeur.
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  static const _detailPanelWidth = 340.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = ShellLayout.forWidth(constraints.maxWidth);
        if (layout == ShellLayout.mobile) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in AppDestination.values)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }

        final extended = layout == ShellLayout.desktop;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                extended: extended,
                scrollable: true,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (final destination in AppDestination.values)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(),
              Expanded(child: child),
              if (extended && selectedTaskId != null) ...[
                const VerticalDivider(),
                SizedBox(
                  width: _detailPanelWidth,
                  child: TaskDetailView(
                    key: ValueKey(selectedTaskId),
                    taskId: selectedTaskId,
                    onClose: () =>
                        ref.read(selectedTaskIdProvider.notifier).select(null),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
