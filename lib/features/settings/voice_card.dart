import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../domain/device_preferences.dart';
import '../../platform/speech.dart';

/// Phrase d'essai de la voix.
const voiceSample =
    'Bonjour monsieur. Tous les systèmes sont opérationnels. Je lirai votre '
    'briefing quand vous voudrez.';

/// Voix de F.R.I.D.A.Y : voix française de l'appareil, débit et hauteur.
class VoiceCard extends ConsumerStatefulWidget {
  const VoiceCard({super.key});

  @override
  ConsumerState<VoiceCard> createState() => _VoiceCardState();
}

class _VoiceCardState extends ConsumerState<VoiceCard> {
  late final Future<List<SpeechVoice>> _voices =
      ref.read(speakerProvider)?.frenchVoices() ?? Future.value(const []);

  /// Valeurs des curseurs pendant le glissement, enregistrées au relâchement.
  double? _rate;
  double? _pitch;

  Future<void> _save(DevicePreferences prefs) =>
      ref.read(planningServiceProvider).saveDevicePrefs(prefs);

  @override
  Widget build(BuildContext context) {
    final speaker = ref.watch(speakerProvider);
    if (speaker == null) return const SizedBox.shrink();
    final prefs = ref.watch(currentDevicePrefsProvider);
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.audioLines),
              title: const Text('Voix de F.R.I.D.A.Y'),
              subtitle: Text(
                'Synthèse vocale de cet appareil, pour le briefing et le '
                'bilan.',
                style: TextStyle(color: colors.mutedForeground),
              ),
            ),
            FutureBuilder<List<SpeechVoice>>(
              future: _voices,
              builder: (context, snapshot) {
                final voices = snapshot.data ?? const [];
                final selected = voices
                    .where((v) => v.name == prefs.voiceName)
                    .firstOrNull;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<SpeechVoice?>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Voix'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Voix française par défaut'),
                      ),
                      for (final voice in voices)
                        DropdownMenuItem(
                          value: voice,
                          child: Text(
                            '${voice.name} (${voice.locale})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (voice) => _save(
                      voice == null
                          ? prefs.copyWith(clearVoice: true)
                          : prefs.copyWith(
                              voiceName: voice.name,
                              voiceLocale: voice.locale,
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _SliderTile(
              label: 'Débit',
              value: _rate ?? prefs.speechRate,
              min: 0.2,
              max: 1,
              describe: (v) => v < 0.45
                  ? 'Lent'
                  : v > 0.6
                  ? 'Rapide'
                  : 'Normal',
              onChanged: (v) => setState(() => _rate = v),
              onChangeEnd: (v) async {
                await _save(prefs.copyWith(speechRate: v));
                if (mounted) setState(() => _rate = null);
              },
            ),
            _SliderTile(
              label: 'Hauteur',
              value: _pitch ?? prefs.speechPitch,
              min: 0.5,
              max: 2,
              describe: (v) => v < 0.9
                  ? 'Grave'
                  : v > 1.15
                  ? 'Aiguë'
                  : 'Normale',
              onChanged: (v) => setState(() => _pitch = v),
              onChangeEnd: (v) async {
                await _save(prefs.copyWith(speechPitch: v));
                if (mounted) setState(() => _pitch = null);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => toggleSpeech(speaker, voiceSample, prefs),
                  icon: const Icon(LucideIcons.volume2),
                  label: const Text('Tester la voix'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.describe,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String Function(double) describe;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label : ${describe(clamped)}'),
          Slider(
            value: clamped,
            min: min,
            max: max,
            label: describe(clamped),
            semanticFormatterCallback: (v) => '$label ${describe(v)}',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}
