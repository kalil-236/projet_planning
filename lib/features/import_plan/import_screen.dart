import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/destinations.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../domain/plan_parser.dart';
import '../../domain/plan_prompt.dart';
import '../shared/common_widgets.dart';
import 'import_preview_panel.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  static const _maxContentWidth = 720.0;

  ParsedPlan? _plan;
  String? _fileName;
  String? _error;
  bool _dragging = false;

  Future<void> _copyPrompt() async {
    final messenger = ScaffoldMessenger.of(context);
    final prompt = buildPlanPrompt(
      today: ref.read(todayProvider),
      settings: ref.read(currentSettingsProvider),
    );
    await Clipboard.setData(ClipboardData(text: prompt));
    showMessage(messenger, 'Prompt copié dans le presse-papiers.');
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return;
    _load(files.first.name, await files.first.readAsBytes());
  }

  void _load(String name, Uint8List bytes) {
    setState(() {
      _fileName = name;
      try {
        _plan = parsePlanJson(utf8.decode(bytes));
        _error = null;
      } on FormatException {
        _plan = null;
        _error = "Le fichier n'est pas encodé en UTF-8.";
      } on ImportRejected catch (rejected) {
        _plan = null;
        _error = rejected.message;
      }
    });
  }

  void _onImported() {
    setState(() {
      _plan = null;
      _fileName = null;
    });
    context.go(AppDestination.today.path);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final picker = _FilePickerCard(
      fileName: _fileName,
      error: _error,
      dragging: _dragging,
      onPick: _pickFile,
    );
    return Scaffold(
      appBar: AppBar(title: Text(AppDestination.importPlan.label)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(LucideIcons.copy),
                  title: const Text('Copier le prompt'),
                  subtitle: const Text(
                    'À coller dans le chat Claude pour obtenir un planning '
                    'au bon format.',
                  ),
                  onTap: _copyPrompt,
                ),
              ),
              const SizedBox(height: 12),
              if (kIsWeb)
                DropTarget(
                  onDragEntered: (_) => setState(() => _dragging = true),
                  onDragExited: (_) => setState(() => _dragging = false),
                  onDragDone: (details) async {
                    setState(() => _dragging = false);
                    if (details.files.isEmpty) return;
                    final file = details.files.first;
                    _load(file.name, await file.readAsBytes());
                  },
                  child: picker,
                )
              else
                picker,
              if (plan != null) ...[
                const SizedBox(height: 12),
                ImportPreviewPanel(
                  key: ValueKey(_fileName),
                  plan: plan,
                  onImported: _onImported,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  const _FilePickerCard({
    required this.fileName,
    required this.error,
    required this.dragging,
    required this.onPick,
  });

  final String? fileName;
  final String? error;
  final bool dragging;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      color: dragging ? colors.muted : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(LucideIcons.fileUp),
              label: const Text('Choisir un fichier .json'),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 8),
              const Text('Ou déposez le fichier ici.'),
            ],
            if (fileName != null) ...[
              const SizedBox(height: 8),
              Text(fileName!, style: Theme.of(context).textTheme.labelLarge),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.circleX,
                    size: 20,
                    color: colors.destructive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
