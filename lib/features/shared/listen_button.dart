import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../platform/speech.dart';

/// Bouton de la barre du haut : F.R.I.D.A.Y lit [text], ou se tait.
class ListenButton extends ConsumerWidget {
  const ListenButton({required this.tooltip, required this.text, super.key});

  final String tooltip;

  /// Calculé au moment du toucher, pour lire l'état le plus récent.
  final String Function() text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speaker = ref.watch(speakerProvider);
    if (speaker == null) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: speaker.speaking,
      builder: (context, speaking, _) => IconButton(
        tooltip: speaking ? 'Arrêter la lecture' : tooltip,
        onPressed: () =>
            toggleSpeech(speaker, text(), ref.read(currentDevicePrefsProvider)),
        icon: Icon(speaking ? LucideIcons.square : LucideIcons.volume2),
      ),
    );
  }
}
