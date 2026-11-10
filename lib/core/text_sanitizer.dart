final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2B55}\u{FE0F}\u{200D}]',
  unicode: true,
);

/// Retire les emojis et les espaces superflus d'un texte saisi ou importé.
String sanitizeText(String value) =>
    value.replaceAll(_emoji, '').replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
