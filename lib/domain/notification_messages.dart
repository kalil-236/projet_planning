/// Textes d'encouragement des notifications.
///
/// Chaque message dépend d'une clé stable : une tâche garde le même texte
/// quand les rappels sont reprogrammés.
library;

String startReminderMessage(String title, String key) {
  final messages = startReminderMessages(title);
  return messages[stableHash(key) % messages.length];
}

String preReminderMessage(String title, String delay, String key) {
  final messages = preReminderMessages(title, delay);
  return messages[stableHash(key) % messages.length];
}

String morningSummaryTitle(String key) =>
    morningSummaryTitles[stableHash(key) % morningSummaryTitles.length];

List<String> startReminderMessages(String title) => [
  'Monsieur, vous avez au programme : $title',
  "Votre mission, si toutefois vous l'acceptez : $title",
  "Ce message ne s'autodétruira pas, mais place à : $title",
  'Courage, monsieur, vous allez assurer : $title',
  'Le canapé attendra, monsieur. Priorité à : $title',
  'Nous comptons sur vous, monsieur : $title',
  "L'histoire retiendra ce moment : $title",
  'Un pas après l\'autre, monsieur. Prochain pas : $title',
  'Vous êtes capable de grandes choses, à commencer par : $title',
  'Agent, votre objectif est confirmé : $title',
];

List<String> preReminderMessages(String title, String delay) => [
  'Monsieur, vous avez $delay pour vous préparer à : $title',
  "Votre prochaine mission, si toutefois vous l'acceptez : $title",
  'Dernier appel pour les passagers à destination de : $title',
  'Rassemblez vos troupes, monsieur. Objectif : $title',
  'Respirez, monsieur, vous allez gérer : $title',
  'Finissez votre café, monsieur. Bientôt : $title',
  'Échauffement conseillé avant : $title',
  'Agent, préparez-vous pour : $title',
];

const morningSummaryTitles = [
  'Briefing du matin, monsieur',
  'Bonjour monsieur',
  'Votre briefing du jour',
  'Rapport matinal, monsieur',
  'F.R.I.D.A.Y : briefing du jour',
];

const morningBriefingEmptyMessages = [
  "Rien de prévu aujourd'hui, monsieur. Je reste en veille.",
  "Agenda vierge aujourd'hui, monsieur. Une journée sans crise, ce serait une première.",
  "Aucun engagement aujourd'hui, monsieur. Je vous suggère d'en profiter.",
];

const morningBriefingClosings = [
  ' Je surveille le reste, monsieur.',
  ' Je vous préviendrai en temps voulu.',
  ' Essayez de ne rien faire exploser, monsieur.',
  ' Bonne journée, monsieur.',
];

List<String> morningBriefingOpenings(int taskCount) {
  final points = taskCount == 1 ? 'un point' : '$taskCount points';
  return [
    "Bonjour monsieur. Tous les systèmes sont opérationnels, $points à l'agenda aujourd'hui : ",
    'Bonjour monsieur. Voici votre briefing, $points au programme : ',
    "Bonjour monsieur. J'ai analysé votre journée, il y a $points à traiter : ",
    'Réveil confirmé, monsieur. Votre journée compte $points : ',
  ];
}

String morningBriefingEmpty(String key) =>
    _pick(morningBriefingEmptyMessages, key);

String morningBriefingOpening(int taskCount, String key) =>
    _pick(morningBriefingOpenings(taskCount), '$key|ouverture');

String morningBriefingClosing(String key) =>
    _pick(morningBriefingClosings, '$key|fin');

const eveningReportTitles = [
  'Rapport du soir, monsieur',
  'Bilan de la journée',
  'F.R.I.D.A.Y : rapport du soir',
  'Fin de service, monsieur',
];

const eveningAllDoneMessages = [
  'Mission accomplie, monsieur : tout est fait. Repos mérité.',
  "Sans faute aujourd'hui, monsieur. Je n'ai rien à ajouter, ce qui est rare.",
  'Toutes les missions sont bouclées. Même moi, je suis impressionnée.',
  'Journée parfaite, monsieur. Je classe le dossier.',
];

List<String> eveningPartialOpenings(int done, int total) {
  final score = '$done sur $total';
  return [
    "Monsieur, $score missions accomplies aujourd'hui.",
    'Bilan : $score. Honorable, monsieur.',
    'Rapport : $score objectifs atteints.',
    'Journée chargée, monsieur : $score au compteur.',
  ];
}

const eveningPartialClosings = [
  ' Si elles sont faites, un simple « Fait » suffit. Sinon, je peux les reporter à demain.',
  " Je peux les reporter à demain, monsieur, d'un seul geste.",
  " Rien d'irréparable : demain est un autre jour.",
];

String eveningReportTitle(String key) => _pick(eveningReportTitles, key);

String eveningAllDone(String key) => _pick(eveningAllDoneMessages, key);

String eveningPartialOpening(int done, int total, String key) =>
    _pick(eveningPartialOpenings(done, total), '$key|ouverture');

String eveningPartialClosing(String key) =>
    _pick(eveningPartialClosings, '$key|fin');

String _pick(List<String> messages, String key) =>
    messages[stableHash(key) % messages.length];

/// FNV-1a sur 31 bits : `String.hashCode` varie d'une exécution à l'autre.
int stableHash(String key) {
  const offsetBasis = 0x811c9dc5;
  const prime = 0x01000193;
  const mask = 0x7fffffff;
  var hash = offsetBasis;
  for (final unit in key.codeUnits) {
    hash = ((hash ^ unit) * prime) & mask;
  }
  return hash & mask;
}
