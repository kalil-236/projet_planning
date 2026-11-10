import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../domain/local_time.dart';

/// Squelette affiché pendant le chargement, jamais d'écran blanc (8.5).
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final color = context.colors.muted;
    return Semantics(
      label: 'Chargement',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: color, borderRadius: _radius),
              ),
          ],
        ),
      ),
    );
  }
}

/// État vide. TODO(illustration) : remplacer l'icône par le SVG unDraw (phase 4).
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.primaryOnSurface),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Sélecteur d'heure, toujours sur 24 h.
Future<LocalTime?> pickLocalTime(
  BuildContext context,
  LocalTime initial,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return picked == null ? null : LocalTime(picked.hour, picked.minute);
}

void showMessage(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
