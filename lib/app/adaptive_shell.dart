import 'package:flutter/material.dart';

import '../core/breakpoints.dart';
import 'destinations.dart';

/// Cadre commun : barre du bas, rail ou barre latérale selon la largeur.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
        );
      },
    );
  }
}
