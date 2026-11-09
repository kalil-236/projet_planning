# SPEC — Assistant de planification (Flutter + Supabase)

> Document de référence destiné à Claude Code. Application **personnelle** (un seul utilisateur), en **français**, qui importe un planning hebdomadaire (fichier JSON), l'affiche (jour / semaine), et envoie des **rappels** et un **résumé du matin** sous forme de notifications.
> Métaphore produit : l'assistant d'un chef d'entreprise — il lit l'emploi du temps du jour, permet d'annuler ou décaler des tâches, et rappelle les activités.

---

## 0. Règles de travail pour Claude Code

1. Lire ce document en entier avant d'écrire du code. Les décisions de la section 1 sont **figées** : ne pas les remettre en cause, ne pas ajouter de fonctionnalités hors périmètre (section 2).
2. Travailler **phase par phase** (section 14). Ne passer à la phase suivante que lorsque les critères d'acceptation de la phase courante sont vérifiés.
3. Avant la première ligne de code : exécuter `flutter doctor -v` et corriger ce qui peut l'être. Ne s'arrêter pour demander à l'utilisatrice que si un blocage ne peut pas être levé seul (compte à créer, clé à fournir, téléphone à brancher).
4. Vérifier les versions **actuelles** des paquets (pub.dev) au moment de l'installation ; les noms de paquets de la section 4 sont indicatifs.
5. Un commit Git par étape logique, message en français ou anglais cohérent. Ne jamais committer de secrets (`.env`).
6. Écrire des tests pour la logique de dates, l'import et le calcul des rappels (section 12). Cette logique est le cœur de l'appli.
7. Si un choix technique n'est pas couvert ici, prendre l'option la plus simple et la documenter dans `docs/DECISIONS.md`.

---

## 1. Décisions figées

| Sujet | Décision |
|---|---|
| Utilisateur | Une seule personne. Pas de multi-utilisateur, pas d'inscription publique. |
| Plateformes | **Android** (téléphone, installation par APK, hors Play Store) + **Web** (PC) depuis le même code Flutter. |
| Fonctionnalités | Identiques sur mobile et PC (consulter, modifier, importer, annuler, décaler). **Exception honnête** : les rappels programmés sonnent sur le téléphone ; un navigateur ne peut pas sonner de façon fiable une fois fermé (voir 9.6). |
| Génération du planning | **Hors appli** : l'utilisatrice génère le planning avec Claude dans le chat et importe le fichier JSON. Aucune API d'IA dans l'appli. |
| Rappels | Notifications **locales** programmées sur Android. Pas de WhatsApp, pas de serveur d'envoi. |
| Résumé du matin | Notification quotidienne (« Aujourd'hui : cours à 8h, sport à 17h… »). **Pas de lecture vocale.** |
| Backend | Supabase (offre gratuite) : Postgres + Auth + Realtime. Sert à synchroniser téléphone et PC. |
| Données | **Local-first** : le téléphone garde une copie locale (SQLite) et fonctionne hors ligne. |
| Coût | Zéro. Aucune dépendance payante. |
| Design | Direction **A « Calendrier clair »**, mode clair + mode sombre automatique. |
| Icônes | **Lucide** uniquement. **Jamais d'emojis ni de stickers**, y compris dans les notifications et les catégories. |
| Illustrations | **unDraw** (SVG recoloré en #2563EB), uniquement pour les écrans vides. |
| Langue | Interface 100 % française, dates en `fr_FR`, heures en 24 h, semaine commençant le lundi. |
| Fuseau | `Africa/Porto-Novo` (UTC+1, sans heure d'été) par défaut, modifiable dans les réglages. |

---

## 2. Hors périmètre (ne pas implémenter)

- Génération de planning par IA dans l'appli, lecture vocale, WhatsApp/Telegram/SMS/email.
- iOS, publication Play Store, comptes multiples, partage, collaboration.
- Synchronisation avec Google Calendar.
- Tâches qui traversent minuit (une tâche commence et finit le même jour, v1).

---

## 3. Fonctionnalités

1. **Importer** un planning (fichier JSON, format section 6), avec aperçu et choix « remplacer / fusionner ».
2. **Aujourd'hui** : frise verticale de la journée en cours, trait « maintenant », actions sur chaque tâche.
3. **Semaine** : vue des 7 jours.
4. **Gérer une tâche** : ajouter, modifier, marquer faite, **décaler**, **annuler**, supprimer.
5. **Décaler toute la journée** : repousser toutes les tâches restantes d'un délai choisi (utile en cas de retard).
6. **Rappels** par tâche + **résumé du matin**.
7. **Réglages** : début/fin de journée, heure du résumé, délai de rappel par défaut, fuseau, thème, assistance batterie.
8. **Copier le prompt modèle** (section 6.4) : génère, avec la date du jour pré-remplie, le texte à coller dans le chat Claude pour obtenir un planning au bon format.

---

## 4. Stack technique

- **Flutter** (dernière version stable), Dart, Material 3.
- **État** : `flutter_riverpod`. **Navigation** : `go_router` (avec `ShellRoute`).
- **Base locale** : `drift` (SQLite) — sur le web, utiliser le backend web de drift (WASM/IndexedDB) ou, si trop coûteux en v1, un cache en mémoire alimenté par Supabase (voir 11.4).
- **Backend** : `supabase_flutter` (Auth email + mot de passe, Postgres, Realtime).
- **Notifications** : `flutter_local_notifications`, `timezone`, `flutter_timezone`, `permission_handler`.
- **UI** : `lucide_icons_flutter` (ou équivalent maintenu), `flutter_svg`, police **Plus Jakarta Sans embarquée** dans `assets/fonts/` (licence OFL) — ne pas dépendre d'un téléchargement réseau.
- **Fichiers** : `file_picker`, `flutter/services` (presse-papiers).
- **Dates/format** : `intl` (locale `fr_FR`).
- **Config** : `flutter_dotenv` ou `--dart-define` pour `SUPABASE_URL` et `SUPABASE_ANON_KEY` (jamais la clé `service_role`).
- **Tests** : `flutter_test`, `mocktail`.

### Structure du projet (indicative)

```
lib/
  main.dart
  app/            # router, thème, shell adaptatif
  core/           # dates, fuseau, constantes, utilitaires
  data/           # drift (tables, DAO), repositories, sync Supabase
  domain/         # modèles (Task, Category, Settings), logique pure
  features/
    today/  week/  import_plan/  settings/  task_editor/
  notifications/  # planification, canaux, actions, assistance batterie
assets/ fonts/ illustrations/
test/
docs/DECISIONS.md
supabase/schema.sql
```

---

## 5. Gestion des jours (EXIGENCE CRITIQUE)

L'appli doit toujours savoir **quel jour on est réellement**. Un planning reçu le mardi ne doit jamais afficher les tâches du lundi comme « aujourd'hui ».

### 5.1 Principes

1. Chaque tâche est stockée avec une **date calendaire absolue** (`date`, format `YYYY-MM-DD`, heure locale) et non avec un « jour de la semaine ». Le jour de la semaine est **toujours dérivé** de la date.
2. « Aujourd'hui » = **la date locale actuelle** dans le fuseau configuré. Aucune vue ne doit utiliser un index de jour (« lundi = 0 ») pour décider quoi afficher.
3. Les heures sont stockées en **heure locale** (`HH:mm`) avec la date ; la conversion en instant absolu (UTC) ne se fait qu'au moment de programmer une notification, en utilisant le fuseau configuré. Éviter tout calcul en UTC pour décider du jour affiché.
4. La date du jour est **recalculée** : au lancement, à chaque retour au premier plan (`AppLifecycleState.resumed`), et par un minuteur déclenché à minuit local. Si l'appli reste ouverte pendant le passage à minuit, l'écran « Aujourd'hui » bascule seul.
5. Une fonction unique `Clock` injectable fournit « maintenant » (indispensable pour les tests).

### 5.2 Planning reçu en retard (cas du mardi)

- Le fichier importé contient des dates absolues (section 6). À l'import, chaque tâche est classée **passée** (`date < aujourd'hui`), **aujourd'hui** ou **à venir**.
- L'écran d'aperçu propose l'option **« Importer à partir d'aujourd'hui »**, **activée par défaut** : les tâches passées sont ignorées. Si l'option est désactivée, elles sont importées avec le statut `missed` (grisées, « passée »), **sans rappel** et jamais affichées dans « Aujourd'hui ».
- Le **prompt modèle** (6.4) insère la date du jour et demande à Claude de planifier **à partir d'aujourd'hui**, ce qui évite le problème à la source.
- Un planning mixte (une partie passée, une partie à venir) est donc géré sans ambiguïté.

### 5.3 Cas de test obligatoires (section 12)

- Import un mardi d'un fichier couvrant lundi→dimanche, option activée : lundi absent, mardi = aujourd'hui.
- Même fichier, option désactivée : lundi présent en `missed`, absent de « Aujourd'hui ».
- Passage de minuit appli ouverte : « Aujourd'hui » bascule au nouveau jour.
- Changement de fuseau dans les réglages : les tâches gardent leur date locale, les rappels sont reprogrammés.
- Fichier dont le `timezone` diffère des réglages : afficher un avertissement à l'aperçu.

---

## 6. Format d'import (JSON)

### 6.1 Exemple (fichier envoyé le mardi 2026-11-10)

```json
{
  "schema_version": 1,
  "timezone": "Africa/Porto-Novo",
  "generated_on": "2026-11-10",
  "plan_start": "2026-11-10",
  "plan_end": "2026-11-15",
  "day_bounds": { "start": "07:00", "end": "22:00" },
  "tasks": [
    {
      "title": "Cours d'algorithmique",
      "date": "2026-11-10",
      "start": "08:00",
      "end": "10:00",
      "category": "cours",
      "notes": "Salle B2",
      "reminder_before_min": 15
    },
    {
      "title": "Révisions",
      "date": "2026-11-10",
      "start": "14:00",
      "end": "16:00",
      "category": "etude"
    },
    {
      "title": "Sport",
      "date": "2026-11-10",
      "start": "17:30",
      "end": "18:30",
      "category": "activite"
    }
  ]
}
```

### 6.2 Champs

| Champ | Obligatoire | Règle |
|---|---|---|
| `schema_version` | oui | Entier, `1`. Refuser une version inconnue avec un message clair. |
| `timezone` | non | Nom IANA ; sinon fuseau des réglages. |
| `generated_on`, `plan_start`, `plan_end` | non | Dates `YYYY-MM-DD`, informatives et utilisées pour la plage de « remplacement ». |
| `day_bounds` | non | `start`/`end` `HH:mm` ; propose de mettre à jour les réglages. |
| `tasks[].title` | oui | Texte non vide, 120 caractères max. |
| `tasks[].date` | oui | `YYYY-MM-DD`. |
| `tasks[].start`, `tasks[].end` | oui | `HH:mm`, `end` > `start`, même jour. |
| `tasks[].category` | non | Un identifiant de catégorie (6.3) ; inconnu → `autre`. |
| `tasks[].notes` | non | Texte libre. |
| `tasks[].reminder_before_min` | non | Entier ≥ 0 ; sinon valeur par défaut des réglages. |

### 6.3 Catégories par défaut

Chaque catégorie = **icône Lucide + couleur** (la couleur n'est jamais le seul indicateur).

| id | Libellé | Icône Lucide | Couleur |
|---|---|---|---|
| `cours` | Cours | `graduation-cap` | #2563EB |
| `etude` | Étude | `book-open` | #7C3AED |
| `activite` | Activité | `dumbbell` | #059669 |
| `repos` | Repos / pause | `coffee` | #D97706 |
| `autre` | Autre | `circle-dot` | #64748B |

### 6.4 Prompt modèle (bouton « Copier le prompt »)

L'appli génère ce texte avec la date du jour et les réglages pré-remplis :

```
Nous sommes le {jour_semaine} {date_du_jour} (fuseau {timezone}).
Génère-moi mon emploi du temps à partir d'AUJOURD'HUI ({date_du_jour}) jusqu'au {date_fin}, en tenant compte de mon emploi du temps scolaire et des activités que je souhaite faire (que je te donne ci-dessous).
Journée de {day_start} à {day_end}. Aucune tâche ne doit se chevaucher ni traverser minuit.
Réponds UNIQUEMENT avec un fichier JSON valide, au format suivant (schema_version 1), avec des dates absolues AAAA-MM-JJ et des heures HH:mm.
Catégories autorisées : cours, etude, activite, repos, autre.
{schéma_exemple}

Mon emploi du temps scolaire : ...
Mes activités souhaitées (durée, fréquence, préférences) : ...
```

### 6.5 Validation à l'import

- Rejeter le fichier si le JSON est invalide ou `schema_version` inconnu, en affichant la ligne/le champ fautif.
- Ligne par ligne : signaler (sans bloquer tout l'import) les tâches invalides (`end <= start`, date mal formée, titre vide) ; elles sont exclues et listées.
- Détecter les **chevauchements** (avertissement, non bloquant) et les **doublons** (`title + date + start`).
- Aperçu avant validation : nombre de tâches par statut (passées / aujourd'hui / à venir), avertissements, choix **Remplacer** ou **Fusionner**.
  - **Remplacer** : supprimer les tâches `todo` de la plage de dates importée (conserver `done` et `cancelled`), puis insérer.
  - **Fusionner** : ajouter sans supprimer, en ignorant les doublons.
- Chaque import reçoit un `import_batch_id` (permet un futur « annuler l'import »).

---

## 7. Modèle de données

### 7.1 Tâche (`Task`)

| Champ | Type | Note |
|---|---|---|
| `id` | UUID | généré côté client |
| `title` | texte | |
| `date` | date | locale, absolue |
| `start_time`, `end_time` | `HH:mm` | locaux |
| `category_id` | texte | |
| `notes` | texte nullable | |
| `reminder_before_min` | int nullable | `null` = valeur par défaut des réglages |
| `status` | enum | `todo`, `done`, `cancelled`, `missed` |
| `shifted` | bool | vrai si l'horaire a été décalé après import |
| `original_start_time` | `HH:mm` nullable | pour afficher « décalée » |
| `source` | enum | `import`, `manual` |
| `import_batch_id` | UUID nullable | |
| `created_at`, `updated_at` | timestamp | |
| `deleted_at` | timestamp nullable | suppression logique (sync) |

Statut « décalée » = `shifted = true` (affiché avec icône + texte). Les 4 états visibles : à faire, faite, annulée, décalée (+ « passée » pour `missed`).

### 7.2 Réglages (`Settings`, une ligne)

`day_start` (def. 07:00), `day_end` (def. 22:00), `timezone`, `default_reminder_min` (def. 10), `morning_summary_enabled` (def. vrai), `morning_summary_time` (def. 07:00), `theme_mode` (`system|light|dark`), `updated_at`.

### 7.3 Schéma Supabase (`supabase/schema.sql`)

```sql
create table public.categories (
  id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  label text not null,
  icon text not null,
  color text not null,
  primary key (user_id, id)
);

create table public.tasks (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  date date not null,
  start_time time not null,
  end_time time not null check (end_time > start_time),
  category_id text not null default 'autre',
  notes text,
  reminder_before_min int check (reminder_before_min >= 0),
  status text not null default 'todo' check (status in ('todo','done','cancelled','missed')),
  shifted boolean not null default false,
  original_start_time time,
  source text not null default 'manual' check (source in ('import','manual')),
  import_batch_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index tasks_user_date_idx on public.tasks (user_id, date);

create table public.settings (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  day_start time not null default '07:00',
  day_end time not null default '22:00',
  timezone text not null default 'Africa/Porto-Novo',
  default_reminder_min int not null default 10,
  morning_summary_enabled boolean not null default true,
  morning_summary_time time not null default '07:00',
  theme_mode text not null default 'system',
  updated_at timestamptz not null default now()
);

alter table public.categories enable row level security;
alter table public.tasks      enable row level security;
alter table public.settings   enable row level security;

create policy "own rows" on public.categories for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.tasks      for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "own rows" on public.settings   for all using (user_id = auth.uid()) with check (user_id = auth.uid());
```

Sécurité : **désactiver les inscriptions publiques** dans Supabase une fois le compte unique créé ; la clé `anon` est publique par conception, c'est la RLS qui protège les données ; ne jamais embarquer la clé `service_role`.

---

## 8. Design system (direction A « Calendrier clair »)

### 8.1 Couleurs

| Token | Clair | Sombre (à valider en contraste ≥ 4,5:1) |
|---|---|---|
| `primary` | #2563EB | #3B82F6 |
| `onPrimary` | #FFFFFF | #0B1120 |
| `secondary` | #3B82F6 | #60A5FA |
| `accent` (succès, « faite ») | #059669 | #10B981 |
| `background` | #F8FAFC | #0F172A |
| `surface` / carte | #FFFFFF | #1E293B |
| `foreground` | #0F172A | #F1F5F9 |
| `mutedForeground` | #64748B | #94A3B8 |
| `muted` | #F1F5FD | #1E293B |
| `border` | #E4ECFC | #334155 |
| `destructive` (annulée) | #DC2626 | #F87171 |
| `ring` (focus) | #2563EB | #60A5FA |

Définir ces valeurs **une seule fois** comme tokens de thème (`ColorScheme` Material 3 + extension de thème) ; aucune couleur codée en dur dans les widgets.

### 8.2 Typographie

Plus Jakarta Sans (poids 400/500/600/700), embarquée. Corps ≥ 16 px. Respecter le facteur d'échelle du texte système.

### 8.3 Icônes

- Lucide uniquement, une seule taille de trait/épaisseur dans toute l'appli (24 px par défaut, 20 px dans les cartes).
- Jeu à utiliser : `calendar-days` (Semaine), `calendar-check`/`sun` (Aujourd'hui), `file-up` (Importer), `settings`, `plus`, `check`/`circle-check` (faite), `calendar-clock` (décaler), `x`/`circle-x` (annuler), `pencil`, `trash-2`, `bell`/`bell-ring`, `clock`, `chevron-left`/`chevron-right`, `battery-warning`, `info`, `copy`.
- Un état n'est **jamais** signalé par la seule couleur : icône + texte.

### 8.4 Illustrations

SVG unDraw recolorés en #2563EB, stockés dans `assets/illustrations/`, affichés via `flutter_svg`, **uniquement** pour : « Aucune tâche aujourd'hui », « Aucun planning importé », écran de connexion. Si le téléchargement est impossible, mettre un placeholder (grande icône Lucide) et laisser un `TODO(illustration)` — ne pas bloquer.

### 8.5 Règles UX

- Zones tactiles ≥ 48 dp, espacement ≥ 8 dp entre éléments cliquables.
- Transitions 150–300 ms ; respecter `MediaQuery.disableAnimations` (mouvement réduit).
- États de chargement visibles (squelette), jamais d'écran blanc.
- Focus clavier visible sur le web ; raccourcis clavier sur PC (`N` nouvelle tâche, `←/→` jour précédent/suivant, `T` aujourd'hui).
- Pas d'emojis, nulle part (UI, notifications, données).

---

## 9. Écrans et comportements

### 9.1 Mise en page adaptative

| Largeur | Navigation | Contenu |
|---|---|---|
| < 600 dp (mobile) | `NavigationBar` en bas, 4 onglets : **Aujourd'hui, Semaine, Importer, Réglages** | une colonne ; détail de tâche en *bottom sheet* |
| 600–1023 dp | `NavigationRail` à gauche | semaine sur 3 jours |
| ≥ 1024 dp (PC) | barre latérale gauche (mêmes 4 entrées) | **grille 7 colonnes** au centre + **panneau de détail** à droite |

C'est la même base de code ; seule la disposition change (`LayoutBuilder`).

### 9.2 Aujourd'hui

- En-tête : date complète en français + ligne de résumé (« 3 tâches restantes, prochaine à 14h »).
- Frise verticale de `day_start` à `day_end`, **trait « maintenant »** (mis à jour chaque minute), blocs colorés (icône + titre + horaire).
- Actions par bloc (menu ou glissement) : **Fait**, **Décaler** (+15 / +30 / +60 min ou heure choisie), **Annuler**, **Modifier**.
- Bouton d'action en haut : **Décaler toute la journée** (toutes les tâches `todo` à partir de maintenant, avec avertissement si la dernière dépasse `day_end`).
- Bouton flottant « + » (ajout manuel).
- État vide : illustration + « Rien de prévu aujourd'hui » + bouton « Importer un planning ».

### 9.3 Semaine

- Mobile : bande des 7 jours (jour courant mis en évidence) + liste du jour sélectionné.
- PC : grille 7 colonnes, jour courant mis en évidence ; clic sur un bloc ouvre le panneau de détail.
- Navigation semaine précédente / suivante, bouton « Aujourd'hui ».

### 9.4 Détail / édition d'une tâche

Titre, date, début, fin, catégorie, rappel (délai ou aucun), notes, statut. Boutons : Fait, Décaler, Annuler, Supprimer. Validation `end > start`.

### 9.5 Importer

Sélecteur de fichier `.json` (+ zone de dépôt sur le web), **bouton « Copier le prompt »** (6.4), aperçu (6.5), option « Importer à partir d'aujourd'hui », choix Remplacer / Fusionner, confirmation.

### 9.6 Réglages

Début/fin de journée, heure du résumé du matin (+ activation), rappel par défaut, fuseau, thème, **assistance batterie** (voir 10.5), état de la synchronisation, déconnexion. Sur le web, afficher un encart : « Les rappels sonnent sur le téléphone. Sur PC, ils s'affichent seulement tant que l'onglet est ouvert. »

---

## 10. Notifications (Android)

### 10.1 Types

1. **Rappel de début** : à l'heure de début de la tâche. Texte : « C'est l'heure : {titre} » + horaire.
2. **Pré-rappel** : `reminder_before_min` minutes avant (si défini et > 0).
3. **Résumé du matin** : à `morning_summary_time`. Texte : « Aujourd'hui : {titre} à {heure}, {titre} à {heure}… » (style texte long, tronqué proprement) ; si aucune tâche : « Rien de prévu aujourd'hui ».

Aucun emoji dans les textes. Canaux Android : `rappels` (importance haute, son) et `resume` (importance par défaut).

### 10.2 Fenêtre de programmation

Programmer les notifications des **7 prochains jours** (plafond 200 notifications au total, la limite Android étant plus basse que ce qu'on pourrait croire). Reprogrammer en entier à : lancement, retour au premier plan, import, ajout/modification/décalage/annulation/suppression de tâche, changement de réglages, changement de fuseau, **redémarrage du téléphone**.

### 10.3 Contenu du résumé

Le résumé de chaque jour est **construit au moment de la programmation** à partir des tâches `todo` de ce jour ; il est donc reconstruit à chaque modification (10.2). Les tâches `cancelled`, `done` et `missed` sont exclues.

### 10.4 Règles

- Une tâche `cancelled` ou `done` n'a **aucun** rappel (annuler la notification programmée).
- Une tâche dont l'heure est déjà passée n'est pas programmée.
- Décaler une tâche reprogramme ses rappels.
- Utiliser `zonedSchedule` avec le fuseau configuré et `AndroidScheduleMode.exactAllowWhileIdle`.

### 10.5 Permissions et fiabilité (point de risque n°1)

- `POST_NOTIFICATIONS` (Android 13+) : demandée au premier lancement avec une explication.
- **Alarmes exactes** : déclarer `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` selon la version et guider l'utilisatrice vers le réglage « Alarmes et rappels » si refusé.
- `RECEIVE_BOOT_COMPLETED` et le récepteur de reprogrammation au démarrage de `flutter_local_notifications`.
- **Économie de batterie** : beaucoup de téléphones (Xiaomi, Tecno, Infinix, Samsung…) tuent les applis en arrière-plan. Écran « Assistance batterie » dans les réglages : demande d'exclusion de l'optimisation de batterie (`ignoreBatteryOptimizations`), explication pas à pas, lien d'aide vers dontkillmyapp.com, et bouton **« Envoyer une notification de test dans 1 minute »**.

### 10.6 Actions dans la notification (phase 4, optionnel)

Boutons **Fait** et **Décaler 15 min** sur le rappel, via un gestionnaire d'arrière-plan de haut niveau.

### 10.7 Web

Pas de rappel programmé fiable. Sur PC, un bandeau/toast interne « C'est l'heure : … » peut apparaître tant que l'onglet est ouvert (facultatif, phase 4).

---

## 11. Synchronisation

1. **Source de vérité locale** (SQLite) sur Android : l'appli et les rappels marchent hors ligne.
2. Les écritures vont d'abord en local, puis sont poussées à Supabase (file d'attente si hors ligne).
3. **Résolution de conflits** : le plus récent (`updated_at`) gagne, au niveau de la ligne.
4. Suppressions via `deleted_at` (jamais de suppression physique côté sync).
5. Sync au lancement, au retour au premier plan, et via Realtime quand l'appli est ouverte.
6. **Web** : si le stockage local web complique la v1, lire/écrire directement dans Supabase avec un cache mémoire ; documenter le choix dans `docs/DECISIONS.md`.
7. Authentification : e-mail + mot de passe (compte unique), session persistée ; écran de connexion minimal avec illustration.

---

## 12. Tests

Tests unitaires obligatoires (avec une horloge injectable) :

- Logique « aujourd'hui » et cas de la section 5.3.
- Parsing/validation du JSON d'import (valide, champs manquants, `end <= start`, version inconnue, catégorie inconnue, doublons, chevauchements).
- Remplacer vs fusionner.
- Décaler une tâche et décaler la journée (y compris dépassement de `day_end`).
- Calcul de la liste de notifications (fenêtre de 7 jours, plafond, exclusion des tâches annulées/faites/passées, contenu du résumé, jour sans tâche).
- Conversion heure locale → instant absolu avec le fuseau `Africa/Porto-Novo`.

Tests de widgets : mise en page aux trois largeurs (390, 800, 1280), état vide, frise « Aujourd'hui ».

Checklist manuelle sur téléphone réel : rappel reçu écran éteint, après redémarrage, après fermeture de l'appli, avec économie de batterie active/désactivée ; import le « mauvais » jour ; passage de minuit.

---

## 13. Livraison

- **APK** : `flutter build apk --release` ; configurer une clé de signature locale (`keystore`, hors Git) ; instructions d'installation dans `README.md` (autoriser l'installation depuis une source inconnue).
- **Web** : `flutter build web` ; déploiement gratuit (Vercel, Netlify, Cloudflare Pages ou GitHub Pages) ; documenter la commande et la configuration des variables d'environnement.
- `README.md` : installation, variables d'environnement, lancement, génération de l'APK, déploiement web.

---

## 14. Plan de développement (phases et critères d'acceptation)

### Phase 0 — Socle
Projet Flutter, thème A (clair/sombre), police embarquée, Lucide, shell adaptatif (4 destinations, 3 largeurs), CI locale (`flutter analyze`, `flutter test`).
**Acceptation** : l'appli tourne sur le téléphone **et** dans Chrome ; la navigation s'adapte à la largeur ; aucune couleur codée en dur.

### Phase 1 — Données locales, import, vues, gestion des jours
Modèles, base locale, import JSON complet (aperçu, validation, remplacer/fusionner, « à partir d'aujourd'hui »), **Aujourd'hui**, **Semaine**, CRUD de tâches, décaler / décaler la journée / annuler / fait, prompt modèle, logique de dates (section 5) et ses tests.
**Acceptation** : tous les cas de 5.3 passent ; import d'un planning un mardi n'affiche jamais le lundi comme aujourd'hui.

### Phase 2 — Notifications
Rappels, pré-rappels, résumé du matin, canaux, permissions, alarmes exactes, reprogrammation (modifs + redémarrage), assistance batterie + notification de test.
**Acceptation** : sur téléphone réel, rappel reçu à la minute près écran éteint et après redémarrage ; tâche annulée = aucun rappel.

### Phase 3 — Supabase et web
Projet Supabase (schéma 7.3), authentification, sync local-first, Realtime, version web déployée.
**Acceptation** : une tâche modifiée sur PC apparaît sur le téléphone (et inversement) ; l'appli téléphone marche hors ligne ; inscriptions publiques désactivées.

### Phase 4 — Finitions
Actions dans les notifications, illustrations des écrans vides, raccourcis clavier PC, accessibilité (sémantique, contraste, échelle du texte), APK de release signé, README.
**Acceptation** : checklist manuelle (section 12) entièrement cochée.

---

## 15. Définition de « terminé »

- Les 4 phases validées, tests au vert, `flutter analyze` sans erreur.
- Aucun emoji dans l'appli, aucune couleur codée en dur, aucun secret dans Git.
- Les rappels fonctionnent sur le téléphone de l'utilisatrice dans les conditions réelles (écran éteint, appli fermée, après redémarrage).
- `docs/DECISIONS.md` liste toute décision prise hors de ce document.
