import 'package:assistant_planning/domain/day_gaps.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:assistant_planning/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

LocalTime t(String value) => LocalTime.parse(value);

void main() {
  group('créneaux libres', () {
    test('trous entre les tâches, dans les bornes de la journée', () {
      final slots = freeSlots(
        tasks: [
          makeTask(id: 'a', start: '08:00', end: '10:00'),
          makeTask(id: 'b', start: '14:00', end: '15:00'),
        ],
        dayStart: t('07:00'),
        dayEnd: t('18:00'),
      );
      expect(slots, [
        FreeSlot(t('07:00'), t('08:00')),
        FreeSlot(t('10:00'), t('14:00')),
        FreeSlot(t('15:00'), t('18:00')),
      ]);
    });

    test('ignore les trous de moins de 30 minutes', () {
      final slots = freeSlots(
        tasks: [
          makeTask(id: 'a', start: '08:00', end: '10:00'),
          makeTask(id: 'b', start: '10:20', end: '12:00'),
        ],
        dayStart: t('08:00'),
        dayEnd: t('12:00'),
      );
      expect(slots, isEmpty);
    });

    test('commence à l\'heure actuelle arrondie aux 5 minutes', () {
      final slots = freeSlots(
        tasks: [makeTask(start: '12:00', end: '13:00')],
        dayStart: t('07:00'),
        dayEnd: t('14:00'),
        from: t('09:12'),
      );
      expect(slots, [
        FreeSlot(t('09:15'), t('12:00')),
        FreeSlot(t('13:00'), t('14:00')),
      ]);
    });

    test('une tâche annulée libère sa place, une tâche faite l\'occupe', () {
      final slots = freeSlots(
        tasks: [
          makeTask(
            id: 'a',
            start: '08:00',
            end: '09:00',
            status: TaskStatus.cancelled,
          ),
          makeTask(
            id: 'b',
            start: '09:00',
            end: '10:00',
            status: TaskStatus.done,
          ),
        ],
        dayStart: t('08:00'),
        dayEnd: t('10:00'),
      );
      expect(slots, [FreeSlot(t('08:00'), t('09:00'))]);
    });

    test('tâches imbriquées et tâche qui dépasse la fin de journée', () {
      final slots = freeSlots(
        tasks: [
          makeTask(id: 'a', start: '08:00', end: '12:00'),
          makeTask(id: 'b', start: '09:00', end: '10:00'),
          makeTask(id: 'c', start: '21:00', end: '23:00'),
        ],
        dayStart: t('08:00'),
        dayEnd: t('22:00'),
      );
      expect(slots, [FreeSlot(t('12:00'), t('21:00'))]);
    });
  });

  group('chevauchements', () {
    test('signale les deux tâches qui se recouvrent', () {
      final ids = overlappingTaskIds([
        makeTask(id: 'a', start: '08:00', end: '10:00'),
        makeTask(id: 'b', start: '09:30', end: '11:00'),
        makeTask(id: 'c', start: '11:00', end: '12:00'),
      ]);
      expect(ids, {'a', 'b'});
    });

    test('tâche longue qui en couvre plusieurs', () {
      final ids = overlappingTaskIds([
        makeTask(id: 'a', start: '08:00', end: '18:00'),
        makeTask(id: 'b', start: '09:00', end: '10:00'),
        makeTask(id: 'c', start: '15:00', end: '16:00'),
      ]);
      expect(ids, {'a', 'b', 'c'});
    });

    test('ni tâche faite ou annulée, ni jours différents', () {
      final ids = overlappingTaskIds([
        makeTask(id: 'a', start: '08:00', end: '10:00'),
        makeTask(
          id: 'b',
          start: '09:00',
          end: '10:00',
          status: TaskStatus.cancelled,
        ),
        makeTask(id: 'c', start: '09:00', end: '10:00', date: monday),
      ]);
      expect(ids, isEmpty);
    });
  });
}
