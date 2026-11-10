import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../core/french_format.dart';
import '../../domain/day_gaps.dart';
import '../../domain/local_time.dart';
import '../../domain/task.dart';
import 'swipe_actions.dart';
import 'task_visuals.dart';
import 'timeline_layout.dart';

/// Colonne des heures, à gauche d'une ou plusieurs [TimelineColumn].
class HourGutter extends StatelessWidget {
  const HourGutter({required this.scale, super.key});

  static const width = 48.0;

  final TimelineScale scale;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: context.colors.mutedForeground);
    return SizedBox(
      width: width,
      height: scale.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final minutes in scale.hours)
            Positioned(
              top: scale.yOfMinutes(minutes) - 8,
              right: 8,
              child: Text('${minutes ~/ 60}h', style: style),
            ),
        ],
      ),
    );
  }
}

class TimelineColumn extends StatelessWidget {
  const TimelineColumn({
    required this.tasks,
    required this.scale,
    required this.onTaskTap,
    this.now,
    this.highlighted = false,
    this.freeSlots = const [],
    this.onFreeSlotTap,
    this.conflictIds = const {},
    super.key,
  });

  /// Heure du trait « maintenant », ou `null` hors de la journée en cours.
  final LocalTime? now;
  final List<Task> tasks;

  /// Trous de la journée, affichés en pointillés entre les tâches.
  final List<FreeSlot> freeSlots;
  final ValueChanged<FreeSlot>? onFreeSlotTap;

  /// Tâches qui en chevauchent une autre : marquées d'un avertissement.
  final Set<String> conflictIds;
  final TimelineScale scale;
  final ValueChanged<Task> onTaskTap;
  final bool highlighted;

  static const _baseMinBlockHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final minHeight = MediaQuery.textScalerOf(context)
        .scale(_baseMinBlockHeight);
    final items = layoutTimeline(
      tasks: tasks,
      scale: scale,
      minHeight: minHeight,
    );
    final current = now;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: scale.height,
          color: highlighted ? colors.muted : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final minutes in scale.hours)
                Positioned(
                  top: scale.yOfMinutes(minutes),
                  left: 0,
                  right: 0,
                  height: 1,
                  child: ColoredBox(color: colors.border),
                ),
              for (final slot in freeSlots)
                Positioned(
                  key: ValueKey('free-${slot.start}'),
                  top: scale.yOf(slot.start) + 2,
                  height: scale.yOf(slot.end) - scale.yOf(slot.start) - 4,
                  left: 2,
                  right: 2,
                  child: FreeSlotBlock(
                    slot: slot,
                    onTap: onFreeSlotTap == null
                        ? null
                        : () => onFreeSlotTap!(slot),
                  ),
                ),
              for (final item in items)
                Positioned(
                  key: ValueKey('task-${item.task.id}'),
                  top: item.top,
                  height: item.height,
                  left: item.column * width / item.columnCount + 2,
                  width: width / item.columnCount - 4,
                  child: SwipeableTask(
                    task: item.task,
                    child: TaskBlock(
                      task: item.task,
                      conflict: conflictIds.contains(item.task.id),
                      onTap: () => onTaskTap(item.task),
                    ),
                  ),
                ),
              if (current != null && scale.contains(current))
                Positioned(
                  key: const ValueKey('now-line'),
                  top: scale.yOf(current) - 1,
                  left: 0,
                  right: 0,
                  height: 2,
                  child: IgnorePointer(
                    child: Semantics(
                      label: 'Maintenant, ${formatHour(current)}',
                      child: ColoredBox(color: colors.primaryOnSurface),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TaskBlock extends StatelessWidget {
  const TaskBlock({
    required this.task,
    required this.onTap,
    this.conflict = false,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;
  final bool conflict;

  static const _tintOpacity = 0.16;
  static const _inactiveOpacity = 0.65;
  static const _barWidth = 4.0;
  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final color = colors.categoryColor(task.category);
    final state = task.displayState;
    final inactive =
        state == TaskDisplayState.done ||
        state == TaskDisplayState.cancelled ||
        state == TaskDisplayState.missed;

    final content = ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minHeight: 0,
        maxHeight: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    categoryIcon(task.category),
                    size: 20,
                    color: colors.foreground,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w600,
                        decoration: state == TaskDisplayState.cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                formatTimeRange(task.start, task.end),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(color: colors.foreground),
              ),
              if (state != TaskDisplayState.todo) TaskStateBadge(state: state),
              if (conflict) const ConflictBadge(),
            ],
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: inactive ? _inactiveOpacity : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      child: Material(
        color: Color.alphaBlend(
          color.withValues(alpha: _tintOpacity),
          colors.surface,
        ),
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: color,
                child: const SizedBox(width: _barWidth),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne de liste d'une tâche, pour la vue semaine sur mobile.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.task,
    required this.onTap,
    this.conflict = false,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          categoryIcon(task.category),
          size: 20,
          color: colors.foreground,
        ),
        title: Text(task.title),
        subtitle: Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(formatTimeRange(task.start, task.end)),
            TaskStateBadge(state: task.displayState),
            if (conflict) const ConflictBadge(),
          ],
        ),
      ),
    );
  }
}

/// Avertissement : la tâche en chevauche une autre.
class ConflictBadge extends StatelessWidget {
  const ConflictBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.triangleAlert, size: 20, color: colors.destructive),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Chevauchement',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.foreground),
          ),
        ),
      ],
    );
  }
}

/// Créneau libre : cadre en pointillés, touché pour y ajouter une tâche.
class FreeSlotBlock extends StatelessWidget {
  const FreeSlotBlock({required this.slot, this.onTap, super.key});

  final FreeSlot slot;
  final VoidCallback? onTap;

  static const _radius = Radius.circular(8);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: colors.mutedForeground);
    final range = '${formatHour(slot.start)} – ${formatHour(slot.end)}';
    return Semantics(
      button: onTap != null,
      label:
          'Créneau libre de $range, ${formatDuration(slot.minutes)}. '
          'Ajouter une tâche',
      excludeSemantics: true,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colors.mutedForeground,
          radius: _radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(_radius),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: colors.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Libre · ${formatDuration(slot.minutes)} · $range',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final Radius radius;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, radius));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
