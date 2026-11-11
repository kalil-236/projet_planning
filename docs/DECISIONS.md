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
| Nom de l'application | F.R.I.D.A.Y sur Android et le web. Le nom technique du paquet ne change pas. | Demande explicite. Changer l'identifiant Android empêcherait la mise à jour de l'appli installée. |
| Résumé du matin | Briefing à la manière d'un assistant : ouverture, liste des tâches, conclusion. Remplace le texte de 10.1 et 10.3. La conclusion disparaît si le texte dépasse 300 caractères. | Demande explicite. |

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
| Variables GitHub | Le déploiement retire un préfixe `NOM=`, les espaces, les guillemets et la barre oblique finale. | Erreurs de copie fréquentes depuis un fichier `.env`. |

## Phase 4

| Sujet | Décision | Raison |
|---|---|---|
| Illustrations | unDraw « Relaxation », « Add files » et « AI personal assistant », téléchargées depuis cdn.undraw.co, bleu remplacé par #2563EB. | Reprennent les trois usages de 8.4. |
| « Aucun planning importé » | Affiché sur Semaine quand la semaine n'a aucune tâche, avec un bouton « Importer un planning ». | La spécification ne dit pas quel écran le porte. Un jour vide de la semaine garde son icône. |
| Raccourcis clavier | `N`, `T`, `←` et `→`, actifs sur tous les écrans principaux, désactivés pendant une saisie ou quand une fenêtre est ouverte. `←` et `→` n'agissent que dans Semaine. `T` ramène Semaine à aujourd'hui, ou ouvre Aujourd'hui depuis un autre écran. | Aujourd'hui n'affiche qu'un jour : le changement de jour n'a de sens que dans Semaine. Hors de Semaine, les flèches gardent leur rôle habituel. |
| Jour choisi dans Semaine | Conservé dans un fournisseur global, et marqué dans l'en-tête de la grille PC. | Les raccourcis doivent pouvoir le modifier, et le changement doit être visible sur PC. |
| Contrôle d'accessibilité | Tests automatiques sur les quatre écrans et la connexion : contraste du texte, zones tactiles d'au moins 48 dp, boutons nommés, en clair et en sombre, à 390 et 1280 dp. Aucun débordement avec un texte à 200 %, à 390, 800 et 1280 dp. | Rend les critères de 8.2 et 8.5 vérifiables à chaque modification. |
| « Aujourd'hui » dans Semaine | Sur mobile, au-delà de 130 % de taille de texte, le bouton devient une icône avec une info-bulle. | Avec un texte à 200 %, le bouton faisait déborder la barre du haut. |
| Boutons des rappels | « Fait » et « Décaler 15 min » sur le rappel de début et le pré-rappel, pas sur le résumé. Ils agissent sans ouvrir l'application. | 10.6. Le résumé concerne plusieurs tâches. |
| Base partagée | `shareAcrossIsolates` de drift : les boutons écrivent depuis un moteur Flutter séparé, et l'application ouverte voit le changement. | Sans partage, deux connexions sur le même fichier pourraient se gêner, et l'écran ne se mettrait pas à jour. |
| Bouton sans effet | Tâche déjà faite, annulée, supprimée, ou décalage qui passerait minuit : rien ne change, la notification se ferme. | Même règle que l'écran Décaler (Phase 1). |
| Synchronisation après un bouton | La tâche est marquée à envoyer et part à la prochaine synchronisation (ouverture de l'application). | Le moteur d'arrière-plan n'ouvre pas de session Supabase. |
| Rappel dans l'onglet web | Bandeau « C'est l'heure : {titre} » au début de chaque tâche à faire, pendant 15 secondes, quel que soit l'écran. Pas de pré-rappel. | 10.7 ne cite que ce texte. Un seul bandeau par tâche et par horaire, même si l'écran est reconstruit. |
| Mouvement réduit | Si le système demande moins d'animations, les changements d'écran se font sans transition. | 8.5. Les autres animations du framework sont brèves. |
| Mode sombre des illustrations | Couleurs remplacées à l'affichage : bleu vers `primary`, gris vers `foreground`, `surface`, `muted` ou `border`, teintes chaudes inchangées. | Les gris d'origine sont illisibles sur fond sombre. Le classement se fait par teinte et luminosité, sans couleur écrite dans le code. |

## Phase 5 : améliorations validées après la phase 4

Les idées 1, 2, 3, 4, 5, 6, 7, 10, 13, 15 et 20 de la liste de propositions ont été validées par l'utilisateur. L'idée 20 (lecture vocale) lève explicitement l'interdiction des sections 1 et 2.

| Sujet | Décision | Raison |
|---|---|---|
| Planning collé | Bouton « Coller le planning » dans Importer. Le texte peut entourer le JSON d'un bloc de code ou d'une phrase : le premier objet `{ … }` est lu, puis validé comme un fichier. | La réponse du chat contient souvent un bloc de code et une phrase d'introduction. |
| Partage vers l'application | Android : « Partager » (fichier JSON, fichier inconnu ou texte) et « Ouvrir avec » (fichier JSON) ouvrent Importer avec l'aperçu. Lecture native dans `MainActivity`, limitée à 1 Mo, sans paquet supplémentaire. | Le canal natif fait une quarantaine de lignes ; un paquet de partage aurait ajouté une dépendance pour peu de chose. Le contenu est toujours validé avant import. |
| Créneaux libres | Trous d'au moins 30 minutes entre le début et la fin de journée, affichés dans la frise d'Aujourd'hui seulement, à partir de l'heure actuelle arrondie aux 5 minutes. Les toucher ouvre l'ajout prérempli avec ces horaires. Une tâche faite occupe sa place, une tâche annulée la libère. | Un trou plus court n'est pas exploitable. Sur Semaine, sept colonnes de pointillés rendraient la grille illisible. |
| Chevauchements | Deux tâches à faire du même jour qui se recouvrent portent la mention « Chevauchement » (icône d'alerte et texte), dans Aujourd'hui et Semaine ; Aujourd'hui l'annonce aussi en tête. | Les tâches faites ou annulées ne gênent plus. La frise les plaçait déjà côte à côte sans le dire. |
| Listes déroulantes du formulaire | Le texte des choix se coupe avec « … » au lieu de déborder. | Le choix « Rappel » débordait de 5 pixels sur un écran de 390 dp, découvert par les tests. |
| Ajout express | Champ en tête d'Aujourd'hui. Reconnaît : aujourd'hui, demain, après-demain, jour de la semaine (« prochain » pour la semaine suivante), « le 12 », « 12/11 », « 3 décembre » ; « 18h », « 18h30 », « 18:30 », « midi », « de 14h à 16h », « 14h-16h » ; durées « 1h », « 1h30 », « 45 min », « pendant 2h ». Le reste devient le titre ; la catégorie est devinée par mots-clés (cours, révisions, sport, pause…). | Analyse locale par règles, sans IA (section 1). Un aperçu en direct montre ce qui sera créé avant de valider. |
| Valeurs par défaut de l'ajout express | Sans durée : 1 heure. Sans date : aujourd'hui, ou demain si l'heure est déjà passée. Sans heure : heure pleine suivante. Une date sans année déjà passée désigne le mois ou l'année suivante. | Évite de créer une tâche dans le passé. |
| Gestes sur les tâches | Sur les tâches à faire (frise d'Aujourd'hui, grille et liste de Semaine) : glisser de 72 dp vers la droite marque faite, vers la gauche décale de 15 minutes. Vibration légère au seuil, plus marquée à la validation, petit rebond de l'icône, puis bandeau « Annuler ». Les tâches faites, annulées ou passées ne glissent pas. | Même sens que les boutons des rappels. Le bandeau rattrape un geste involontaire. Les deux actions sont aussi proposées aux lecteurs d'écran, le geste n'étant pas accessible à tous. |
| Mouvement réduit et gestes | Pas de rebond ni de retour animé : la carte revient en place d'un coup. L'estompage d'une tâche faite est immédiat. | 8.5. |
| Heure de réalisation | Nouvelle colonne `completed_at` (base locale v4, et table `tasks` du serveur) : instant où une tâche passe à « Faite », par l'écran, un geste ou un bouton de rappel. Effacée si la tâche n'est plus faite, conservée si on modifie une tâche déjà faite. | Indispensable pour comparer le prévu et le réel (bilan). |
| Serveur pas encore migré | `supabase/migrations/002_completed_at.sql` ajoute la colonne. Tant qu'elle manque, l'envoi réessaie sans ce champ : la synchronisation continue, seule l'heure de réalisation reste locale. | Évite de bloquer toute la synchronisation si la migration est oubliée. |
| Notification de la tâche en cours | Le rappel de début devient persistant : compte à rebours natif jusqu'à l'heure de fin, boutons « Fait » et « Décaler 15 min », retrait automatique à la fin prévue. Sur Android 16, il demande la mise en avant (« Live Update ») avec l'heure de fin dans la pastille de la barre d'état. | Le compte à rebours est calculé par Android : rien à mettre à jour depuis l'application, qui peut être fermée. Pas de barre de progression, qui demanderait de reposter la notification régulièrement. |
| Rapport du soir | Une notification par jour qui a au moins une tâche non annulée, à la fin de journée, ou à la fin de la dernière tâche si elle est plus tardive. Elle donne « X sur Y » et cite jusqu'à quatre tâches restantes. Bouton « Reporter à demain » s'il en reste. Texte recalculé à chaque modification, comme le résumé du matin. Canal « Rapports du soir et de la semaine ». | L'heure de fin de journée existe déjà dans les réglages. Un rapport sur une journée vide n'apporte rien. |
| Reporter à demain | Les tâches encore à faire du jour passent au lendemain, aux mêmes heures, marquées décalées. Les chevauchements éventuels sont signalés par Aujourd'hui. | Ce que fait une personne le soir : remettre au lendemain sans tout réorganiser. |
| Préférences de l'appareil | Nouvelle table locale (base v5), jamais synchronisée : rapport du soir, bilan de la semaine, voix, débit et hauteur de la lecture. L'interrupteur du rapport du soir n'apparaît que sur Android. | Les rapports n'existent que là où les notifications sonnent, et les voix dépendent de l'appareil. Aucune colonne de plus sur le serveur. |
