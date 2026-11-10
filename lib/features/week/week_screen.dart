import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/destinations.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/breakpoints.dart';
import '../../core/french_format.dart';
import '../../domain/app_settings.dart';
import '../../domain/local_date.dart';
import '../../domain/local_time.dart';
import '../../domain/task.dart';
import '../shared/common_widgets.dart';
import '../shared/timeline_layout.dart';
import '../shared/timeline_widgets.dart';
import '../task_editor/task_detail.dart';

class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  static const _tabletDayCount = 3;

  void _select(LocalDate? day) =>
      ref.read(weekSelectedDayProvider.notifier).select(day);

  void _moveWeek(LocalDate selected, int weeks) =>
      _select(selected.addDays(weeks * 7));

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider);
    final settings = ref.watch(currentSettingsProvider);
    final selected = ref.watch(weekSelectedDayProvider) ?? now.date;
    final monday = selected.monday;
    final days = [for (var i = 0; i < 7; i++) monday.addDays(i)];
    final tasksAsync = ref.watch(
      tasksInRangeProvider(DateRange(monday, days.last)),
    );
    final layout = ShellLayout.forWidth(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppDestination.week.label),
        actions: [
          IconButton(
            onPressed: () => _moveWeek(selected, -1),
            tooltip: 'Semaine précédente',
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          TextButton(
            onPressed: () => _select(null),
            child: const Text("Aujourd'hui"),
          ),
          IconButton(
            onPressed: () => _moveWeek(selected, 1),
            tooltip: 'Semaine suivante',
            icon: const Icon(LucideIcons.chevronRight),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              formatWeekRange(monday),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (layout != ShellLayout.desktop)
            _WeekStrip(
              days: days,
              selected: selected,
              today: now.date,
              onSelected: _select,
            ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const LoadingSkeleton(),
              error: (error, _) => EmptyState(
                icon: LucideIcons.info,
                message: 'Impossible de lire le planning : $error',
              ),
              data: (tasks) => tasks.isEmpty
                  ? EmptyState(
                      illustration: AppIllustration.noPlan,
                      message: 'Aucun planning importé pour cette semaine',
                      action: FilledButton.icon(
                        onPressed: () =>
                            context.go(AppDestination.importPlan.path),
                        icon: const Icon(LucideIcons.fileUp),
                        label: const Text('Importer un planning'),
                      ),
                    )
                  : switch (layout) {
                      ShellLayout.mobile => _DayList(
                        tasks: tasks.where((t) => t.date == selected).toList(),
                        onTaskTap: (task) => openTaskDetail(context, ref, task),
                      ),
                      ShellLayout.tablet => _WeekGrid(
                        days: _tabletDays(days, selected),
                        selected: selected,
                        tasks: tasks,
                        settings: settings,
                        now: now,
                        onTaskTap: (task) => openTaskDetail(context, ref, task),
                      ),
                      ShellLayout.desktop => _WeekGrid(
                        days: days,
                        selected: selected,
                        tasks: tasks,
                        settings: settings,
                        now: now,
                        onTaskTap: (task) => openTaskDetail(context, ref, task),
                      ),
                    },
            ),
          ),
        ],
      ),
    );
  }

  /// Trois jours à partir du jour choisi, sans sortir de la semaine.
  List<LocalDate> _tabletDays(List<LocalDate> days, LocalDate selected) {
    final index = days
        .indexOf(selected)
        .clamp(0, days.length - _tabletDayCount);
    return days.sublist(index, index + _tabletDayCount);
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.today,
    required this.onSelected,
  });

  final List<LocalDate> days;
  final LocalDate selected;
  final LocalDate today;
  final ValueChanged<LocalDate> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: _DayChip(
                day: day,
                isSelected: day == selected,
                isToday: day == today,
                onTap: () => onSelected(day),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final LocalDate day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isSelected ? colors.onPrimary : colors.foreground;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: isSelected,
      button: true,
      label: isToday ? "Aujourd'hui" : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Material(
          color: isSelected ? colors.primary : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: _radius,
            side: BorderSide(
              color: isToday ? colors.primaryOnSurface : colors.border,
              width: isToday ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: _radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    weekdayShort(day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(color: foreground),
                  ),
                  Text(
                    '${day.day}',
                    style: text.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.tasks, required this.onTaskTap});

  final List<Task> tasks;
  final ValueChanged<Task> onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.calendarDays,
        message: 'Rien de prévu ce jour',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => TaskListTile(
        task: tasks[index],
        onTap: () => onTaskTap(tasks[index]),
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.days,
    required this.selected,
    required this.tasks,
    required this.settings,
    required this.now,
    required this.onTaskTap,
  });

  final List<LocalDate> days;
  final LocalDate selected;
  final List<Task> tasks;
  final AppSettings settings;
  final LocalDateTime now;
  final ValueChanged<Task> onTaskTap;

  @override
  Widget build(BuildContext context) {
    final visible = tasks.where((t) => days.contains(t.date)).toList();
    final scale = TimelineScale.covering(
      dayStart: settings.dayStart,
      dayEnd: settings.dayEnd,
      tasks: visible,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: HourGutter.width,
            right: 16,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: [
              for (final day in days)
                Expanded(
                  child: _GridDayHeader(
                    day: day,
                    today: now.date,
                    isSelected: day == selected,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 12, 16, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HourGutter(scale: scale),
                for (final day in days)
                  Expanded(
                    child: TimelineColumn(
                      tasks: visible.where((t) => t.date == day).toList(),
                      scale: scale,
                      now: _nowFor(day),
                      highlighted: day == now.date,
                      onTaskTap: onTaskTap,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  LocalTime? _nowFor(LocalDate day) => day == now.date ? now.time : null;
}

class _GridDayHeader extends StatelessWidget {
  const _GridDayHeader({
    required this.day,
    required this.today,
    required this.isSelected,
  });

  final LocalDate day;
  final LocalDate today;

  /// Jour choisi au clavier (`←` et `→`).
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isToday = day == today;
    final colors = context.colors;
    final label = '${weekdayShort(day)} ${day.day}';
    return Semantics(
      selected: isSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.muted : null,
          border: Border(
            bottom: BorderSide(
              color: isToday ? colors.primaryOnSurface : colors.border,
              width: isToday ? 2 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.foreground,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
