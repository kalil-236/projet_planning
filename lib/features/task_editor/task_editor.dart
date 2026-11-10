import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/breakpoints.dart';
import '../../core/french_format.dart';
import '../../domain/category.dart';
import '../../domain/local_date.dart';
import '../../domain/local_time.dart';
import '../../domain/task.dart';
import '../shared/common_widgets.dart';
import '../shared/task_visuals.dart';

/// Formulaire d'ajout ([task] nul) ou de modification.
Future<void> showTaskEditor(BuildContext context, {Task? task}) {
  final width = MediaQuery.sizeOf(context).width;
  if (ShellLayout.forWidth(width) == ShellLayout.mobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (_) => TaskEditorForm(task: task),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: TaskEditorForm(task: task),
      ),
    ),
  );
}

class TaskEditorForm extends ConsumerStatefulWidget {
  const TaskEditorForm({this.task, super.key});

  final Task? task;

  @override
  ConsumerState<TaskEditorForm> createState() => _TaskEditorFormState();
}

class _TaskEditorFormState extends ConsumerState<TaskEditorForm> {
  static const _maxTitleLength = 120;
  static const _defaultDuration = 60;
  static const _reminderChoices = <int?>[null, 0, 5, 10, 15, 30, 60];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late LocalDate _date;
  late LocalTime _start;
  late LocalTime _end;
  late TaskCategory _category;
  late int? _reminder;
  late TaskStatus _status;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final now = ref.read(nowProvider);
    final start = task?.start ?? _nextHour(now.time);
    _title = TextEditingController(text: task?.title ?? '');
    _notes = TextEditingController(text: task?.notes ?? '');
    _date = task?.date ?? now.date;
    _start = start;
    _end =
        task?.end ??
        start.plusMinutes(_defaultDuration) ??
        const LocalTime(23, 59);
    _category = task?.category ?? TaskCategory.autre;
    _reminder = task?.reminderBeforeMin;
    _status = task?.status ?? TaskStatus.todo;
  }

  LocalTime _nextHour(LocalTime now) =>
      now.hour >= 22 ? const LocalTime(22, 0) : LocalTime(now.hour + 1, 0);

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      firstDate: today.addDays(-365).toDateTime(),
      lastDate: today.addDays(730).toDateTime(),
    );
    if (picked != null) setState(() => _date = LocalDate.fromDateTime(picked));
  }

  Future<void> _pickStart() async {
    final picked = await pickLocalTime(context, _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await pickLocalTime(context, _end);
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _save() async {
    final titleValid = _formKey.currentState!.validate();
    final timeValid = _end.isAfter(_start);
    setState(() {
      _timeError = timeValid ? null : 'La fin doit être après le début.';
    });
    if (!titleValid || !timeValid) return;

    final navigator = Navigator.of(context);
    final service = ref.read(planningServiceProvider);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text;
    final task = widget.task;
    if (task == null) {
      await service.addTask(
        title: _title.text,
        date: _date,
        start: _start,
        end: _end,
        category: _category,
        notes: notes,
        reminderBeforeMin: _reminder,
      );
    } else {
      await service.updateTask(
        task,
        task.copyWith(
          title: _title.text,
          date: _date,
          start: _start,
          end: _end,
          category: _category,
          notes: notes,
          reminderBeforeMin: _reminder,
          status: _status,
        ),
      );
    }
    navigator.pop();
  }

  String _reminderLabel(int? minutes, int fallback) => switch (minutes) {
    null => 'Par défaut ($fallback min)',
    0 => 'Aucun',
    _ => '$minutes min avant',
  };

  @override
  Widget build(BuildContext context) {
    final fallback = ref.watch(currentSettingsProvider).defaultReminderMin;
    final reminderChoices = {..._reminderChoices, _reminder}.toList();
    final isEditing = widget.task != null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Modifier la tâche' : 'Nouvelle tâche',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              autofocus: !isEditing,
              maxLength: _maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Le titre est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 8),
            _PickerField(
              label: 'Date',
              value: formatFullDate(_date),
              icon: LucideIcons.calendarDays,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Début',
                    value: _start.toHHmm(),
                    icon: LucideIcons.clock,
                    onTap: _pickStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Fin',
                    value: _end.toHHmm(),
                    icon: LucideIcons.clock,
                    onTap: _pickEnd,
                  ),
                ),
              ],
            ),
            if (_timeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _timeError!,
                  style: TextStyle(color: context.colors.destructive),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final category in TaskCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(categoryIcon(category), size: 20),
                        const SizedBox(width: 8),
                        Text(category.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _reminder,
              decoration: const InputDecoration(labelText: 'Rappel'),
              items: [
                for (final minutes in reminderChoices)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(_reminderLabel(minutes, fallback)),
                  ),
              ],
              onChanged: (value) => setState(() => _reminder = value),
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: [
                  for (final status in TaskStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon, size: 20),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
