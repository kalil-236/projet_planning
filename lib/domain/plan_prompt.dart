import 'dart:convert';

import '../core/french_format.dart';
import 'app_settings.dart';
import 'insights.dart';
import 'local_date.dart';
import 'local_time.dart';

const _planLengthDays = 7;

/// Texte à coller dans le chat Claude (section 6.4).
String buildPlanPrompt({
  required LocalDate today,
  required AppSettings settings,
  List<Insight> insights = const [],
}) {
  final todayIso = today.toIso();
  final endIso = today.addDays(_planLengthDays - 1).toIso();
  final dayStart = settings.dayStart.toHHmm();
  final dayEnd = settings.dayEnd.toHHmm();

  return '''
Nous sommes le ${weekdayName(today)} $todayIso (fuseau ${settings.timezone}).
Génère-moi mon emploi du temps à partir d'AUJOURD'HUI ($todayIso) jusqu'au $endIso, en tenant compte de mon emploi du temps scolaire et des activités que je souhaite faire (que je te donne ci-dessous).
Journée de $dayStart à $dayEnd. Aucune tâche ne doit se chevaucher ni traverser minuit.
Réponds UNIQUEMENT avec un fichier JSON valide, au format suivant (schema_version 1), avec des dates absolues AAAA-MM-JJ et des heures HH:mm.
Catégories autorisées : cours, etude, activite, repos, autre.
${_exampleSchema(todayIso, endIso, settings)}
${_observations(insights)}
Mon emploi du temps scolaire : ...
Mes activités souhaitées (durée, fréquence, préférences) : ...''';
}

String _exampleSchema(String todayIso, String endIso, AppSettings settings) {
  return const JsonEncoder.withIndent('  ').convert({
    'schema_version': 1,
    'timezone': settings.timezone,
    'generated_on': todayIso,
    'plan_start': todayIso,
    'plan_end': endIso,
    'day_bounds': {
      'start': settings.dayStart.toHHmm(),
      'end': settings.dayEnd.toHHmm(),
    },
    'tasks': [
      {
        'title': "Cours d'algorithmique",
        'date': todayIso,
        'start': const LocalTime(8, 0).toHHmm(),
        'end': const LocalTime(10, 0).toHHmm(),
        'category': 'cours',
        'notes': 'Salle B2',
        'reminder_before_min': 15,
      },
    ],
  });
}

/// Observations de l'application sur les semaines passées (section 5 du bilan).
String _observations(List<Insight> insights) {
  if (insights.isEmpty) return '';
  final lines = [
    for (final insight in insights.take(maxPromptInsights))
      '- ${insight.promptLine}',
  ];
  return '''
Observations de mon application sur mes ${insightHistoryDays ~/ 7} dernières semaines, à prendre en compte :
${lines.join('\n')}
''';
}
