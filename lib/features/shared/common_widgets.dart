import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_colors.dart';
import '../../domain/local_time.dart';

/// Squelette affiché pendant le chargement, jamais d'écran blanc (8.5).
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final color = context.colors.muted;
    return Semantics(
      label: 'Chargement',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                height: 72,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: color, borderRadius: _radius),
              ),
          ],
        ),
      ),
    );
  }
}

/// Illustrations unDraw (8.4), réservées à ces trois écrans.
enum AppIllustration {
  nothingToday('assets/illustrations/rien_aujourdhui.svg'),
  noPlan('assets/illustrations/aucun_planning.svg'),
  login('assets/illustrations/connexion.svg');

  const AppIllustration(this.asset);

  final String asset;
}

/// Illustration décorative, recolorée avec les tokens du thème courant pour
/// rester lisible en mode sombre.
class Illustration extends StatelessWidget {
  const Illustration(this.illustration, {this.maxHeight = 180, super.key});

  final AppIllustration illustration;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ExcludeSemantics(
      child: SvgPicture.asset(
        illustration.asset,
        height: math.min(maxHeight, width * 0.45),
        colorMapper: _ThemeColorMapper(context.colors),
      ),
    );
  }
}

/// Classe les couleurs d'origine sans les nommer : bleu vif vers `primary`,
/// gris vers les tokens neutres, teintes chaudes (peau) inchangées.
class _ThemeColorMapper extends ColorMapper {
  const _ThemeColorMapper(this.colors);

  final AppColors colors;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final hsv = HSVColor.fromColor(color);
    final warm = hsv.hue < 40 || hsv.hue > 330;
    if (warm && hsv.saturation > 0.15) return color;
    if (hsv.saturation > 0.5) return colors.primary;
    final luminance = color.computeLuminance();
    if (luminance < 0.1) return colors.foreground;
    if (luminance > 0.97) return colors.surface;
    if (luminance > 0.85) return colors.muted;
    return colors.border;
  }

  @override
  bool operator ==(Object other) =>
      other is _ThemeColorMapper && other.colors == colors;

  @override
  int get hashCode => colors.hashCode;
}

/// État vide : illustration si l'écran en prévoit une (8.4), sinon icône.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon,
    this.illustration,
    this.action,
    super.key,
  });

  final IconData? icon;
  final AppIllustration? illustration;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final illustration = this.illustration;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              Illustration(illustration)
            else
              Icon(icon, size: 64, color: colors.primaryOnSurface),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Sélecteur d'heure, toujours sur 24 h.
Future<LocalTime?> pickLocalTime(
  BuildContext context,
  LocalTime initial,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return picked == null ? null : LocalTime(picked.hour, picked.minute);
}

void showMessage(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
