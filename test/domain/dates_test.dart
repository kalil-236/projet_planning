import 'package:assistant_planning/core/clock.dart';
import 'package:assistant_planning/core/french_format.dart';
import 'package:assistant_planning/core/text_sanitizer.dart';
import 'package:assistant_planning/core/time_zones.dart';
import 'package:assistant_planning/domain/local_date.dart';
import 'package:assistant_planning/domain/local_time.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  setUpAll(() async {
    initTimeZones();
    await initFrenchFormats();
  });

  group('LocalDate', () {
    test('refuse les dates inexistantes et les formats approximatifs', () {
      expect(LocalDate.tryParse('2026-02-30'), isNull);
      expect(LocalDate.tryParse('2026-13-01'), isNull);
      expect(LocalDate.tryParse('10/11/2026'), isNull);
      expect(LocalDate.tryParse('2026-1-1'), isNull);
      expect(LocalDate.tryParse('2028-02-29'), const LocalDate(2028, 2, 29));
    });

    test('dérive le jour de la semaine de la date', () {
      expect(tuesday.weekday, DateTime.tuesday);
      expect(tuesday.monday, monday);
      expect(const LocalDate(2026, 11, 15).monday, monday);
      expect(monday.monday, monday);
    });

    test('additionne les jours en traversant mois et années', () {
      expect(
        const LocalDate(2026, 12, 31).addDays(1),
        const LocalDate(2027, 1, 1),
      );
      expect(
        const LocalDate(2026, 3, 1).addDays(-1),
        const LocalDate(2026, 2, 28),
      );
    });
  });

  group('LocalTime', () {
    test('format HH:mm strict', () {
      expect(LocalTime.tryParse('24:00'), isNull);
      expect(LocalTime.tryParse('8:00'), isNull);
      expect(LocalTime.tryParse('08:60'), isNull);
      expect(LocalTime.tryParse('23:59'), const LocalTime(23, 59));
    });

    test('plusMinutes refuse de sortir de la journée', () {
      expect(const LocalTime(23, 30).plusMinutes(30), isNull);
      expect(const LocalTime(0, 10).plusMinutes(-11), isNull);
      expect(const LocalTime(23, 0).plusMinutes(59), const LocalTime(23, 59));
    });
  });

  group('fuseau', () {
    test('« aujourd\'hui » suit la date locale, pas la date UTC', () {
      // 23h30 UTC le lundi, soit 00h30 le mardi à Porto-Novo.
      final clock = FakeClock(DateTime.utc(2026, 11, 9, 23, 30));
      final now = localNow(clock, 'Africa/Porto-Novo');
      expect(now.date, tuesday);
      expect(now.time, const LocalTime(0, 30));
    });

    test('le fuseau configuré change le jour courant', () {
      final clock = FakeClock(DateTime.utc(2026, 11, 10, 2));
      expect(localNow(clock, 'Africa/Porto-Novo').date, tuesday);
      expect(localNow(clock, 'America/New_York').date, monday);
    });

    test('heure locale vers instant absolu à Porto-Novo', () {
      expect(
        toInstant(tuesday, const LocalTime(8, 0), 'Africa/Porto-Novo'),
        DateTime.utc(2026, 11, 10, 7),
      );
      expect(
        toInstant(tuesday, const LocalTime(0, 30), 'Africa/Porto-Novo'),
        DateTime.utc(2026, 11, 9, 23, 30),
      );
    });

    test('délai jusqu\'à la prochaine minute', () {
      expect(
        untilNextMinute(DateTime.utc(2026, 1, 1, 10, 0, 45, 500)),
        const Duration(milliseconds: 14500),
      );
    });
  });

  group('formats français', () {
    test('date complète et premier du mois', () {
      expect(formatFullDate(tuesday), 'Mardi 10 novembre 2026');
      expect(formatFullDate(const LocalDate(2026, 12, 1)), contains('1er'));
    });

    test('plage de semaine', () {
      expect(formatWeekRange(monday), '9 – 15 novembre 2026');
      expect(
        formatWeekRange(const LocalDate(2026, 11, 30)),
        '30 novembre – 6 décembre 2026',
      );
    });

    test('heures sur 24 h', () {
      expect(formatHour(const LocalTime(8, 0)), '8h');
      expect(formatHour(const LocalTime(14, 5)), '14h05');
    });
  });

  test('sanitizeText retire les emojis', () {
    expect(sanitizeText('Sport \u{1F3C3}  du soir '), 'Sport du soir');
    expect(sanitizeText("Cours d'été à 8h"), "Cours d'été à 8h");
  });
}
