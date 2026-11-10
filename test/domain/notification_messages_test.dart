import 'package:assistant_planning/domain/notification_messages.dart';
import 'package:flutter_test/flutter_test.dart';

final _emoji = RegExp(
  r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{FE0F}]',
  unicode: true,
);

void main() {
  const title = 'Cours de maths';

  final all = [
    ...startReminderMessages(title),
    ...preReminderMessages(title, '10 min'),
    ...morningSummaryTitles,
    ...morningBriefingEmptyMessages,
    ...morningBriefingClosings,
    ...morningBriefingOpenings(1),
    ...morningBriefingOpenings(3),
  ];

  test('tout message de tâche nomme la tâche', () {
    for (final message in [
      ...startReminderMessages(title),
      ...preReminderMessages(title, '10 min'),
    ]) {
      expect(message, endsWith(title));
    }
  });

  test('aucun message ne contient d\'emoji (8.5)', () {
    for (final message in all) {
      expect(_emoji.hasMatch(message), isFalse, reason: message);
    }
  });

  test('une même clé donne toujours le même message', () {
    expect(
      startReminderMessage(title, 'abc|start'),
      startReminderMessage(title, 'abc|start'),
    );
    expect(
      preReminderMessage(title, '10 min', 'abc|pre'),
      preReminderMessage(title, '10 min', 'abc|pre'),
    );
    expect(morningSummaryTitle('summary|x'), morningSummaryTitle('summary|x'));
  });

  test('les clés de tâches différentes couvrent tous les messages', () {
    final seen = {
      for (var i = 0; i < 500; i++)
        startReminderMessage(title, 'tache-$i|start'),
    };
    expect(seen, startReminderMessages(title).toSet());
  });

  test('stableHash garde sa valeur d\'une version à l\'autre', () {
    expect(stableHash(''), 0x011c9dc5);
    expect(stableHash('a'), stableHash('a'));
    expect(stableHash('a'), isNot(stableHash('b')));
  });
}
