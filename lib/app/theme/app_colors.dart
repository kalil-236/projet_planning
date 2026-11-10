import 'package:flutter/material.dart';

import '../../domain/category.dart';

/// Tokens de couleur de la direction « Calendrier clair » (section 8.1).
///
/// C'est le seul fichier de l'application autorisé à contenir des valeurs de
/// couleur ; `test/conventions_test.dart` le vérifie.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.foreground,
    required this.mutedForeground,
    required this.muted,
    required this.border,
    required this.destructive,
    required this.ring,
  });

  static const light = AppColors(
    primary: Color(0xFF2563EB),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF3B82F6),
    accent: Color(0xFF059669),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    foreground: Color(0xFF0F172A),
    mutedForeground: Color(0xFF64748B),
    muted: Color(0xFFF1F5FD),
    border: Color(0xFFE4ECFC),
    destructive: Color(0xFFDC2626),
    ring: Color(0xFF2563EB),
  );

  static const dark = AppColors(
    primary: Color(0xFF3B82F6),
    onPrimary: Color(0xFF0B1120),
    secondary: Color(0xFF60A5FA),
    accent: Color(0xFF10B981),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    foreground: Color(0xFFF1F5F9),
    mutedForeground: Color(0xFF94A3B8),
    muted: Color(0xFF1E293B),
    border: Color(0xFF334155),
    destructive: Color(0xFFF87171),
    ring: Color(0xFF60A5FA),
  );

  static const _categoryCours = Color(0xFF2563EB);
  static const _categoryEtude = Color(0xFF7C3AED);
  static const _categoryActivite = Color(0xFF059669);
  static const _categoryRepos = Color(0xFFD97706);
  static const _categoryAutre = Color(0xFF64748B);

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color foreground;
  final Color mutedForeground;
  final Color muted;
  final Color border;
  final Color destructive;
  final Color ring;

  /// Couleur d'un texte ou d'une icône d'accent posé sur `surface`.
  ///
  /// `primary` n'atteint pas 4,5:1 sur `surface` en mode sombre, contrairement
  /// à `ring`, qui vaut `primary` en mode clair.
  Color get primaryOnSurface => ring;

  /// Couleur d'une catégorie (6.3), réservée au décor des blocs : le texte et
  /// les icônes posés dessus utilisent `foreground`.
  Color categoryColor(TaskCategory category) => switch (category) {
    TaskCategory.cours => _categoryCours,
    TaskCategory.etude => _categoryEtude,
    TaskCategory.activite => _categoryActivite,
    TaskCategory.repos => _categoryRepos,
    TaskCategory.autre => _categoryAutre,
  };

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? foreground,
    Color? mutedForeground,
    Color? muted,
    Color? border,
    Color? destructive,
    Color? ring,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      foreground: foreground ?? this.foreground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      destructive: destructive ?? this.destructive,
      ring: ring ?? this.ring,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      secondary: mix(secondary, other.secondary),
      accent: mix(accent, other.accent),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      foreground: mix(foreground, other.foreground),
      mutedForeground: mix(mutedForeground, other.mutedForeground),
      muted: mix(muted, other.muted),
      border: mix(border, other.border),
      destructive: mix(destructive, other.destructive),
      ring: mix(ring, other.ring),
    );
  }
}

extension AppColorsOfContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
