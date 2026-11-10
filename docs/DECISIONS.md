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

## Phase 2

| Sujet | Décision | Raison |
|---|---|---|
| `flutter_timezone` | Non installé, malgré la section 4. | Le fuseau vient toujours des réglages (1, 10.4). Aucune fonctionnalité ne lit celui du téléphone. |
| `url_launcher` | Ajouté, hors liste de la section 4. | Nécessaire pour le lien vers dontkillmyapp.com (10.5). |
| Alarmes exactes | `USE_EXACT_ALARM` dès Android 13, `SCHEDULE_EXACT_ALARM` limité à Android 12 et moins. | Sur Android 13 et plus, l'autorisation est accordée d'office et ne peut pas être retirée. `USE_EXACT_ALARM` serait contrôlé sur le Play Store, mais l'APK est installé directement. |
| Alarmes exactes refusées | Repli sur `inexactAllowWhileIdle`, avec un avertissement dans l'assistance batterie. | Un rappel en retard vaut mieux qu'aucun rappel. |
| Reprogrammation | Annule seulement les rappels devenus inutiles, puis réécrit tous les autres. Pas de `cancelAll`. | `cancelAll` effacerait aussi les notifications déjà affichées. Tout réécrire reste nécessaire : un arrêt forcé supprime les alarmes système sans vider la liste du plugin. |
| Identifiants | Hachage FNV-1a stable de la tâche et du type de rappel. L'identifiant 0 est réservé au test. | Un identifiant numéroté dans l'ordre remplacerait à tort une notification déjà affichée. |
| Appels simultanés | Un seul passage à la fois ; un appel pendant un passage en déclenche un dernier. | Le dernier passage lit toujours l'état le plus récent. |
| Échec de programmation | Journalisé, sans faire échouer l'écriture de la tâche. | Une erreur système ne doit pas empêcher d'annuler ou d'importer. |
| Plafond de 200 | Garde les notifications les plus proches. | Les plus lointaines seront programmées lors d'une prochaine ouverture. |
| Texte du pré-rappel | « Dans 10 min : {titre} », avec l'horaire en corps. | Non précisé en 10.1. |
| Titre du résumé | « Résumé du matin », longueur limitée à 300 caractères. | Coupe entre deux tâches, ou dans le titre s'il n'y en a qu'une. |
| Demande de permission | Marquée dans une colonne locale, `notification_prompt_shown`. | Android ne permet pas de savoir si la demande a déjà été faite. Propre à l'appareil, cette colonne ne sera pas synchronisée. |
| Toucher une notification | Ouvre l'application sur son écran courant. | Non précisé. Les actions sont prévues en phase 4 (10.6). |
| Icône de notification | Icône Lucide `bell` en vecteur Android. | L'icône doit être monochrome et rester Lucide (8.3). |
| Mémoire Gradle | 4 Go au lieu de 8. | La machine de développement a 7,7 Go de RAM : 8 Go faisaient planter la compilation. |
| Icône de l'application | Image fournie (`assets/branding/icone.jpg`), générée avec `flutter_launcher_icons` pour Android et le web. Marge de 16 % sur l'icône adaptative, fond #0A0B0D identique à celui de l'image. | Demande explicite. La marge garde le dessin entier dans la zone visible des masques Android. |
| Messages d'encouragement | Corps des rappels : phrase humoristique, puis l'horaire à la ligne. Le titre garde le texte de 10.1. Le titre du résumé varie, son corps reste celui de 10.3. | Demande explicite. Un titre factuel reste lisible quand Android le tronque. |
| Choix du message | Déterminé par un hachage de la tâche et du type de rappel, pas au hasard. | Un rappel garde son texte quand il est reprogrammé, et le calcul reste testable. |
| Forme d'adresse | « Monsieur » et « Agent », écrits en dur, sans réglage. | Formulation demandée. |

## Phase 3

| Sujet | Décision | Raison |
|---|---|---|
| Colonne `synced_at` | Ajoutée à `tasks` et `settings`, écrite par un déclencheur serveur. La lecture incrémentale l'utilise au lieu de `updated_at`. | Une modification faite hors ligne garde un `updated_at` ancien : avec lui, l'autre appareil ne la verrait jamais. |
| Le plus récent gagne | Vérifié sur le serveur par un déclencheur, et à la réception sur chaque appareil. | Deux appareils qui écrivent en même temps ne peuvent pas écraser une version plus récente. |
| File d'attente hors ligne | Colonne locale `pending_sync` sur chaque ligne. La marque n'est retirée que si la ligne n'a pas changé pendant l'envoi. | Rien n'est perdu après un arrêt de l'appli, sans table de journal à maintenir. |
| Données existantes | Marquées à envoyer par la migration. | Les tâches déjà sur le téléphone partent au premier envoi. |
| Relecture | La lecture reprend 5 minutes avant la dernière position. | Deux transactions serveur peuvent se terminer dans le désordre. Appliquer deux fois la même ligne est sans effet. |
| Temps réel | Un événement déclenche une synchronisation, son contenu n'est pas lu. | Un seul chemin d'écriture, et les événements manqués sont rattrapés. |
| Connexion | Obligatoire sur le web. Facultative sur Android, depuis Réglages. | Sur le téléphone, l'absence de compte ou de réseau ne doit jamais bloquer les rappels (1, 11.1). |
| Déconnexion | Conserve les données locales. | Un seul compte existe. Les écritures en attente partiront à la prochaine connexion. |
| Sans configuration | Sans `SUPABASE_URL` et `SUPABASE_ANON_KEY`, l'application reste locale, sans écran de compte. | Une erreur de configuration ne doit pas empêcher les rappels. |
| Configuration | `--dart-define-from-file=env.json`, fichier ignoré par Git. `flutter_dotenv` non installé. | `flutter_dotenv` embarquerait un fichier dans les assets. Les deux options sont prévues en section 4. |
| Clé Supabase | Passée à `publishableKey`, sous le nom `SUPABASE_ANON_KEY`. | `anonKey` est dépréciée dans `supabase_flutter`. |
| Table `categories` | Créée (7.3) mais pas synchronisée. | La v1 utilise une liste fixe dans le code. |
| Hébergement web | GitHub Pages, déployé par GitHub Actions. | Gratuit, sans compte de plus. L'URL et la clé `anon` restent hors du dépôt, en variables GitHub. |
