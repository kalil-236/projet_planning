import 'dart:convert';

import 'package:assistant_planning/core/french_format.dart';
import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/plan_import.dart';
import 'package:assistant_planning/domain/plan_parser.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

Map<String, Object?> taskJson(
  String title,
  String date, {
  String start = '08:00',
  String end = '09:00',
  Object? category,
}) => {
  'title': title,
  'date': date,
  'start': start,
  'end': end,
  'category': ?category,
};

String planJson(
  List<Object?> tasks, {
  Object? version = 1,
  String? timezone,
  Map<String, Object?> extra = const {},
}) => jsonEncode({
  'schema_version': version,
  'timezone': ?timezone,
  ...extra,
  'tasks': tasks,
});

/// Fichier couvrant du lundi 9 au dimanche 15 novembre 2026.
ParsedPlan fullWeekPlan() => parsePlanJson(
  planJson(
    [
      for (var i = 0; i < 7; i++)
        taskJson('Jour $i', monday.addDays(i).toIso(), category: 'cours'),
    ],
    extra: {'plan_start': '2026-11-09', 'plan_end': '2026-11-15'},
  ),
);

ImportChanges runImport(
  ParsedPlan plan, {
  List<Task> existing = const [],
  ImportMode mode = ImportMode.merge,
  bool fromToday = true,
}) {
  var counter = 0;
  return prepareImport(
    plan: plan,
    existing: existing,
    today: tuesday,
    mode: mode,
    fromToday: fromToday,
    batchId: 'batch',
    nowUtc: fixedInstant,
    newId: () => 'id${counter++}',
  );
}

void main() {
  setUpAll(initFrenchFormats);

  group('rejets du fichier', () {
    test('JSON invalide : indique la ligne', () {
      expect(
        () => parsePlanJson('{\n  "schema_version": 1,\n  oups\n}'),
        throwsA(
          isA<ImportRejected>().having(
            (e) => e.message,
            'message',
            contains('ligne 3'),
          ),
        ),
      );
    });

    test('version inconnue : nomme le champ', () {
      expect(
        () => parsePlanJson(planJson([], version: 2)),
        throwsA(
          isA<ImportRejected>().having(
            (e) => e.message,
            'message',
            contains('schema_version'),
          ),
        ),
      );
    });

    test('version manquante, racine incorrecte, tasks absent', () {
      expect(
        () => parsePlanJson('{"tasks":[]}'),
        throwsA(isA<ImportRejected>()),
      );
      expect(() => parsePlanJson('[]'), throwsA(isA<ImportRejected>()));
      expect(
        () => parsePlanJson('{"schema_version":1}'),
        throwsA(isA<ImportRejected>()),
      );
    });

    test('accepte le BOM en tête de fichier', () {
      expect(parsePlanJson('﻿${planJson([])}').tasks, isEmpty);
    });
  });

  group('validation ligne par ligne', () {
    test('exemple de la spécification (6.1)', () {
      final plan = parsePlanJson(
        jsonEncode({
          'schema_version': 1,
          'timezone': 'Africa/Porto-Novo',
          'generated_on': '2026-11-10',
          'plan_start': '2026-11-10',
          'plan_end': '2026-11-15',
          'day_bounds': {'start': '07:00', 'end': '22:00'},
          'tasks': [
            {
              'title': "Cours d'algorithmique",
              'date': '2026-11-10',
              'start': '08:00',
              'end': '10:00',
              'category': 'cours',
              'notes': 'Salle B2',
              'reminder_before_min': 15,
            },
          ],
        }),
      );
      final task = plan.tasks.single;
      expect(plan.invalidTasks, isEmpty);
      expect(plan.notices, isEmpty);
      expect(task.category, TaskCategory.cours);
      expect(task.notes, 'Salle B2');
      expect(task.reminderBeforeMin, 15);
      expect(plan.planEnd, const LocalDate(2026, 11, 15));
      expect(plan.dayStart.toString(), '07:00');
    });

    test('exclut les tâches invalides sans bloquer les autres', () {
      final plan = parsePlanJson(
        planJson([
          taskJson('OK', '2026-11-10'),
          taskJson(
            'Fin avant début',
            '2026-11-10',
            start: '10:00',
            end: '09:00',
          ),
          taskJson('Fin égale', '2026-11-10', start: '10:00', end: '10:00'),
          taskJson('Date', '2026-02-30'),
          taskJson('   ', '2026-11-10'),
          taskJson('x' * 121, '2026-11-10'),
          taskJson('Heure', '2026-11-10', start: '8h'),
          'pas un objet',
        ]),
      );
      expect(plan.tasks.single.title, 'OK');
      expect(plan.invalidTasks, hasLength(7));
      expect(plan.invalidTasks.first.position, 2);
      expect(plan.invalidTasks.first.reasons.single, contains('tasks[1].end'));
      expect(plan.invalidTasks[2].reasons.single, contains('tasks[3].date'));
    });

    test('champs obligatoires manquants', () {
      final plan = parsePlanJson(planJson([<String, Object?>{}]));
      expect(plan.tasks, isEmpty);
      expect(plan.invalidTasks.single.reasons, hasLength(4));
    });

    test('catégorie inconnue : remplacée par autre, avec une remarque', () {
      final plan = parsePlanJson(
        planJson([taskJson('A', '2026-11-10', category: 'musique')]),
      );
      expect(plan.tasks.single.category, TaskCategory.autre);
      expect(plan.notices.single, contains('musique'));
    });

    test('rappel invalide : valeur par défaut', () {
      final plan = parsePlanJson(
        planJson([
          {...taskJson('A', '2026-11-10'), 'reminder_before_min': -5},
        ]),
      );
      expect(plan.tasks.single.reminderBeforeMin, isNull);
      expect(plan.notices, hasLength(1));
    });

    test('retire les emojis du titre', () {
      final plan = parsePlanJson(
        planJson([taskJson('Sport \u{1F3C3}', '2026-11-10')]),
      );
      expect(plan.tasks.single.title, 'Sport');
    });
  });

  group('aperçu', () {
    test('classe les tâches passées, du jour et à venir', () {
      final preview = buildImportPreview(
        plan: fullWeekPlan(),
        today: tuesday,
        settingsTimezone: 'Africa/Porto-Novo',
        fromToday: true,
      );
      expect(preview.pastCount, 1);
      expect(preview.todayCount, 1);
      expect(preview.upcomingCount, 5);
      expect(preview.importableCount, 6);
    });

    test('section 5.3 : fuseau du fichier différent des réglages', () {
      final plan = parsePlanJson(planJson([], timezone: 'Europe/Paris'));
      final preview = buildImportPreview(
        plan: plan,
        today: tuesday,
        settingsTimezone: 'Africa/Porto-Novo',
        fromToday: true,
      );
      expect(preview.fileTimezoneMismatch, 'Europe/Paris');
    });

    test('pas d\'avertissement si le fuseau est identique ou absent', () {
      for (final timezone in ['Africa/Porto-Novo', null]) {
        final preview = buildImportPreview(
          plan: parsePlanJson(planJson([], timezone: timezone)),
          today: tuesday,
          settingsTimezone: 'Africa/Porto-Novo',
          fromToday: true,
        );
        expect(preview.fileTimezoneMismatch, isNull);
      }
    });

    test('détecte chevauchements et doublons', () {
      final plan = parsePlanJson(
        planJson([
          taskJson('A', '2026-11-10', start: '08:00', end: '10:00'),
          taskJson('B', '2026-11-10', start: '09:00', end: '11:00'),
          taskJson('C', '2026-11-10', start: '11:00', end: '12:00'),
          taskJson('D', '2026-11-11', start: '09:00', end: '11:00'),
          taskJson('A', '2026-11-10', start: '08:00', end: '09:30'),
        ]),
      );
      final preview = buildImportPreview(
        plan: plan,
        today: tuesday,
        settingsTimezone: 'Africa/Porto-Novo',
        fromToday: true,
      );
      expect(preview.duplicates.single.title, 'A');
      expect(preview.importableCount, 4);
      expect(preview.overlaps, hasLength(1));
      expect(preview.overlaps.single.first.title, 'A');
      expect(preview.overlaps.single.second.title, 'B');
    });
  });

  group('section 5.3 : planning reçu en retard', () {
    test('option activée : lundi absent, mardi présent', () {
      final changes = runImport(fullWeekPlan());
      final dates = changes.toInsert.map((t) => t.date).toSet();
      expect(dates, isNot(contains(monday)));
      expect(dates, contains(tuesday));
      expect(changes.toInsert, hasLength(6));
      expect(
        changes.toInsert.every((t) => t.status == TaskStatus.todo),
        isTrue,
      );
    });

    test('option désactivée : lundi présent en missed', () {
      final changes = runImport(fullWeekPlan(), fromToday: false);
      expect(changes.toInsert, hasLength(7));
      final mondayTask = changes.toInsert.singleWhere((t) => t.date == monday);
      expect(mondayTask.status, TaskStatus.missed);
      final tuesdayTask = changes.toInsert.singleWhere(
        (t) => t.date == tuesday,
      );
      expect(tuesdayTask.status, TaskStatus.todo);
    });
  });

  group('remplacer et fusionner', () {
    final plan = parsePlanJson(
      planJson(
        [taskJson('Nouveau', '2026-11-10', start: '12:00', end: '13:00')],
        extra: {'plan_start': '2026-11-10', 'plan_end': '2026-11-15'},
      ),
    );

    test('remplacer : retire les todo, conserve done et cancelled', () {
      final todo = makeTask(id: 'todo');
      final done = makeTask(id: 'done', status: TaskStatus.done);
      final cancelled = makeTask(id: 'c', status: TaskStatus.cancelled);
      final changes = runImport(
        plan,
        existing: [todo, done, cancelled],
        mode: ImportMode.replace,
      );
      expect(changes.toRemove.map((t) => t.id), ['todo']);
      expect(changes.toInsert.single.title, 'Nouveau');
    });

    test('remplacer ne duplique pas une tâche déjà faite', () {
      final done = makeTask(
        title: 'Nouveau',
        start: '12:00',
        end: '13:00',
        status: TaskStatus.done,
      );
      final changes = runImport(
        plan,
        existing: [done],
        mode: ImportMode.replace,
      );
      expect(changes.toInsert, isEmpty);
      expect(changes.skippedDuplicates, 1);
    });

    test('fusionner : ne retire rien et ignore les doublons', () {
      final same = makeTask(title: 'Nouveau', start: '12:00', end: '13:00');
      final other = makeTask(id: 'o', title: 'Autre');
      final changes = runImport(plan, existing: [same, other]);
      expect(changes.toRemove, isEmpty);
      expect(changes.toInsert, isEmpty);
      expect(changes.skippedDuplicates, 1);
    });

    test('les tâches importées portent le batch et la source', () {
      final task = runImport(plan).toInsert.single;
      expect(task.importBatchId, 'batch');
      expect(task.source, TaskSource.import);
    });
  });

  group('plage de remplacement', () {
    test('avec l\'option, ne remonte pas avant aujourd\'hui', () {
      final range = importRange(
        plan: fullWeekPlan(),
        today: tuesday,
        fromToday: true,
      );
      expect(range, const DateRange(tuesday, LocalDate(2026, 11, 15)));
    });

    test('sans l\'option, couvre les dates déclarées', () {
      final range = importRange(
        plan: fullWeekPlan(),
        today: tuesday,
        fromToday: false,
      );
      expect(range, const DateRange(monday, LocalDate(2026, 11, 15)));
    });

    test('sans dates déclarées, utilise celles des tâches', () {
      final plan = parsePlanJson(
        planJson([taskJson('A', '2026-11-12'), taskJson('B', '2026-11-11')]),
      );
      final range = importRange(plan: plan, today: tuesday, fromToday: true);
      expect(range, const DateRange(wednesday, LocalDate(2026, 11, 12)));
    });

    test('rien à importer : pas de plage', () {
      final plan = parsePlanJson(planJson([taskJson('A', '2026-11-09')]));
      expect(importRange(plan: plan, today: tuesday, fromToday: true), isNull);
    });
  });
}
