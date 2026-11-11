import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/destinations.dart';
import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/french_format.dart';
import '../../domain/insights.dart';
import '../../domain/local_date.dart';
import '../../domain/notification_messages.dart';
import '../../domain/notification_plan.dart';
import '../../domain/plan_prompt.dart';
import '../../domain/week_stats.dart';
import '../shared/common_widgets.dart';
import '../shared/listen_button.dart';
import '../shared/task_visuals.dart';

/// Jours remontés pour la série de jours réussis.
const _streakDays = 60;

/// Bilan : la semaine en chiffres, et ce que F.R.I.D.A.Y a remarqué sur les
/// semaines passées.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  static const _maxContentWidth = 1100.0;
  static const _twoColumnsWidth = 900.0;

  /// 0 : semaine en cours, -1 : semaine précédente…
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider);
    final settings = ref.watch(currentSettingsProvider);
    final monday = now.date.monday.addDays(7 * _weekOffset);
    final sunday = monday.addDays(6);
    final historyStart = now.date.addDays(
      1 - math.max(_streakDays, insightHistoryDays),
    );
    final range = DateRange(
      monday.isBefore(historyStart) ? monday : historyStart,
      sunday.isAfter(now.date) ? sunday : now.date,
    );
    final tasksAsync = ref.watch(tasksInRangeProvider(range));

    return Scaffold(
      appBar: AppBar(title: Text(AppDestination.report.label)),
      body: tasksAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          icon: LucideIcons.info,
          message: 'Impossible de lire le planning : $error',
        ),
        data: (tasks) {
          final stats = weekStats(
            tasks: tasks,
            monday: monday,
            today: now.date,
            now: now.time,
          );
          final streak = successStreak(
            tasks: tasks,
            today: now.date,
            now: now.time,
            maxDays: _streakDays,
          );
          final insights = computeInsights(
            tasks: tasks,
            today: now.date,
            now: now.time,
            timezone: settings.timezone,
          );
          final listen = ListenButton(
            tooltip: 'Écouter le bilan',
            text: () => spokenWeekReport(stats, insights),
          );
          final header = _WeekHeader(
            trailing: stats.isEmpty ? null : listen,
            monday: monday,
            isCurrent: _weekOffset == 0,
            onPrevious: () => setState(() => _weekOffset--),
            onNext: _weekOffset < 0
                ? () => setState(() => _weekOffset++)
                : null,
            onCurrent: () => setState(() => _weekOffset = 0),
          );
          final insightsCard = _InsightsCard(insights: insights);

          if (stats.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                header,
                const SizedBox(height: 24),
                const EmptyState(
                  icon: LucideIcons.chartColumn,
                  message: 'Aucune tâche cette semaine',
                ),
                const SizedBox(height: 24),
                insightsCard,
              ],
            );
          }

          final summary = [
            _HeroCard(stats: stats),
            const SizedBox(height: 12),
            _KpiTiles(stats: stats, streak: streak),
            const SizedBox(height: 12),
            _DailyChart(stats: stats, today: now.date),
          ];
          final details = [
            _CategoryCard(stats: stats),
            const SizedBox(height: 12),
            insightsCard,
          ];

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < _twoColumnsWidth) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        header,
                        const SizedBox(height: 12),
                        ...summary,
                        const SizedBox(height: 12),
                        ...details,
                      ],
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      header,
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(children: summary)),
                          const SizedBox(width: 16),
                          Expanded(child: Column(children: details)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.monday,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    this.trailing,
  });

  final Widget? trailing;
  final LocalDate monday;
  final bool isCurrent;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Semaine précédente',
          onPressed: onPrevious,
          icon: const Icon(LucideIcons.chevronLeft),
        ),
        Expanded(
          child: Text(
            formatWeekRange(monday),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Semaine suivante',
          onPressed: onNext,
          icon: const Icon(LucideIcons.chevronRight),
        ),
        if (!isCurrent)
          TextButton(onPressed: onCurrent, child: const Text('Cette semaine')),
        ?trailing,
      ],
    );
  }
}

/// Taux de la semaine dans un anneau, et l'appréciation de F.R.I.D.A.Y.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final WeekStats stats;

  static const _ringSize = 112.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final rate = stats.rate;
    final percent = rate == null ? '–' : '${(rate * 100).round()} %';
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Semantics(
              label: rate == null
                  ? 'Aucune mission due pour le moment'
                  : '$percent des missions dues accomplies',
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: _ringSize,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: rate ?? 0),
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CustomPaint(
                    painter: _RingPainter(
                      progress: value,
                      track: colors.muted,
                      fill: colors.accent,
                    ),
                    child: Center(
                      child: Text(
                        percent,
                        style: text.headlineSmall?.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekVerdict(rate),
                    style: text.titleMedium?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stats.done} ${stats.done > 1 ? 'missions accomplies' : 'mission accomplie'} '
                    'sur ${stats.due} ${stats.due > 1 ? 'dues' : 'due'}',
                    style: TextStyle(color: colors.foreground),
                  ),
                  if (stats.upcoming > 0)
                    Text(
                      '${stats.upcoming} à venir',
                      style: TextStyle(color: colors.mutedForeground),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      paint..color = fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

class _KpiTiles extends StatelessWidget {
  const _KpiTiles({required this.stats, required this.streak});

  final WeekStats stats;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tiles = [
          _Kpi(
            icon: LucideIcons.timer,
            label: 'Temps accompli',
            value: formatDuration(stats.doneMinutes),
            detail: 'sur ${formatDuration(stats.plannedMinutes)} prévues',
          ),
          _Kpi(
            icon: LucideIcons.flame,
            label: 'Série',
            value: streak <= 1 ? '$streak jour' : '$streak jours',
            detail: 'réussis d\'affilée',
          ),
          _Kpi(
            icon: LucideIcons.target,
            label: 'Meilleur jour',
            value: _bestDay(stats),
            detail: 'de la semaine',
          ),
        ];
        // Trois tuiles côte à côte si la place le permet, sinon empilées.
        if (constraints.maxWidth < 420 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(
            children: [
              for (final tile in tiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(width: double.infinity, child: tile),
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, tile) in tiles.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: tile),
            ],
          ],
        );
      },
    );
  }

  static String _bestDay(WeekStats stats) {
    DayStats? best;
    for (final day in stats.days) {
      final rate = day.rate;
      if (rate == null || day.done == 0) continue;
      if (best == null ||
          rate > best.rate! ||
          (rate == best.rate! && day.done > best.done)) {
        best = day;
      }
    }
    if (best == null) return '–';
    final name = weekdayName(best.date);
    return name[0].toUpperCase() + name.substring(1);
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primaryOnSurface),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: text.labelLarge?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: text.titleLarge?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(detail, style: TextStyle(color: colors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

/// Colonnes empilées par jour : faites, manquées, à venir. Une légende, une
/// info-bulle par jour et un tableau détaillé portent les mêmes chiffres.
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.stats, required this.today});

  final WeekStats stats;
  final LocalDate today;

  static const _plotHeight = 140.0;
  static const _barWidth = 24.0;
  static const _gap = 2.0;
  static const _radius = Radius.circular(4);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final maxTotal = stats.days.map((d) => d.total).fold(1, math.max);
    final segments = [
      (label: 'Faites', color: colors.accent),
      (label: 'Manquées', color: colors.destructive),
      (label: 'À venir', color: colors.border),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Missions par jour', style: text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                for (final segment in segments)
                  _LegendItem(label: segment.label, color: segment.color),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _plotHeight + MediaQuery.textScalerOf(context).scale(48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in stats.days)
                    Expanded(
                      child: _DayColumn(
                        day: day,
                        isToday: day.date == today,
                        maxTotal: maxTotal,
                        colors: [for (final s in segments) s.color],
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: EdgeInsets.zero,
              title: const Text('Détail par jour'),
              children: [
                for (final day in stats.days)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${weekdayName(day.date)} ${formatDayMonth(day.date)}',
                          ),
                        ),
                        Text(_dayDetail(day)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _dayDetail(DayStats day) =>
      '${day.done} faites · ${day.missed} manquées · ${day.upcoming} à venir';
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.isToday,
    required this.maxTotal,
    required this.colors,
  });

  final DayStats day;
  final bool isToday;
  final int maxTotal;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final text = Theme.of(context).textTheme;
    final counts = [day.done, day.missed, day.upcoming];
    final description =
        '${weekdayName(day.date)} : ${_DailyChart._dayDetail(day)}';
    // Empilées de bas en haut ; seul le segment du haut a des coins arrondis.
    final topIndex = counts.lastIndexWhere((count) => count > 0);
    return Tooltip(
      message: description,
      child: Semantics(
        label: description,
        excludeSemantics: true,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Place laissée au chiffre posé sur la colonne.
                  final label = MediaQuery.textScalerOf(context).scale(16) + 6;
                  final unit =
                      math.max(constraints.maxHeight - label, 0) / maxTotal;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (day.total > 0)
                        Text(
                          '${day.total}',
                          maxLines: 1,
                          style: text.labelMedium?.copyWith(
                            color: palette.mutedForeground,
                          ),
                        ),
                      const SizedBox(height: 4),
                      for (var i = counts.length - 1; i >= 0; i--)
                        if (counts[i] > 0)
                          Container(
                            width: _DailyChart._barWidth,
                            height: math.max(
                              counts[i] * unit - _DailyChart._gap,
                              1,
                            ),
                            margin: const EdgeInsets.only(
                              top: _DailyChart._gap,
                            ),
                            decoration: BoxDecoration(
                              color: colors[i],
                              borderRadius: i == topIndex
                                  ? const BorderRadius.vertical(
                                      top: _DailyChart._radius,
                                    )
                                  : null,
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              weekdayShort(day.date),
              style: text.labelMedium?.copyWith(
                color: isToday ? palette.foreground : palette.mutedForeground,
                fontWeight: isToday ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.colors.foreground)),
      ],
    );
  }
}

/// Temps accompli sur temps prévu, une barre par catégorie, avec son icône
/// et son nom : la couleur n'est jamais le seul repère.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.stats});

  final WeekStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temps par catégorie', style: text.titleSmall),
            const SizedBox(height: 12),
            for (final category in stats.categories) ...[
              Semantics(
                label:
                    '${category.category.label} : '
                    '${formatDuration(category.doneMinutes)} accomplies sur '
                    '${formatDuration(category.plannedMinutes)} prévues',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          categoryIcon(category.category),
                          size: 20,
                          color: colors.categoryColor(category.category),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.category.label,
                            style: TextStyle(color: colors.foreground),
                          ),
                        ),
                        Text(
                          '${formatDuration(category.doneMinutes)} / '
                          '${formatDuration(category.plannedMinutes)}',
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: category.plannedMinutes == 0
                            ? 0
                            : category.doneMinutes / category.plannedMinutes,
                        backgroundColor: colors.muted,
                        color: colors.categoryColor(category.category),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _insightIcon(InsightKind kind) => switch (kind) {
  InsightKind.overrun => LucideIcons.hourglass,
  InsightKind.underrun => LucideIcons.zap,
  InsightKind.timeOfDay => LucideIcons.sunrise,
  InsightKind.weekday => LucideIcons.calendarX2,
  InsightKind.neglected => LucideIcons.triangleAlert,
};

/// « F.R.I.D.A.Y a remarqué » : observations, et prompt enrichi à copier.
class _InsightsCard extends ConsumerWidget {
  const _InsightsCard({required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.radar, color: colors.primaryOnSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('F.R.I.D.A.Y a remarqué', style: text.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              Text(
                "Pas encore assez d'observations, monsieur. Continuez à "
                'marquer vos tâches comme faites : il me faut au moins trois '
                'tâches comparables sur les quatre dernières semaines.',
                style: TextStyle(color: colors.foreground),
              )
            else
              for (final insight in insights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _insightIcon(insight.kind),
                        size: 20,
                        color: colors.primaryOnSurface,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          insight.message,
                          style: TextStyle(color: colors.foreground),
                        ),
                      ),
                    ],
                  ),
                ),
            if (insights.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Ces observations sont ajoutées au prompt de la semaine '
                'prochaine.',
                style: TextStyle(color: colors.mutedForeground),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(
                      text: buildPlanPrompt(
                        today: ref.read(todayProvider),
                        settings: ref.read(currentSettingsProvider),
                        insights: insights,
                      ),
                    ),
                  );
                  showMessage(messenger, 'Prompt enrichi copié.');
                },
                icon: const Icon(LucideIcons.copy),
                label: const Text('Copier le prompt enrichi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bilan lu à voix haute : chiffres de la semaine puis observations.
String spokenWeekReport(WeekStats stats, List<Insight> insights) {
  final summary = weeklyReportBody(stats)
      .replaceAll(' Le détail vous attend dans le Bilan.', '');
  if (insights.isEmpty) return summary;
  return '$summary Mes observations : '
      '${insights.map((insight) => insight.message).join(' ')}';
}
