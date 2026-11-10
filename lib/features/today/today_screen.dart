import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/destinations.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/french_format.dart';
import '../../domain/app_settings.dart';
import '../../domain/day_gaps.dart';
import '../../domain/local_date.dart';
import '../../domain/local_time.dart';
import '../../domain/task.dart';
import '../../domain/task_draft.dart';
import '../../domain/task_ops.dart';
import '../shared/common_widgets.dart';
import '../shared/shift_dialogs.dart';
import '../shared/timeline_layout.dart';
import '../shared/timeline_widgets.dart';
import '../task_editor/task_detail.dart';
import '../task_editor/task_editor.dart';
import 'quick_add_bar.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final settings = ref.watch(currentSettingsProvider);
    final range = DateRange(now.date, now.date);
    final tasksAsync = ref.watch(tasksInRangeProvider(range));

    return Scaffold(
      appBar: AppBar(title: Text(AppDestination.today.label)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskEditor(context),
        tooltip: 'Ajouter une tâche',
        child: const Icon(LucideIcons.plus),
      ),
      body: tasksAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          icon: LucideIcons.info,
          message: 'Impossible de lire le planning : $error',
        ),
        data: (tasks) {
          final today = tasksForToday(tasks, now.date);
          return _TodayBody(
            key: ValueKey(now.date),
            now: now,
            tasks: today,
            settings: settings,
          );
        },
      ),
    );
  }
}

class _TodayBody extends ConsumerStatefulWidget {
  const _TodayBody({
    required this.now,
    required this.tasks,
    required this.settings,
    super.key,
  });

  final LocalDateTime now;
  final List<Task> tasks;
  final AppSettings settings;

  @override
  ConsumerState<_TodayBody> createState() => _TodayBodyState();
}

class _TodayBodyState extends ConsumerState<_TodayBody> {
  static const _nowLineMargin = 120.0;

  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: math.max(
      0,
      _scale.yOf(widget.now.time) - _nowLineMargin,
    ),
  );

  TimelineScale get _scale => TimelineScale.covering(
    dayStart: widget.settings.dayStart,
    dayEnd: widget.settings.dayEnd,
    tasks: widget.tasks,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final now = widget.now;
    final tasks = widget.tasks;
    final scale = _scale;
    final slots = freeSlots(
      tasks: tasks,
      dayStart: widget.settings.dayStart,
      dayEnd: widget.settings.dayEnd,
      from: now.time,
    );
    final conflicts = overlappingTaskIds(tasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatFullDate(now.date), style: text.titleMedium),
              const SizedBox(height: 8),
              const QuickAddBar(),
              if (tasks.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  daySummary(tasks, now.time),
                  style: TextStyle(color: colors.mutedForeground),
                ),
                if (conflicts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        size: 20,
                        color: colors.destructive,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${conflicts.length} tâches se chevauchent',
                          style: TextStyle(color: colors.foreground),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => showShiftDayDialog(context),
                  icon: const Icon(LucideIcons.calendarClock),
                  label: const Text('Décaler toute la journée'),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? EmptyState(
                  illustration: AppIllustration.nothingToday,
                  message: "Rien de prévu aujourd'hui",
                  action: FilledButton.icon(
                    onPressed: () => context.go(AppDestination.importPlan.path),
                    icon: const Icon(LucideIcons.fileUp),
                    label: const Text('Importer un planning'),
                  ),
                )
              : SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 88),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HourGutter(scale: scale),
                      Expanded(
                        child: TimelineColumn(
                          tasks: tasks,
                          scale: scale,
                          now: now.time,
                          freeSlots: slots,
                          conflictIds: conflicts,
                          onFreeSlotTap: (slot) => showTaskEditor(
                            context,
                            draft: TaskDraft(
                              date: now.date,
                              start: slot.start,
                              end: slot.end,
                            ),
                          ),
                          onTaskTap: (task) =>
                              openTaskDetail(context, ref, task),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
