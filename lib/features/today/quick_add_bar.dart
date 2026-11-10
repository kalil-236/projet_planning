import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/french_format.dart';
import '../../domain/local_date.dart';
import '../../domain/quick_task.dart';
import '../../domain/task_draft.dart';
import '../shared/common_widgets.dart';
import '../shared/task_visuals.dart';
import '../task_editor/task_editor.dart';

/// Ajout express : une phrase comme « sport demain 18h 1h » crée la tâche.
class QuickAddBar extends ConsumerStatefulWidget {
  const QuickAddBar({super.key});

  @override
  ConsumerState<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends ConsumerState<QuickAddBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  QuickTaskParse? _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final now = ref.read(nowProvider);
    return parseQuickTask(text, today: now.date, now: now.time);
  }

  Future<void> _submit() async {
    final draft = _parse()?.draft;
    if (draft == null || _busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(planningServiceProvider)
          .addTask(
            title: draft.title,
            date: draft.date,
            start: draft.start,
            end: draft.end,
            category: draft.category,
            notes: null,
            reminderBeforeMin: null,
          );
      _controller.clear();
      showMessage(
        messenger,
        'Ajouté : ${draft.title}, ${_when(draft, ref.read(todayProvider))}.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDetails(TaskDraft draft) {
    _controller.clear();
    showTaskEditor(context, draft: draft);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(nowProvider);
    final result = _parse();
    final draft = result?.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.done,
          maxLength: 160,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) async {
            await _submit();
            _focus.requestFocus();
          },
          decoration: InputDecoration(
            labelText: 'Ajout express',
            hintText: 'sport demain 18h 1h',
            counterText: '',
            prefixIcon: const Icon(LucideIcons.wandSparkles),
            suffixIcon: draft == null
                ? null
                : IconButton(
                    tooltip: 'Ajouter',
                    onPressed: _busy ? null : _submit,
                    icon: const Icon(LucideIcons.cornerDownLeft),
                  ),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 6),
          if (draft != null)
            _DraftPreview(
              draft: draft,
              when: _when(draft, ref.watch(todayProvider)),
              onDetails: () => _openDetails(draft),
            )
          else
            _ParseError(message: result.error!),
        ],
      ],
    );
  }
}

/// « aujourd'hui 18h – 19h », « demain 9h – 10h » ou « jeudi 12 novembre … ».
String _when(TaskDraft draft, LocalDate today) {
  final day = draft.date == today
      ? "aujourd'hui"
      : draft.date == today.addDays(1)
      ? 'demain'
      : '${weekdayName(draft.date)} ${formatDayMonth(draft.date)}';
  return '$day, ${formatHour(draft.start)} – ${formatHour(draft.end)}';
}

class _DraftPreview extends StatelessWidget {
  const _DraftPreview({
    required this.draft,
    required this.when,
    required this.onDetails,
  });

  final TaskDraft draft;
  final String when;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(
            categoryIcon(draft.category),
            size: 20,
            color: colors.categoryColor(draft.category),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: draft.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · $when · ${draft.category.label}'),
                ],
              ),
              style: text.bodyMedium?.copyWith(color: colors.foreground),
            ),
          ),
          TextButton(onPressed: onDetails, child: const Text('Détails')),
        ],
      ),
    );
  }
}

class _ParseError extends StatelessWidget {
  const _ParseError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 20, color: colors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.foreground)),
          ),
        ],
      ),
    );
  }
}
