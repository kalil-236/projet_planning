import 'dart:async';
import 'dart:convert';

import 'package:assistant_planning/domain/plan_parser.dart';
import 'package:assistant_planning/platform/shared_plan.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

final _planJson = const JsonEncoder.withIndent('  ').convert({
  'schema_version': 1,
  'tasks': [
    {
      'title': 'Sport',
      'date': tuesday.toIso(),
      'start': '17:00',
      'end': '18:00',
      'category': 'activite',
    },
  ],
});

class _FakeSharedPlanSource implements SharedPlanSource {
  _FakeSharedPlanSource([this.first]);

  final SharedPlan? first;
  final controller = StreamController<SharedPlan>.broadcast();

  @override
  Future<SharedPlan?> initial() async => first;

  @override
  Stream<SharedPlan> get incoming => controller.stream;
}

void _mockClipboard(String? text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return text == null ? null : {'text': text};
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
}

void main() {
  setUpAll(initAppFormats);

  group('planning collé', () {
    test('JSON seul', () {
      expect(parsePastedPlan(_planJson).tasks.single.title, 'Sport');
    });

    test('bloc de code entouré de texte', () {
      final answer =
          'Voici votre planning :\n```json\n$_planJson\n```\nBonne semaine !';
      expect(parsePastedPlan(answer).tasks.single.title, 'Sport');
    });

    test('phrase avant et après, sans bloc de code', () {
      expect(
        parsePastedPlan('Le voici : $_planJson Bonne journée.').tasks,
        hasLength(1),
      );
    });

    test('aucun objet JSON : message clair', () {
      expect(
        () => parsePastedPlan('Bonjour, voici ma semaine.'),
        throwsA(
          isA<ImportRejected>().having(
            (e) => e.message,
            'message',
            contains('JSON'),
          ),
        ),
      );
    });
  });

  group('écran Importer', () {
    testWidgets('« Coller le planning » affiche l\'aperçu', (tester) async {
      _mockClipboard('Voici :\n```json\n$_planJson\n```');
      await pumpApp(tester);
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Coller le planning'));
      await tester.pumpAndSettle();
      expect(find.text('Texte collé'), findsOneWidget);
      expect(find.text('Importer 1 tâche'), findsOneWidget);
    });

    testWidgets('presse-papiers vide : explication', (tester) async {
      _mockClipboard(null);
      await pumpApp(tester);
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Coller le planning'));
      await tester.pumpAndSettle();
      expect(find.textContaining('presse-papiers est vide'), findsOneWidget);
    });

    testWidgets('fichier partagé au lancement : ouvre l\'aperçu', (
      tester,
    ) async {
      await pumpApp(
        tester,
        sharedPlanSource: _FakeSharedPlanSource(
          SharedPlan(name: 'semaine.json', text: _planJson),
        ),
      );
      expect(find.text('semaine.json'), findsOneWidget);
      expect(find.text('Importer 1 tâche'), findsOneWidget);
    });

    testWidgets('partage reçu application ouverte', (tester) async {
      final source = _FakeSharedPlanSource();
      await pumpApp(tester, sharedPlanSource: source);
      expect(find.text('Coller le planning'), findsNothing);

      source.controller.add(
        const SharedPlan(name: 'photo.jpg', error: 'format inconnu'),
      );
      await tester.pumpAndSettle();
      expect(find.text('photo.jpg'), findsOneWidget);
      expect(find.textContaining('format inconnu'), findsOneWidget);
    });
  });
}
