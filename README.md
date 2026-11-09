# Assistant de planification

Application Flutter personnelle (Android et web), en français, qui importe un planning hebdomadaire, l'affiche et envoie des rappels. La référence complète est [SPEC_assistant_planning.md](SPEC_assistant_planning.md).

## Lancer l'application

```powershell
flutter pub get
flutter run -d chrome     # web
flutter run -d <appareil> # téléphone Android ou émulateur
```

## Vérifier le code

```powershell
powershell -ExecutionPolicy Bypass -File tool\ci.ps1
```

Ce script contrôle le formatage, lance `flutter analyze` et `flutter test`. Les tests vérifient aussi qu'il n'y a ni couleur codée en dur, ni icône hors Lucide, ni emoji.

Les décisions techniques prises hors spécification sont listées dans [docs/DECISIONS.md](docs/DECISIONS.md).
