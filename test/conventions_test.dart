import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Règles transverses de la spécification, vérifiées sur le code source.
final _hardCodedColor = RegExp(
  r'\bColor\(0x|\bColor\.from(ARGB|RGBO)\(|\bColors\.\w+',
);
final _nonLucideIcon = RegExp(r'\b(Cupertino)?Icons\.\w+');
final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2B55}\u{FE0F}]',
  unicode: true,
);

const _colorTokensFile = 'lib/app/theme/app_colors.dart';

Iterable<File> _dartFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

String _normalized(String path) => path.replaceAll(r'\', '/');

List<String> _violations(RegExp rule, {Set<String> except = const {}}) => [
  for (final file in _dartFiles())
    if (!except.contains(_normalized(file.path)))
      for (final (index, line) in file.readAsLinesSync().indexed)
        if (rule.hasMatch(line)) '${file.path}:${index + 1}: $line',
];

void main() {
  test('les règles détectent bien les cas interdits', () {
    expect(_hardCodedColor.hasMatch('Color(0xFF000000)'), isTrue);
    expect(_hardCodedColor.hasMatch('Colors.red'), isTrue);
    expect(_hardCodedColor.hasMatch('context.colors.primary'), isFalse);
    expect(_nonLucideIcon.hasMatch('Icons.add'), isTrue);
    expect(_nonLucideIcon.hasMatch('CupertinoIcons.add'), isTrue);
    expect(_nonLucideIcon.hasMatch('LucideIcons.plus'), isFalse);
    expect(_emoji.hasMatch('Sport \u{1F3C3}'), isTrue);
    expect(_emoji.hasMatch("Aujourd'hui à 8h"), isFalse);
  });

  test('aucune couleur codée en dur hors des tokens', () {
    expect(_violations(_hardCodedColor, except: {_colorTokensFile}), isEmpty);
  });

  test('icônes Lucide uniquement', () {
    expect(_violations(_nonLucideIcon), isEmpty);
  });

  test('aucun emoji', () {
    expect(_violations(_emoji), isEmpty);
  });
}
