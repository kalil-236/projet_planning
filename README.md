# F.R.I.D.A.Y

Application Flutter personnelle (Android et web), en français, qui importe un planning hebdomadaire, l'affiche et envoie des rappels. La référence complète est [SPEC_assistant_planning.md](SPEC_assistant_planning.md).

## Lancer l'application

```powershell
flutter pub get
flutter run -d chrome     # web
flutter run -d <appareil> # téléphone Android ou émulateur
```

Sans configuration Supabase, l'application fonctionne en local, sans compte ni synchronisation.

## Configurer Supabase

1. Créez un projet gratuit sur [supabase.com](https://supabase.com).
2. Dans **SQL Editor**, exécutez le contenu de [supabase/schema.sql](supabase/schema.sql).
3. Dans **Authentication > Users**, créez votre compte avec **Add user**, en cochant la confirmation automatique.
4. Dans les réglages **Authentication** de connexion, désactivez **Allow new users to sign up**.
5. Dans **Project Settings > API**, relevez l'URL du projet et la clé `anon` (ou `publishable`). N'utilisez jamais la clé `service_role`.
6. Copiez `env.example.json` vers `env.json` et renseignez ces deux valeurs. Ce fichier est ignoré par Git.

```powershell
flutter run -d chrome --dart-define-from-file=env.json
```

## Générer l'APK

```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=env.json
```

Pour un téléphone récent, installez `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`.

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
