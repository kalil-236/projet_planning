import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/breakpoints.dart';
import '../../core/french_format.dart';
import '../../domain/task.dart';
import '../shared/common_widgets.dart';
import '../shared/shift_dialogs.dart';
import '../shared/task_visuals.dart';
import 'task_editor.dart';

/// Ouvre le détail : panneau à droite sur PC, feuille du bas sinon (9.1).
void openTaskDetail(BuildContext context, WidgetRef ref, Task task) {
  final width = MediaQuery.sizeOf(context).width;
  if (ShellLayout.forWidth(width) == ShellLayout.desktop) {
    ref.read(selectedTaskIdProvider.notifier).select(task.id);
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (sheet) => TaskDetailView(
      taskId: task.id,
      onClose: () => Navigator.pop(sheet),
      closeAfterAction: true,
    ),
  );
}

class TaskDetailView extends ConsumerWidget {
  const TaskDetailView({
    required this.taskId,
    required this.onClose,
    this.closeAfterAction = false,
    super.key,
  });

  final String taskId;
  final VoidCallback onClose;

  /// Vrai pour la feuille du bas, qui se ferme une fois l'action faite.
  final bool closeAfterAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskByIdProvider(taskId));
    final task = async.value;
    if (task == null) {
      return async.isLoading
          ? const LoadingSkeleton()
          : const SizedBox.shrink();
    }
    final service = ref.read(planningServiceProvider);

    void done() {
      if (closeAfterAction) onClose();
    }

    Future<void> setStatus(TaskStatus status) async {
      await service.setStatus(task, status);
      done();
    }

    Future<void> delete() async {
      if (await _confirmDelete(context)) {
        await service.deleteTask(task);
        onClose();
      }
    }

    final isTodo = task.status == TaskStatus.todo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(task: task, onClose: onClose),
          const SizedBox(height: 8),
          TaskStateBadge(state: task.displayState),
          const SizedBox(height: 16),
          _InfoLine(
            icon: LucideIcons.calendarDays,
            text: formatFullDate(task.date),
          ),
          _InfoLine(
            icon: LucideIcons.clock,
            text: formatTimeRange(task.start, task.end),
          ),
          if (task.originalStart != null)
            _InfoLine(
              icon: LucideIcons.calendarClock,
              text: 'Décalée, initialement à ${task.originalStart!.toHHmm()}',
            ),
          _InfoLine(
            icon: categoryIcon(task.category),
            text: task.category.label,
          ),
          _InfoLine(icon: LucideIcons.bell, text: _reminderLabel(task, ref)),
          if (task.notes != null)
            _InfoLine(icon: LucideIcons.info, text: task.notes!),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isTodo) ...[
                FilledButton.icon(
                  onPressed: () => setStatus(TaskStatus.done),
                  icon: const Icon(LucideIcons.check),
                  label: const Text('Fait'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await showShiftTaskDialog(context, ref, task);
                    done();
                  },
                  icon: const Icon(LucideIcons.calendarClock),
                  label: const Text('Décaler'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setStatus(TaskStatus.cancelled),
                  icon: const Icon(LucideIcons.x),
                  label: const Text('Annuler'),
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: () => setStatus(TaskStatus.todo),
                  icon: const Icon(LucideIcons.clock),
                  label: const Text('Remettre à faire'),
                ),
              OutlinedButton.icon(
                onPressed: () => showTaskEditor(context, task: task),
                icon: const Icon(LucideIcons.pencil),
                label: const Text('Modifier'),
              ),
              TextButton.icon(
                onPressed: delete,
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.destructive,
                ),
                icon: const Icon(LucideIcons.trash2),
                label: const Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _reminderLabel(Task task, WidgetRef ref) {
    final minutes = task.reminderBeforeMin;
    if (minutes == null) {
      final fallback = ref.read(currentSettingsProvider).defaultReminderMin;
      return 'Rappel par défaut ($fallback min avant)';
    }
    return minutes == 0 ? 'Pas de pré-rappel' : 'Rappel $minutes min avant';
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Supprimer cette tâche ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.task, required this.onClose});

  final Task task;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              task.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: 'Fermer',
          icon: const Icon(LucideIcons.x),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.colors.mutedForeground),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
