import 'dart:math' as math;

import 'package:assistant_planning/app/theme/app_colors.dart';
import 'package:assistant_planning/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void expectReadable(String name, Color fg, Color bg, {double min = 4.5}) {
  expect(contrast(fg, bg), greaterThanOrEqualTo(min), reason: name);
}

void expectCommonPairs(AppColors c) {
  expectReadable('onPrimary/primary', c.onPrimary, c.primary);
  expectReadable('foreground/background', c.foreground, c.background);
  expectReadable('foreground/surface', c.foreground, c.surface);
  expectReadable('foreground/muted', c.foreground, c.muted);
  expectReadable('muted/background', c.mutedForeground, c.background);
  expectReadable('muted/surface', c.mutedForeground, c.surface);
  expectReadable('primaryOnSurface', c.primaryOnSurface, c.surface);
  expectReadable('destructive/surface', c.destructive, c.surface);
}

void main() {
  test('contrastes du mode sombre ≥ 4,5:1', () {
    const c = AppColors.dark;
    expectCommonPairs(c);
    expectReadable('muted/muted', c.mutedForeground, c.muted);
    expectReadable('accent/surface', c.accent, c.surface);
  });

  test('contrastes du mode clair', () {
    const c = AppColors.light;
    expectCommonPairs(c);
    // Voir docs/DECISIONS.md : accent réservé aux icônes en mode clair.
    expectReadable('accent/surface', c.accent, c.surface, min: 3);
  });

  for (final (name, theme, colors) in [
    ('clair', AppTheme.light, AppColors.light),
    ('sombre', AppTheme.dark, AppColors.dark),
  ]) {
    test('thème $name : tokens et typographie', () {
      expect(theme.extension<AppColors>(), same(colors));
      expect(theme.colorScheme.primary, colors.primary);
      expect(theme.colorScheme.error, colors.destructive);
      expect(theme.scaffoldBackgroundColor, colors.background);

      final body = theme.textTheme.bodyMedium!;
      expect(body.fontFamily, AppTheme.fontFamily);
      expect(body.fontSize, greaterThanOrEqualTo(16));
    });
  }
}
