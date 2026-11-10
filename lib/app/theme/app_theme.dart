import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';
  static const _bodyFontSize = 16.0;
  static const _indicatorOpacity = 0.14;

  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.secondary,
      onSecondary: colors.onPrimary,
      error: colors.destructive,
      onError: colors.onPrimary,
      surface: colors.surface,
      onSurface: colors.foreground,
      onSurfaceVariant: colors.mutedForeground,
      surfaceTint: colors.surface,
      surfaceContainerLowest: colors.surface,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.muted,
      surfaceContainerHighest: colors.muted,
      outline: colors.border,
      outlineVariant: colors.border,
    );

    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    final text = base.textTheme;
    final indicator = colors.primaryOnSurface.withValues(
      alpha: _indicatorOpacity,
    );
    final selectedIcon = IconThemeData(color: colors.primaryOnSurface);
    final unselectedIcon = IconThemeData(color: colors.mutedForeground);

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      focusColor: colors.ring.withValues(alpha: _indicatorOpacity),
      textTheme: text.copyWith(
        bodyLarge: text.bodyLarge?.copyWith(fontSize: _bodyFontSize),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: _bodyFontSize),
        bodySmall: text.bodySmall?.copyWith(fontSize: _bodyFontSize),
      ),
      iconTheme: IconThemeData(color: colors.foreground, size: 24),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        indicatorColor: indicator,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? selectedIcon
              : unselectedIcon,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? text.labelMedium?.copyWith(
                  color: colors.primaryOnSurface,
                  fontWeight: FontWeight.w600,
                )
              : text.labelMedium?.copyWith(color: colors.mutedForeground),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        indicatorColor: indicator,
        selectedIconTheme: selectedIcon,
        unselectedIconTheme: unselectedIcon,
        selectedLabelTextStyle: text.labelLarge?.copyWith(
          color: colors.primaryOnSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.labelLarge?.copyWith(
          color: colors.mutedForeground,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: colors.surface),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.primaryOnSurface),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primaryOnSurface,
          side: BorderSide(color: colors.mutedForeground),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colors.mutedForeground),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.mutedForeground),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.ring, width: 2),
        ),
      ),
      extensions: [colors],
    );
  }
}
