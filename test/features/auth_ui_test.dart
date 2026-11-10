import 'package:assistant_planning/sync/sync_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_sync_backend.dart';
import '../support/test_app.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('Réglages'));
  await tester.pumpAndSettle();
}

Future<void> _fillLogin(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'a@b.fr');
  await tester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'x');
  await tester.tap(find.text('Se connecter'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initAppFormats);

  testWidgets('web : sans session, seul l\'écran de connexion est visible', (
    tester,
  ) async {
    await pumpApp(
      tester,
      width: 1280,
      syncBackend: FakeSyncBackend(FakeServer(), signedIn: false),
      loginRequired: true,
    );

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsNothing);
  });

  testWidgets('web : la connexion ouvre l\'application', (tester) async {
    await pumpApp(
      tester,
      width: 1280,
      syncBackend: FakeSyncBackend(FakeServer(), signedIn: false),
      loginRequired: true,
    );

    await _fillLogin(tester);

    expect(find.text('Connexion'), findsNothing);
    expect(find.text('Aujourd\'hui'), findsWidgets);
  });

  testWidgets('web : la déconnexion ramène à l\'écran de connexion', (
    tester,
  ) async {
    await pumpApp(
      tester,
      width: 1280,
      syncBackend: FakeSyncBackend(FakeServer()),
      loginRequired: true,
    );
    await _openSettings(tester);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('mot de passe refusé : message clair, on reste sur l\'écran', (
    tester,
  ) async {
    final backend = FakeSyncBackend(FakeServer(), signedIn: false)
      ..signInFailure = const SignInFailure(
        SignInFailureReason.invalidCredentials,
      );
    await pumpApp(tester, syncBackend: backend, loginRequired: true);

    await _fillLogin(tester);

    expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('champs vides : la connexion n\'est pas tentée', (tester) async {
    await pumpApp(
      tester,
      syncBackend: FakeSyncBackend(FakeServer(), signedIn: false),
      loginRequired: true,
    );

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(
      find.text('Saisissez votre e-mail et votre mot de passe.'),
      findsOneWidget,
    );
  });

  testWidgets('Android : l\'application reste utilisable sans compte', (
    tester,
  ) async {
    await pumpApp(
      tester,
      syncBackend: FakeSyncBackend(FakeServer(), signedIn: false),
    );

    expect(find.text('Connexion'), findsNothing);
    expect(find.text('Aujourd\'hui'), findsWidgets);

    await _openSettings(tester);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('sans configuration Supabase, aucune mention de compte', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openSettings(tester);

    expect(find.text('Se connecter'), findsNothing);
    expect(find.text('Se déconnecter'), findsNothing);
  });
}
