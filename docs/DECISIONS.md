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

## Phase 1

| Sujet | Décision | Raison |
|---|---|---|
| Minuit | Un seul minuteur, calé sur chaque début de minute, recalcule la date et l'heure. | Il couvre minuit et le trait « maintenant » sans second minuteur. |
| Base web | `drift` en WASM, avec `web/sqlite3.wasm` et `web/drift_worker.js` de la version 2.35.4. | Évite le cache mémoire prévu en repli (11.6). L'hébergeur doit servir le `.wasm` en `application/wasm` (phase 3). |
| Dépôt de fichier web | `desktop_drop` 0.8. | La 0.9 exige `cross_file` 0.4, incompatible avec `file_picker` 13. |
| Rappels | Interface `ReminderScheduler`, sans effet en phase 1, appelée après chaque écriture. | Le cas 5.3 « les rappels sont reprogrammés » est vérifié sur l'appel. La programmation réelle arrive en phase 2. |
| Écran Réglages en phase 1 | Journée, rappel par défaut, fuseau et thème. | Le fuseau est requis par 5.3. Résumé du matin et batterie en phase 2, synchronisation en phase 3. |
| Catégories | Liste fixe dans le code, pas de table locale. | La v1 ne prévoit pas de les modifier. |
| Décaler la journée | Inclut la tâche en cours (`end` > maintenant). | En cas de retard, c'est justement celle-là qu'il faut repousser. |
| Décalage après minuit | Refusé, pour une tâche comme pour toute la journée. | Hors périmètre v1 (section 2). |
| Remplacer | Une tâche importée identique à une tâche conservée (faite, annulée, passée) est ignorée. | Sinon, réimporter le même fichier créerait un doublon d'une tâche déjà faite. |
| Plage de remplacement | Dates déclarées et dates des tâches réunies ; jamais avant aujourd'hui si « à partir d'aujourd'hui » est actif. | Une tâche passée ne doit pas disparaître quand elle n'est pas importée. |
| `reminder_before_min` = 0 | Pas de pré-rappel. Le rappel de début reste actif. | Cohérent avec 10.1 (« si défini et > 0 »). |
| Emojis saisis ou importés | Retirés du titre et des notes. | Règle 8.5 : pas d'emojis, y compris dans les données. |
| Modifier l'heure d'une tâche importée | La marque « décalée ». | Définition du champ `shifted` (7.1). |
| Panneau de détail PC | Porté par le shell, donc disponible sur Aujourd'hui et Semaine. | Un seul composant pour les deux vues. |
| Semaine en largeur intermédiaire | Trois jours à partir du jour choisi, sans sortir de la semaine. | La spécification ne précise pas lesquels. |
| Blocs de la frise | Pas de badge pour l'état « À faire », qui est l'état normal. Il reste affiché dans les listes et le détail. | Évite de surcharger des blocs étroits. |
| Illustrations | Grande icône Lucide avec `TODO(illustration)`. | Prévues en phase 4 (14). |
| Compilation Kotlin | `kotlin.incremental=false` dans `android/gradle.properties`. | La compilation incrémentale échoue sous Windows quand les plugins (C:) et le projet (E:) sont sur des lecteurs différents. |
