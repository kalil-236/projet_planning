import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/french_format.dart';
import '../../domain/local_time.dart';
import '../../domain/task.dart';
import '../../domain/task_ops.dart';
import 'common_widgets.dart';

const _midnightMessage =
    'Décalage impossible : la tâche se terminerait après minuit.';
const _pickTimeChoice = -1;

Future<void> showShiftTaskDialog(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final service = ref.read(planningServiceProvider);

  final choice = await showDialog<int>(
    context: context,
    builder: (dialog) => SimpleDialog(
      title: const Text('Décaler la tâche'),
      children: [
        for (final minutes in const [15, 30, 60])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialog, minutes),
            child: _DialogLine(icon: LucideIcons.clock, label: '+$minutes min'),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialog, _pickTimeChoice),
          child: const _DialogLine(
            icon: LucideIcons.calendarClock,
            label: 'Choisir une heure',
          ),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;

  final bool shifted;
  if (choice == _pickTimeChoice) {
    final time = await pickLocalTime(context, task.start);
    if (time == null) return;
    shifted = await service.shiftTo(task, time);
  } else {
    shifted = await service.shiftBy(task, choice);
  }
  if (!shifted) showMessage(messenger, _midnightMessage);
}

class _DialogLine extends StatelessWidget {
  const _DialogLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

Future<void> showShiftDayDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ShiftDayDialog(),
  );
}

class _ShiftDayDialog extends ConsumerStatefulWidget {
  const _ShiftDayDialog();

  @override
  ConsumerState<_ShiftDayDialog> createState() => _ShiftDayDialogState();
}

class _ShiftDayDialogState extends ConsumerState<_ShiftDayDialog> {
  static const _delays = [15, 30, 45, 60, 90, 120];

  int _minutes = 30;
  late Future<DayShiftPlan> _plan = _preview();

  Future<DayShiftPlan> _preview() =>
      ref.read(planningServiceProvider).previewDayShift(_minutes);

  void _select(int minutes) => setState(() {
    _minutes = minutes;
    _plan = _preview();
  });

  Future<void> _confirm(DayShiftPlan plan) async {
    final navigator = Navigator.of(context);
    await ref.read(planningServiceProvider).applyDayShift(plan);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dayEnd = ref.watch(currentSettingsProvider).dayEnd;
    return FutureBuilder<DayShiftPlan>(
      future: _plan,
      builder: (context, snapshot) {
        final plan = snapshot.data;
        return AlertDialog(
          title: const Text('Décaler toute la journée'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in _delays)
                      ChoiceChip(
                        label: Text('+$minutes min'),
                        selected: minutes == _minutes,
                        onSelected: (_) => _select(minutes),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (plan != null) _PlanSummary(plan: plan, dayEnd: dayEnd),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            FilledButton(
              onPressed: plan != null && plan.canApply
                  ? () => _confirm(plan)
                  : null,
              child: const Text('Décaler'),
            ),
          ],
        );
      },
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan, required this.dayEnd});

  final DayShiftPlan plan;
  final LocalTime dayEnd;

  @override
  Widget build(BuildContext context) {
    final count = plan.shifted.length;
    final blocked = plan.blockedByMidnight;
    final latestEnd = plan.latestEnd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(switch (count) {
          0 when blocked.isEmpty => 'Aucune tâche à décaler.',
          1 => '1 tâche sera décalée.',
          _ => '$count tâches seront décalées.',
        }),
        if (plan.exceedsDayEnd && latestEnd != null) ...[
          const SizedBox(height: 8),
          _WarningLine(
            'La dernière tâche finirait à ${formatHour(latestEnd)}, après '
            'la fin de journée (${formatHour(dayEnd)}).',
          ),
        ],
        if (blocked.isNotEmpty) ...[
          const SizedBox(height: 8),
          _WarningLine(
            'Décalage impossible : « ${blocked.first.title} » se terminerait '
            'après minuit.',
          ),
        ],
      ],
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.info, size: 20, color: context.colors.destructive),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    );
  }
}
