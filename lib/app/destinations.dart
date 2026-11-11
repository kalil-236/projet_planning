import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Les cinq entrées de navigation, dans l'ordre d'affichage.
enum AppDestination {
  today('/aujourdhui', "Aujourd'hui", LucideIcons.calendarCheck),
  week('/semaine', 'Semaine', LucideIcons.calendarDays),
  report('/bilan', 'Bilan', LucideIcons.chartColumn),
  importPlan('/importer', 'Importer', LucideIcons.fileUp),
  settings('/reglages', 'Réglages', LucideIcons.settings);

  const AppDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}
