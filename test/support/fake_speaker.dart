import 'package:assistant_planning/domain/device_preferences.dart';
import 'package:assistant_planning/platform/speech.dart';
import 'package:flutter/foundation.dart';

class FakeSpeaker implements Speaker {
  final spoken = <String>[];
  final usedPrefs = <DevicePreferences>[];
  final _speaking = ValueNotifier(false);
  List<SpeechVoice> voices = const [
    SpeechVoice(name: 'fr-fr-x-vlf', locale: 'fr-FR'),
  ];

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  Future<List<SpeechVoice>> frenchVoices() async => voices;

  @override
  Future<void> speak(String text, DevicePreferences prefs) async {
    spoken.add(text);
    usedPrefs.add(prefs);
  }

  @override
  Future<void> stop() async => _speaking.value = false;
}
