import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/spoken.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  test('heures en toutes lettres', () {
    expect(spokenHour(const LocalTime(8, 0)), '8 heures');
    expect(spokenHour(const LocalTime(14, 30)), '14 heures 30');
    expect(spokenHour(const LocalTime(12, 0)), 'midi');
    expect(spokenHour(const LocalTime(1, 0)), '1 heure');
  });

  test('tâches restantes, en cours puis à venir', () {
    final text = spokenBriefing(
      todayTasks: [
        makeTask(id: 'a', title: 'Cours', start: '08:00', end: '10:00'),
        makeTask(id: 'b', title: 'Sport', start: '17:30', end: '18:30'),
        makeTask(id: 'c', title: 'Lecture', start: '20:00', end: '21:00'),
        makeTask(id: 'd', title: 'Finie', start: '06:00', end: '07:00'),
      ],
      now: const LocalTime(9, 0),
    );
    expect(text, startsWith('Bonjour monsieur'));
    expect(text, contains('3 points'));
    expect(text, contains("Cours, en cours jusqu'à 10 heures"));
    expect(
      text,
      contains('Sport à 17 heures 30, et enfin Lecture à 20 heures'),
    );
    expect(text, isNot(contains('Finie')));
  });

  test('tout est fait, ou rien de prévu', () {
    expect(
      spokenBriefing(
        todayTasks: [makeTask(status: TaskStatus.done)],
        now: const LocalTime(9, 0),
      ),
      contains('Tout est accompli'),
    );
    expect(
      spokenBriefing(todayTasks: const [], now: const LocalTime(9, 0)),
      contains('monsieur'),
    );
  });
}
