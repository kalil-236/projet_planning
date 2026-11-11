# F.R.I.D.A.Y

Application Flutter personnelle (Android et web), en français, qui importe un planning hebdomadaire, l'affiche et envoie des rappels. La référence complète est [SPEC_assistant_planning.md](SPEC_assistant_planning.md).

## Lancer l'application

```powershell
flutter pub get
flutter run -d chrome     # web
flutter run -d <appareil> # téléphone Android ou émulateur
```

Sans configuration Supabase, l'application fonctionne en local, sans compte ni synchronisation.

Raccourcis clavier sur PC : `N` nouvelle tâche, `T` aujourd'hui, `←` et `→` jour précédent et suivant dans Semaine.

## Fonctionnalités de la version 1.1

- **Importer** : « Coller le planning » lit la réponse de Claude copiée telle quelle. Sur Android, un fichier JSON partagé ou ouvert avec F.R.I.D.A.Y arrive directement dans l'aperçu.
- **Aujourd'hui** : ajout express en une phrase (« sport demain 18h 1h »), créneaux libres en pointillés (les toucher pour y ajouter une tâche), chevauchements signalés, gestes (glisser à droite : faite ; à gauche : décalée de 15 min, avec « Annuler »).
- **Bilan** : taux de la semaine, série de jours réussis, temps par catégorie, et observations de F.R.I.D.A.Y ajoutées au prompt de la semaine suivante.
- **Notifications** : la tâche en cours reste affichée avec un compte à rebours (mise en avant sur Android 16), rapport du soir avec « Reporter à demain », bilan de la semaine le dimanche soir.
- **Widget d'accueil** « Prochaine mission » : appui long sur l'écran d'accueil, **Widgets**, F.R.I.D.A.Y.
- **Voix** : F.R.I.D.A.Y lit le briefing et le bilan avec la voix française de l'appareil, réglable dans **Réglages > Voix de F.R.I.D.A.Y**.

## Variables d'environnement

| Nom | Rôle |
|---|---|
| `SUPABASE_URL` | URL du projet Supabase |
| `SUPABASE_ANON_KEY` | Clé publique `anon` ou `publishable` du projet, protégée par les règles d'accès des tables |

Elles sont lues à la compilation, depuis `env.json` en local et depuis les variables du dépôt GitHub pour le web.

## Configurer Supabase

1. Créez un projet gratuit sur [supabase.com](https://supabase.com).
2. Dans **SQL Editor**, exécutez le contenu de [supabase/schema.sql](supabase/schema.sql).
3. Dans **Authentication > Users**, créez votre compte avec **Add user**, en cochant la confirmation automatique.
4. Dans les réglages **Authentication** de connexion, désactivez **Allow new users to sign up**.
5. Dans **Project Settings > API**, relevez l'URL du projet et la clé `anon` (ou `publishable`). N'utilisez jamais la clé `service_role`.
6. Copiez `env.example.json` vers `env.json` et renseignez ces deux valeurs. Ce fichier est ignoré par Git.

Projet créé avant la version 1.1 : exécutez une fois [supabase/migrations/002_completed_at.sql](supabase/migrations/002_completed_at.sql) dans **SQL Editor**. Sans cette colonne, la synchronisation continue, mais l'heure à laquelle une tâche est faite reste sur l'appareil.

```powershell
flutter run -d chrome --dart-define-from-file=env.json
```

## Générer l'APK

### Clé de signature

L'APK de release est signé avec une clé personnelle, gardée hors du dépôt. À faire une seule fois :

```powershell
keytool -genkeypair -v -keystore $env:USERPROFILE\.keystores\friday-release.jks `
  -storetype PKCS12 -alias friday -keyalg RSA -keysize 2048 -validity 10000
```

Puis créez `android\key.properties`, ignoré par Git :

```properties
storePassword=<mot de passe choisi>
keyPassword=<mot de passe choisi>
keyAlias=friday
storeFile=C:/Users/<vous>/.keystores/friday-release.jks
```

Sauvegardez ces deux fichiers ailleurs que sur le PC, par exemple sur une clé USB. Sans eux, une nouvelle version ne pourra plus s'installer par-dessus l'ancienne : il faudrait désinstaller l'application, ce qui efface les données qui n'ont pas été synchronisées.

Sans `key.properties`, l'APK est signé avec la clé de débogage du PC.

### Compiler

```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=env.json
```

Pour un téléphone récent, utilisez `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`.

### Installer sur le téléphone

1. Copiez l'APK sur le téléphone (câble USB, Google Drive ou e-mail).
2. Ouvrez-le depuis l'application **Fichiers**. Android demande d'autoriser l'installation depuis cette source : acceptez pour cette application seulement.
3. Au premier lancement, acceptez les notifications, puis ouvrez **Réglages > Assistance batterie** pour exclure l'application de l'optimisation de batterie.

Une mise à jour s'installe par-dessus l'ancienne version, sans perte de données, tant qu'elle est signée avec la même clé.

## Déployer le web

Le déploiement sur GitHub Pages se fait à chaque envoi sur `main`, une fois ces réglages faits sur le dépôt GitHub :

1. **Settings > Pages** : choisissez **GitHub Actions** comme source.
2. **Settings > Secrets and variables > Actions > Variables** : créez `SUPABASE_URL` et `SUPABASE_ANON_KEY`.
3. **Actions > Déployer le web > Run workflow** lance le premier déploiement.

## Vérifier le code

```powershell
powershell -ExecutionPolicy Bypass -File tool\ci.ps1
```

Ce script contrôle le formatage, lance `flutter analyze` et `flutter test`. Les tests vérifient aussi qu'il n'y a ni couleur codée en dur, ni icône hors Lucide, ni emoji.

Les décisions techniques prises hors spécification sont listées dans [docs/DECISIONS.md](docs/DECISIONS.md).
