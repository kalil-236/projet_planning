import 'dart:convert';

import 'package:assistant_planning/core/french_format.dart';
import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/plan_parser.dart';
import 'package:assistant_planning/domain/plan_prompt.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:assistant_planning/domain/task_ops.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const _dayEnd = LocalTime(22, 0);

DayShiftPlan planShift(List<Task> tasks, int minutes, {String now = '09:00'}) =>
    planDayShift(
      tasks: tasks,
      now: LocalDateTime(tuesday, LocalTime.parse(now)),
      minutes: minutes,
      dayEnd: _dayEnd,
      nowUtc: fixedInstant,
    );

void main() {
  setUpAll(initFrenchFormats);

  group('décaler une tâche', () {
    test('conserve la durée et marque la tâche décalée', () {
      final moved = shiftTaskBy(makeTask(), 30, fixedInstant)!;
      expect(moved.start, const LocalTime(8, 30));
      expect(moved.end, const LocalTime(10, 30));
      expect(moved.shifted, isTrue);
      expect(moved.originalStart, const LocalTime(8, 0));
      expect(moved.displayState, TaskDisplayState.shifted);
    });

    test('garde l\'heure d\'origine après plusieurs décalages', () {
      final first = shiftTaskBy(makeTask(), 30, fixedInstant)!;
      final second = shiftTaskBy(first, 15, fixedInstant)!;
      expect(second.start, const LocalTime(8, 45));
      expect(second.originalStart, const LocalTime(8, 0));
    });

    test('décalage vers une heure choisie', () {
      final moved = shiftTaskTo(
        makeTask(),
        const LocalTime(14, 0),
        fixedInstant,
      )!;
      expect(moved.start, const LocalTime(14, 0));
      expect(moved.end, const LocalTime(16, 0));
    });

    test('refuse de traverser minuit', () {
      final late = makeTask(start: '23:00', end: '23:30');
      expect(shiftTaskBy(late, 30, fixedInstant), isNull);
      expect(shiftTaskBy(late, 29, fixedInstant), isNotNull);
    });
  });

  group('décaler la journée', () {
    test('ne décale que les tâches todo non terminées du jour', () {
      final plan = planShift([
        makeTask(id: 'finie', start: '07:00', end: '08:00'),
        makeTask(id: 'en_cours', start: '08:30', end: '09:30'),
        makeTask(id: 'a_venir', start: '10:00', end: '11:00'),
        makeTask(
          id: 'faite',
          start: '12:00',
          end: '13:00',
          status: TaskStatus.done,
        ),
        makeTask(
          id: 'annulee',
          start: '12:00',
          end: '13:00',
          status: TaskStatus.cancelled,
        ),
        makeTask(id: 'demain', date: wednesday, start: '10:00', end: '11:00'),
      ], 30);
      expect(plan.shifted.map((t) => t.id), ['en_cours', 'a_venir']);
      expect(plan.canApply, isTrue);
      expect(plan.exceedsDayEnd, isFalse);
    });

    test('signale le dépassement de la fin de journée', () {
      final plan = planShift([makeTask(start: '20:00', end: '21:45')], 30);
      expect(plan.exceedsDayEnd, isTrue);
      expect(plan.latestEnd, const LocalTime(22, 15));
      expect(plan.canApply, isTrue);
    });

    test('finir exactement à la fin de journée n\'est pas un dépassement', () {
      final plan = planShift([makeTask(start: '20:00', end: '21:30')], 30);
      expect(plan.exceedsDayEnd, isFalse);
    });

    test('refuse tout le décalage si une tâche traverserait minuit', () {
      final plan = planShift([
        makeTask(id: 'a', start: '10:00', end: '11:00'),
        makeTask(id: 'b', start: '23:00', end: '23:50'),
      ], 30);
      expect(plan.blockedByMidnight.single.id, 'b');
      expect(plan.canApply, isFalse);
    });

    test('rien à décaler', () {
      expect(planShift(const [], 30).canApply, isFalse);
    });
  });

  group('aujourd\'hui', () {
    test('exclut les autres jours, les missed et les supprimées', () {
      final tasks = [
        makeTask(id: 'ok'),
        makeTask(id: 'hier', date: monday),
        makeTask(id: 'passee', status: TaskStatus.missed),
        makeTask(id: 'sup').copyWith(deletedAt: fixedInstant),
      ];
      expect(tasksForToday(tasks, tuesday).map((t) => t.id), ['ok']);
    });

    test('résumé de la journée', () {
      final tasks = [
        makeTask(id: 'a', start: '08:00', end: '10:00'),
        makeTask(id: 'b', start: '14:00', end: '16:00'),
        makeTask(id: 'c', start: '17:30', end: '18:30'),
      ];
      expect(
        daySummary(tasks, const LocalTime(7, 0)),
        '3 tâches restantes, prochaine à 8h',
      );
      expect(
        daySummary(tasks, const LocalTime(9, 0)),
        '3 tâches restantes, prochaine à 14h',
      );
      expect(
        daySummary(tasks.take(1).toList(), const LocalTime(9, 0)),
        '1 tâche restante',
      );
      expect(
        daySummary(tasks, const LocalTime(19, 0)),
        'Aucune tâche restante',
      );
    });
  });

  group('prompt modèle', () {
    late final prompt = buildPlanPrompt(
      today: tuesday,
      settings: const AppSettings(),
    );

    test('insère la date du jour et les réglages', () {
      expect(prompt, contains('Nous sommes le mardi 2026-11-10'));
      expect(prompt, contains('fuseau Africa/Porto-Novo'));
      expect(prompt, contains('jusqu\'au 2026-11-16'));
      expect(prompt, contains('Journée de 07:00 à 22:00'));
      expect(prompt, contains('AUJOURD\'HUI (2026-11-10)'));
    });

    test('l\'exemple intégré est importable', () {
      final json = prompt.substring(
        prompt.indexOf('{'),
        prompt.lastIndexOf('}') + 1,
      );
      expect(jsonDecode(json), isA<Map<String, dynamic>>());
      final plan = parsePlanJson(json);
      expect(plan.tasks.single.date, tuesday);
      expect(plan.invalidTasks, isEmpty);
      expect(plan.notices, isEmpty);
    });
  });
}
