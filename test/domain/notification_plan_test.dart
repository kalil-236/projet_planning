import 'package:assistant_planning/core/time_zones.dart';
import 'package:assistant_planning/domain/app_settings.dart';
import 'package:assistant_planning/domain/device_preferences.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/notification_messages.dart';
import 'package:assistant_planning/domain/notification_plan.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

const _noSummary = AppSettings(morningSummaryEnabled: false);

List<PlannedNotification> _plan(
  List<Task> tasks, {
  AppSettings settings = _noSummary,
  FakeClock? clock,
  DevicePreferences device = const DevicePreferences(
    eveningReportEnabled: false,
  ),
}) => planNotifications(
  tasks: tasks,
  settings: settings,
  clock: clock ?? FakeClock.porto(tuesday, 6),
  device: device,
);

Iterable<NotificationKind> _kinds(List<PlannedNotification> plan) =>
    plan.map((n) => n.kind);

DateTime _porto(LocalDate date, int hour, [int minute = 0]) =>
    DateTime.utc(date.year, date.month, date.day, hour - 1, minute);

void main() {
  setUpAll(initAppFormats);

  group('rappels de tâche', () {
    test('le rappel de début porte le texte et l\'horaire de la tâche', () {
      final plan = _plan([makeTask(title: 'Cours')]);

      final start = plan.singleWhere((n) => n.kind == NotificationKind.start);
      expect(start.title, "C'est l'heure : Cours");
      expect(start.body, contains('Cours'));
      expect(start.body, endsWith('\n08:00 – 10:00'));
      expect(start.instant, _porto(tuesday, 8));
    });

    test("le rappel de début suit la tâche jusqu'à sa fin", () {
      final plan = _plan([makeTask(title: 'Cours', end: '10:30')]);

      final start = plan.singleWhere((n) => n.kind == NotificationKind.start);
      expect(start.endsAt, _porto(tuesday, 10, 30));
      expect(start.endLabel, '10h30');
      final pre = plan.singleWhere(
        (n) => n.kind == NotificationKind.preReminder,
      );
      expect(pre.endsAt, isNull);
    });

    test('le pré-rappel utilise le délai par défaut des réglages', () {
      final plan = _plan([makeTask(title: 'Cours')]);

      final pre = plan.singleWhere(
        (n) => n.kind == NotificationKind.preReminder,
      );
      expect(pre.instant, _porto(tuesday, 7, 50));
      expect(pre.title, 'Dans 10 min : Cours');
      expect(pre.body, contains('Cours'));
      expect(pre.body, endsWith('\n08:00 – 10:00'));
    });

    test('le délai de la tâche prime sur celui des réglages', () {
      final task = makeTask(title: 'Cours').copyWith(reminderBeforeMin: 90);
      final pre = _plan([task])
          .singleWhere((n) => n.kind == NotificationKind.preReminder);

      expect(pre.title, 'Dans 1 h 30 : Cours');
    });

    test('un délai de 0 supprime le pré-rappel, pas le rappel de début', () {
      final task = makeTask().copyWith(reminderBeforeMin: 0);

      expect(_kinds(_plan([task])), [NotificationKind.start]);
    });

    test('décaler une tâche déplace ses rappels, avec le même identifiant', () {
      final task = makeTask();
      final moved = task.copyWith(start: const LocalTime(9, 0));

      final before = _plan([task]);
      final after = _plan([moved]);

      expect(after.map((n) => n.id).toSet(), before.map((n) => n.id).toSet());
      expect(
        after.singleWhere((n) => n.kind == NotificationKind.start).instant,
        _porto(tuesday, 9),
      );
    });
  });

  group('exclusions', () {
    for (final status in [
      TaskStatus.cancelled,
      TaskStatus.done,
      TaskStatus.missed,
    ]) {
      test('une tâche ${status.name} n\'a aucun rappel', () {
        expect(_plan([makeTask(status: status)]), isEmpty);
      });
    }

    test('une tâche supprimée n\'a aucun rappel', () {
      final task = makeTask().copyWith(deletedAt: fixedInstant);

      expect(_plan([task]), isEmpty);
    });

    test('une tâche déjà commencée n\'est pas programmée', () {
      final plan = _plan([makeTask()], clock: FakeClock.porto(tuesday, 9));

      expect(plan, isEmpty);
    });

    test('un pré-rappel passé disparaît, le rappel de début reste', () {
      final plan = _plan([makeTask()], clock: FakeClock.porto(tuesday, 7, 55));

      expect(_kinds(plan), [NotificationKind.start]);
    });

    test('l\'instant exact de maintenant est considéré comme passé', () {
      final plan = _plan([makeTask()], clock: FakeClock.porto(tuesday, 8));

      expect(plan, isEmpty);
    });
  });

  group('fenêtre de 7 jours', () {
    test('couvre aujourd\'hui et les 6 jours suivants', () {
      final tasks = [
        makeTask(id: 'hier', date: monday),
        makeTask(id: 'j0', date: tuesday),
        makeTask(id: 'j6', date: tuesday.addDays(6)),
        makeTask(id: 'j7', date: tuesday.addDays(7)),
      ];

      final starts = _plan(tasks)
          .where((n) => n.kind == NotificationKind.start)
          .map((n) => n.instant);

      expect(starts, [_porto(tuesday, 8), _porto(tuesday.addDays(6), 8)]);
    });

    test('suit la date locale du fuseau configuré', () {
      // 23:30 UTC le mardi : déjà mercredi à Porto-Novo (UTC+1).
      final clock = FakeClock(DateTime.utc(2026, 11, 10, 23, 30));

      final plan = _plan([
        makeTask(id: 'mardi', date: tuesday),
        makeTask(id: 'mardi+7', date: tuesday.addDays(7)),
      ], clock: clock);

      expect(plan.first.instant, _porto(tuesday.addDays(7), 7, 50));
    });
  });

  group('plafond', () {
    test('garde les 200 notifications les plus proches', () {
      final tasks = [
        for (var i = 0; i < 150; i++)
          makeTask(
            id: 'x$i',
            date: tuesday.addDays(i % 7),
            start: '${(8 + i % 12).toString().padLeft(2, '0')}:00',
            end: '21:00',
          ),
      ];
      final clock = FakeClock.porto(tuesday, 1);

      final plan = _plan(tasks, clock: clock);

      expect(plan, hasLength(maxPlannedNotifications));
      final instants = plan.map((n) => n.instant).toList();
      expect(instants, orderedEquals([...instants]..sort()));
      expect(plan.map((n) => n.id).toSet(), hasLength(plan.length));
    });
  });

  group('identifiants', () {
    test('sont stables d\'un calcul à l\'autre et jamais celui du test', () {
      final tasks = [makeTask(id: 'a'), makeTask(id: 'b', start: '11:00')];

      final first = _plan(tasks).map((n) => n.id).toList();
      final second = _plan(tasks).map((n) => n.id).toList();

      expect(second, first);
      expect(first, isNot(contains(testNotificationId)));
      expect(first.every((id) => id > 0 && id <= 0x7fffffff), isTrue);
    });
  });

  group('résumé du matin', () {
    const settings = AppSettings();

    List<PlannedNotification> summaries(
      List<Task> tasks, {
      AppSettings settings = settings,
      FakeClock? clock,
    }) => _plan(
      tasks,
      settings: settings,
      clock: clock,
    ).where((n) => n.kind == NotificationKind.morningSummary).toList();

    test('une notification par jour de la fenêtre, à l\'heure réglée', () {
      final plan = summaries(const [], clock: FakeClock.porto(tuesday, 6));

      expect(plan, hasLength(7));
      expect(plan.first.instant, _porto(tuesday, 7));
      expect(plan.last.instant, _porto(tuesday.addDays(6), 7));
    });

    test('jour sans tâche', () {
      expect(
        morningBriefingEmptyMessages,
        contains(summaries(const []).first.body),
      );
    });

    test('liste les tâches du jour dans l\'ordre chronologique', () {
      final plan = summaries([
        makeTask(id: 's', title: 'Sport', start: '17:00', end: '18:00'),
        makeTask(id: 'c', title: 'Cours', start: '08:30', end: '10:00'),
        makeTask(id: 'm', title: 'Marché', date: wednesday),
      ]);

      expect(plan.first.body, contains('2 points'));
      expect(plan.first.body, contains('Cours à 8h30, Sport à 17h.'));
      expect(plan.first.body, isNot(contains('Marché')));
    });

    test('le briefing se termine par une phrase de conclusion', () {
      final body = morningSummaryBody([makeTask(title: 'Cours')], key: 'k');

      expect(body, contains('un point'));
      expect(morningBriefingClosings.any(body.endsWith), isTrue);
    });

    test('exclut les tâches annulées, faites et passées', () {
      final plan = summaries([
        makeTask(id: 'a', title: 'Annulée', status: TaskStatus.cancelled),
        makeTask(id: 'f', title: 'Faite', status: TaskStatus.done),
        makeTask(id: 'p', title: 'Passée', status: TaskStatus.missed),
      ]);

      expect(morningBriefingEmptyMessages, contains(plan.first.body));
    });

    test('le résumé déjà passé n\'est pas programmé', () {
      final plan = summaries(const [], clock: FakeClock.porto(tuesday, 7, 1));

      expect(plan, hasLength(6));
      expect(plan.first.instant, _porto(wednesday, 7));
    });

    test('désactivé : aucun résumé', () {
      expect(
        summaries(
          const [],
          settings: const AppSettings(morningSummaryEnabled: false),
        ),
        isEmpty,
      );
    });

    test('un texte trop long est coupé entre deux tâches', () {
      final tasks = [
        for (var i = 0; i < 40; i++)
          makeTask(id: '$i', title: 'Tâche numéro $i', start: '09:00'),
      ];

      final body = morningSummaryBody(tasks);

      expect(body.length, lessThanOrEqualTo(300));
      expect(body, endsWith('à 9h…'));
    });

    test('un titre unique trop long est coupé proprement', () {
      final body = morningSummaryBody([makeTask(title: 'A' * 500)]);

      expect(body.length, lessThanOrEqualTo(300));
      expect(body, endsWith('A…'));
    });
  });

  group('fuseau', () {
    test('Africa/Porto-Novo : 08:00 locale vaut 07:00 UTC', () {
      expect(
        toInstant(tuesday, const LocalTime(8, 0), 'Africa/Porto-Novo'),
        DateTime.utc(2026, 11, 10, 7),
      );
    });

    test('changer de fuseau garde la date locale et déplace l\'instant', () {
      final clock = FakeClock.porto(tuesday, 1);
      final tokyo = _plan(
        [makeTask(date: wednesday)],
        settings: _noSummary.copyWith(timezone: 'Asia/Tokyo'),
        clock: clock,
      );

      expect(
        tokyo.singleWhere((n) => n.kind == NotificationKind.start).instant,
        DateTime.utc(2026, 11, 10, 23),
      );
    });
  });

  test('la notification de test part une minute plus tard', () {
    final now = DateTime.utc(2026, 11, 10, 9);

    final test_ = testNotification(now);

    expect(test_.id, testNotificationId);
    expect(test_.instant, now.add(const Duration(minutes: 1)));
  });
}
