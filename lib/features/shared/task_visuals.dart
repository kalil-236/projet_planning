import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../domain/category.dart';
import '../../domain/task.dart';

IconData categoryIcon(TaskCategory category) => switch (category) {
  TaskCategory.cours => LucideIcons.graduationCap,
  TaskCategory.etude => LucideIcons.bookOpen,
  TaskCategory.activite => LucideIcons.dumbbell,
  TaskCategory.repos => LucideIcons.coffee,
  TaskCategory.autre => LucideIcons.circleDot,
};

IconData stateIcon(TaskDisplayState state) => switch (state) {
  TaskDisplayState.todo => LucideIcons.clock,
  TaskDisplayState.done => LucideIcons.circleCheck,
  TaskDisplayState.cancelled => LucideIcons.circleX,
  TaskDisplayState.shifted => LucideIcons.calendarClock,
  TaskDisplayState.missed => LucideIcons.info,
};

Color stateColor(AppColors colors, TaskDisplayState state) => switch (state) {
  TaskDisplayState.todo => colors.mutedForeground,
  TaskDisplayState.done => colors.accent,
  TaskDisplayState.cancelled => colors.destructive,
  TaskDisplayState.shifted => colors.primaryOnSurface,
  TaskDisplayState.missed => colors.mutedForeground,
};

/// État d'une tâche : toujours une icône et un texte.
class TaskStateBadge extends StatelessWidget {
  const TaskStateBadge({required this.state, super.key});

  final TaskDisplayState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(stateIcon(state), size: 20, color: stateColor(colors, state)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            state.label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.foreground),
          ),
        ),
      ],
    );
  }
}
