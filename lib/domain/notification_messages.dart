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
  'Bonjour monsieur, voici votre programme',
  "Votre mission du jour, si vous l'acceptez",
  'Bien dormi, monsieur ? Voici la suite',
  'Nouvelle journée, nouvelles victoires',
  'Debout, agent : voici vos ordres du jour',
];

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
