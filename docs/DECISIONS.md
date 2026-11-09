# Décisions hors spécification

Choix techniques non couverts par `SPEC_assistant_planning.md`.

## Phase 0

| Sujet | Décision | Raison |
|---|---|---|
| Navigation | `StatefulShellRoute.indexedStack` de `go_router`, variante de `ShellRoute`. | Chaque onglet conserve son état et sa position de défilement. |
| Barre latérale PC | `NavigationRail` en mode `extended`. | Même composant que la largeur intermédiaire, sans widget sur mesure. |
| Police | Fichiers statiques 400/500/600/700 du dépôt officiel `tokotype/PlusJakartaSans`. | Flutter ne sélectionne pas les graisses d'une police variable déclarée dans `pubspec.yaml`. |
| Corps de texte | `bodyLarge`, `bodyMedium` et `bodySmall` à 16 px. Les petits textes utilisent les styles `label*`. | Exigence « corps ≥ 16 px » (8.2). |
| Icônes Material | `uses-material-design: true` reste actif. | Certains widgets du framework, comme les sélecteurs de date, en dépendent en interne. Le code de l'appli n'utilise que Lucide. |
| Accent sur `surface` | Token dérivé `primaryOnSurface`, égal à `ring`. | `primary` sombre (#3B82F6) atteint 3,97:1 sur `surface` sombre, sous le seuil de 4,5:1. `ring` a la bonne valeur dans les deux modes. |
| `accent` en mode clair | Réservé aux icônes. Le texte « Faite » à côté utilise `foreground`. | #059669 sur blanc atteint 3,77:1 : suffisant pour une icône (3:1), pas pour du texte. |
| `mutedForeground` sur `muted` en mode clair | À éviter : utiliser `foreground`. | #64748B sur #F1F5FD atteint 4,36:1. |
| Identifiant Android | `com.kalil236.assistant_planning`. | Dérivé du nom du dépôt GitHub. |
| Branche Git | Travail direct sur `main`. | Projet personnel, dépôt initialement vide, un seul contributeur. |
