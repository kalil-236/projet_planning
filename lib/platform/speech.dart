import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/device_preferences.dart';

/// Voix de synthèse disponible sur l'appareil.
@immutable
class SpeechVoice {
  const SpeechVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  @override
  bool operator ==(Object other) =>
      other is SpeechVoice && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);
}

/// Lecture à voix haute : synthèse vocale du téléphone ou du navigateur.
abstract interface class Speaker {
  /// Voix françaises proposées dans les réglages.
  Future<List<SpeechVoice>> frenchVoices();

  /// Lit [text] ; se termine quand la lecture est finie ou arrêtée.
  Future<void> speak(String text, DevicePreferences prefs);

  Future<void> stop();

  /// Vrai pendant une lecture.
  ValueListenable<bool> get speaking;
}

class TtsSpeaker implements Speaker {
  TtsSpeaker() {
    _tts
      ..setStartHandler(() => _speaking.value = true)
      ..setCompletionHandler(() => _speaking.value = false)
      ..setCancelHandler(() => _speaking.value = false)
      ..setErrorHandler((_) => _speaking.value = false);
  }

  static const _language = 'fr-FR';

  final FlutterTts _tts = FlutterTts();
  final _speaking = ValueNotifier(false);

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  Future<List<SpeechVoice>> frenchVoices() async {
    final raw = await _tts.getVoices;
    if (raw is! List) return const [];
    final voices = <SpeechVoice>{};
    for (final entry in raw) {
      if (entry is! Map) continue;
      final name = entry['name']?.toString();
      final locale = entry['locale']?.toString() ?? '';
      if (name == null || !locale.toLowerCase().startsWith('fr')) continue;
      voices.add(SpeechVoice(name: name, locale: locale));
    }
    return voices.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> speak(String text, DevicePreferences prefs) async {
    await _tts.stop();
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(prefs.voiceLocale ?? _language);
    final voice = prefs.voiceName;
    if (voice != null) {
      await _tts.setVoice({
        'name': voice,
        'locale': prefs.voiceLocale ?? _language,
      });
    }
    await _tts.setSpeechRate(prefs.speechRate);
    await _tts.setPitch(prefs.speechPitch);
    _speaking.value = true;
    try {
      await _tts.speak(text);
    } finally {
      _speaking.value = false;
    }
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _speaking.value = false;
  }
}

/// `null` dans les tests ; le téléphone et le navigateur ont leur synthèse.
final speakerProvider = Provider<Speaker?>((ref) => TtsSpeaker());

/// Lit [text] avec les préférences de l'appareil, ou arrête la lecture en
/// cours. Sans effet si la synthèse vocale est indisponible.
Future<void> toggleSpeech(
  Speaker? speaker,
  String text,
  DevicePreferences prefs,
) async {
  if (speaker == null) return;
  if (speaker.speaking.value) {
    await speaker.stop();
    return;
  }
  try {
    await speaker.speak(text, prefs);
  } on Object catch (error) {
    debugPrint('Lecture impossible : $error');
  }
}
