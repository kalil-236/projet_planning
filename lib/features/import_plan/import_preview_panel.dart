import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/french_format.dart';
import '../../data/planning_service.dart';
import '../../domain/plan_import.dart';
import '../../domain/plan_parser.dart';
import '../shared/common_widgets.dart';

/// Aperçu avant validation (sections 5.2, 6.5 et 9.5).
class ImportPreviewPanel extends ConsumerStatefulWidget {
  const ImportPreviewPanel({
    required this.plan,
    required this.onImported,
    super.key,
  });

  final ParsedPlan plan;
  final VoidCallback onImported;

  @override
  ConsumerState<ImportPreviewPanel> createState() => _ImportPreviewPanelState();
}

class _ImportPreviewPanelState extends ConsumerState<ImportPreviewPanel> {
  bool _fromToday = true;
  ImportMode _mode = ImportMode.replace;
  bool _applyBounds = false;
  bool _busy = false;

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirm() || !mounted) return;
    setState(() => _busy = true);
    final summary = await ref
        .read(planningServiceProvider)
        .importPlan(
          plan: widget.plan,
          mode: _mode,
          fromToday: _fromToday,
          applyDayBounds: _applyBounds,
        );
    if (!mounted) return;
    showMessage(messenger, _resultMessage(summary));
    widget.onImported();
  }

  String _resultMessage(ImportSummary summary) {
    final parts = ['${summary.inserted} tâches importées'];
    if (summary.replaced > 0) parts.add('${summary.replaced} remplacées');
    if (summary.skippedDuplicates > 0) {
      parts.add('${summary.skippedDuplicates} doublons ignorés');
    }
    return '${parts.join(', ')}.';
  }

  Future<bool> _confirm() async {
    final today = ref.read(todayProvider);
    final range = importRange(
      plan: widget.plan,
      today: today,
      fromToday: _fromToday,
    );
    final message = _mode == ImportMode.replace && range != null
        ? 'Les tâches à faire du ${range.start.toIso()} au '
              '${range.end.toIso()} seront remplacées. Les tâches faites ou '
              'annulées sont conservées.'
        : 'Les tâches seront ajoutées au planning, sans doublons.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Importer ce planning ?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(currentSettingsProvider);
    final plan = widget.plan;
    final preview = buildImportPreview(
      plan: plan,
      today: ref.watch(todayProvider),
      settingsTimezone: settings.timezone,
      fromToday: _fromToday,
    );

    final dayStart = plan.dayStart;
    final dayEnd = plan.dayEnd;
    final boundsDiffer =
        dayStart != null &&
        dayEnd != null &&
        (dayStart != settings.dayStart || dayEnd != settings.dayEnd);

    final mismatch = preview.fileTimezoneMismatch;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aperçu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountTile(label: 'Passées', count: preview.pastCount),
                _CountTile(label: "Aujourd'hui", count: preview.todayCount),
                _CountTile(label: 'À venir', count: preview.upcomingCount),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _fromToday,
              onChanged: (value) => setState(() => _fromToday = value),
              title: const Text("Importer à partir d'aujourd'hui"),
              subtitle: Text(
                _fromToday
                    ? 'Les tâches passées sont ignorées.'
                    : 'Les tâches passées sont importées grisées, sans rappel.',
              ),
            ),
            if (mismatch != null)
              _Warning(
                icon: LucideIcons.info,
                text:
                    'Le fichier indique le fuseau $mismatch, différent de vos '
                    'réglages (${settings.timezone}). Les heures sont '
                    'interprétées dans vos réglages.',
              ),
            for (final overlap in preview.overlaps)
              _Warning(
                icon: LucideIcons.info,
                text:
                    'Chevauchement le ${overlap.first.date.toIso()} : '
                    '« ${overlap.first.title} » et '
                    '« ${overlap.second.title} ».',
              ),
            for (final duplicate in preview.duplicates)
              _Warning(
                icon: LucideIcons.copy,
                text:
                    'Doublon ignoré : « ${duplicate.title} », '
                    '${duplicate.date.toIso()} à ${duplicate.start.toHHmm()}.',
              ),
            for (final invalid in plan.invalidTasks)
              _Warning(
                icon: LucideIcons.circleX,
                text:
                    'Tâche ${invalid.position} exclue : '
                    '${invalid.reasons.join(' ')}',
              ),
            for (final notice in plan.notices)
              _Warning(icon: LucideIcons.info, text: notice),
            if (boundsDiffer)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _applyBounds,
                onChanged: (value) =>
                    setState(() => _applyBounds = value ?? false),
                title: Text(
                  'Utiliser la journée du fichier : de '
                  '${formatHour(dayStart)} à ${formatHour(dayEnd)}',
                ),
              ),
            const SizedBox(height: 8),
            SegmentedButton<ImportMode>(
              segments: const [
                ButtonSegment(
                  value: ImportMode.replace,
                  label: Text('Remplacer'),
                ),
                ButtonSegment(
                  value: ImportMode.merge,
                  label: Text('Fusionner'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: preview.importableCount == 0 || _busy
                    ? null
                    : _import,
                icon: const Icon(LucideIcons.fileUp),
                label: Text('Importer ${preview.importableCount} tâches'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('$count', style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.foreground),
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.colors.destructive),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
