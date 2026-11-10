import 'package:assistant_planning/domain/category.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/quick_task.dart';
import 'package:assistant_planning/domain/task_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

LocalTime t(String value) => LocalTime.parse(value);

TaskDraft parse(String input, {String now = '09:00'}) {
  final result = parseQuickTask(input, today: tuesday, now: t(now));
  expect(result.error, isNull, reason: input);
  return result.draft!;
}

String errorOf(String input) =>
    parseQuickTask(input, today: tuesday, now: t('09:00')).error!;

void main() {
  group('ajout express', () {
    test('exemple des propositions : sport demain 18h 1h', () {
      expect(
        parse('sport demain 18h 1h'),
        TaskDraft(
          title: 'Sport',
          date: wednesday,
          start: t('18:00'),
          end: t('19:00'),
          category: TaskCategory.activite,
        ),
      );
    });

    test('plage horaire « de … à … »', () {
      final draft = parse('Révisions de maths de 14h à 16h30');
      expect(draft.title, 'Révisions de maths');
      expect(draft.start, t('14:00'));
      expect(draft.end, t('16:30'));
      expect(draft.category, TaskCategory.etude);
      expect(draft.date, tuesday);
    });

    test('plage avec tiret et heures au format 14:00', () {
      final draft = parse('TD physique 14:00-15:30');
      expect(draft.title, 'TD physique');
      expect((draft.start, draft.end), (t('14:00'), t('15:30')));
      expect(draft.category, TaskCategory.cours);
    });

    test('durée en minutes et « pendant »', () {
      expect(parse('lecture à 20h 45 min').end, t('20:45'));
      expect(parse('pause pendant 30 min à 15h').end, t('15:30'));
      expect(parse('marche pendant 1h30 à 7h', now: '06:00').end, t('08:30'));
    });

    test('sans durée : une heure', () {
      expect(parse('appeler maman à 19h').end, t('20:00'));
    });

    test('sans date, heure passée : demain', () {
      final draft = parse('courses 8h');
      expect(draft.date, wednesday);
      expect(parse('courses 10h').date, tuesday);
    });

    test('sans heure : heure pleine suivante', () {
      final draft = parse('ranger le bureau', now: '09:20');
      expect(draft.title, 'Ranger le bureau');
      expect((draft.start, draft.end), (t('10:00'), t('11:00')));
    });

    test('jours de la semaine, après-demain, prochain', () {
      expect(parse('foot jeudi 17h').date, const LocalDate(2026, 11, 12));
      expect(parse('foot mardi 17h').date, tuesday);
      expect(
        parse('foot mardi prochain 17h').date,
        const LocalDate(2026, 11, 17),
      );
      expect(
        parse('foot après-demain 17h').date,
        const LocalDate(2026, 11, 12),
      );
      expect(parse('foot lundi 17h').date, const LocalDate(2026, 11, 16));
    });

    test('dates : le 12, 12/11, 3 décembre, mois suivant', () {
      expect(parse('dentiste le 12 à 15h').date, const LocalDate(2026, 11, 12));
      expect(parse('dentiste 20/11 à 15h').date, const LocalDate(2026, 11, 20));
      expect(
        parse('dentiste le 3 décembre à 15h').date,
        const LocalDate(2026, 12, 3),
      );
      expect(parse('dentiste le 2 à 15h').date, const LocalDate(2026, 12, 2));
      expect(parse('partiel 15/01 9h').date, const LocalDate(2027, 1, 15));
      expect(parse('dentiste le 1er à 15h').title, 'Dentiste');
    });

    test('midi et heures pleines « 18 heures »', () {
      expect(parse('déjeuner midi').start, t('12:00'));
      expect(parse('déjeuner midi').category, TaskCategory.repos);
      expect(parse('cours 18 heures').start, t('18:00'));
    });

    test('catégorie inconnue : autre', () {
      expect(parse('banque 11h').category, TaskCategory.autre);
    });

    test('erreurs lisibles', () {
      expect(errorOf('demain 18h'), contains('titre'));
      expect(errorOf('soirée de 23h à 1h'), contains('fin'));
      expect(errorOf('soirée 23h30 2h'), contains('minuit'));
      expect(errorOf('rdv 25h'), isNotEmpty);
    });
  });
}
