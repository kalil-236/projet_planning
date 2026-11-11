import 'package:flutter/foundation.dart';

/// Préférences propres à cet appareil, jamais synchronisées : les rapports
/// n'existent que là où les notifications sonnent, et les voix disponibles
/// dépendent du téléphone ou du navigateur.
@immutable
class DevicePreferences {
  const DevicePreferences({
    this.eveningReportEnabled = true,
    this.weeklyReportEnabled = true,
    this.voiceName,
    this.voiceLocale,
    this.speechRate = defaultSpeechRate,
    this.speechPitch = defaultSpeechPitch,
  });

  static const defaultSpeechRate = 0.5;
  static const defaultSpeechPitch = 1.0;

  /// Rapport du soir, à la fin de journée.
  final bool eveningReportEnabled;

  /// Bilan de la semaine, le dimanche à la fin de journée.
  final bool weeklyReportEnabled;

  /// Voix choisie ; `null` : voix française par défaut du système.
  final String? voiceName;
  final String? voiceLocale;

  /// Débit de 0 à 1 (0,5 : normal) et hauteur de 0,5 à 2 (1 : normale).
  final double speechRate;
  final double speechPitch;

  DevicePreferences copyWith({
    bool? eveningReportEnabled,
    bool? weeklyReportEnabled,
    String? voiceName,
    String? voiceLocale,
    bool clearVoice = false,
    double? speechRate,
    double? speechPitch,
  }) {
    return DevicePreferences(
      eveningReportEnabled: eveningReportEnabled ?? this.eveningReportEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
      voiceName: clearVoice ? null : voiceName ?? this.voiceName,
      voiceLocale: clearVoice ? null : voiceLocale ?? this.voiceLocale,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DevicePreferences &&
      other.eveningReportEnabled == eveningReportEnabled &&
      other.weeklyReportEnabled == weeklyReportEnabled &&
      other.voiceName == voiceName &&
      other.voiceLocale == voiceLocale &&
      other.speechRate == speechRate &&
      other.speechPitch == speechPitch;

  @override
  int get hashCode => Object.hash(
    eveningReportEnabled,
    weeklyReportEnabled,
    voiceName,
    voiceLocale,
    speechRate,
    speechPitch,
  );
}
