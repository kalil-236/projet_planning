import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../domain/task.dart';
import 'common_widgets.dart';

/// Décalage appliqué par un glissement vers la gauche.
const swipeShiftMinutes = 15;

/// Glisser une tâche à faire : vers la droite elle est faite, vers la gauche
/// elle est décalée de 15 minutes. Une vibration marque le seuil, et un
/// bandeau propose d'annuler. Les deux actions existent aussi pour les
/// lecteurs d'écran.
class SwipeableTask extends ConsumerStatefulWidget {
  const SwipeableTask({required this.task, required this.child, super.key});

  final Task task;
  final Widget child;

  @override
  ConsumerState<SwipeableTask> createState() => _SwipeableTaskState();
}

enum _SwipeAction { done, shift }

class _SwipeableTaskState extends ConsumerState<SwipeableTask>
    with TickerProviderStateMixin {
  static const _threshold = 72.0;
  static const _maxDrag = 140.0;
  static const _radius = BorderRadius.all(Radius.circular(8));

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() => setState(() => _dx = _settleFrom * (1 - _settle.value)));

  /// Petit rebond de l'icône quand l'action est validée.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  double _dx = 0;
  double _settleFrom = 0;
  bool _armed = false;

  bool get _enabled => widget.task.status == TaskStatus.todo;

  @override
  void dispose() {
    _settle.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails details) {
    _settle.stop();
    setState(() {
      _dx = (_dx + details.delta.dx).clamp(-_maxDrag, _maxDrag);
    });
    final armed = _dx.abs() >= _threshold;
    if (armed != _armed) {
      _armed = armed;
      if (armed) HapticFeedback.selectionClick();
    }
  }

  Future<void> _onEnd(DragEndDetails details) async {
    final action = !_armed
        ? null
        : _dx > 0
        ? _SwipeAction.done
        : _SwipeAction.shift;
    _armed = false;
    if (action != null) {
      HapticFeedback.mediumImpact();
      if (!_reducedMotion) await _pop.forward(from: 0);
    }
    _springBack();
    if (action != null) await _apply(action);
  }

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  void _springBack() {
    if (!mounted) return;
    if (_reducedMotion) {
      setState(() => _dx = 0);
      return;
    }
    _settleFrom = _dx;
    _settle.forward(from: 0);
  }

  Future<void> _apply(_SwipeAction action) async {
    final task = widget.task;
    final service = ref.read(planningServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _SwipeAction.done:
        await service.setStatus(task, TaskStatus.done);
        _confirm(messenger, 'Faite : ${task.title}', task);
      case _SwipeAction.shift:
        final moved = await service.shiftBy(task, swipeShiftMinutes);
        if (moved) {
          _confirm(
            messenger,
            'Décalée de $swipeShiftMinutes min : ${task.title}',
            task,
          );
        } else {
          showMessage(messenger, 'Impossible : la tâche dépasserait minuit.');
        }
    }
  }

  void _confirm(ScaffoldMessengerState messenger, String text, Task before) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => ref.read(planningServiceProvider).restore(before),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;
    final colors = context.colors;
    final toRight = _dx > 0;
    final progress = math.min(_dx.abs() / _threshold, 1.0);
    final color = toRight ? colors.accent : colors.primaryOnSurface;

    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Marquer faite'): () =>
            _apply(_SwipeAction.done),
        const CustomSemanticsAction(
          label: 'Décaler de $swipeShiftMinutes min',
        ): () =>
            _apply(_SwipeAction.shift),
      },
      child: GestureDetector(
        onHorizontalDragUpdate: _onUpdate,
        onHorizontalDragEnd: _onEnd,
        onHorizontalDragCancel: _springBack,
        child: ClipRRect(
          borderRadius: _radius,
          child: Stack(
            children: [
              if (_dx != 0)
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: ColoredBox(
                      color: Color.alphaBlend(
                        color.withValues(alpha: 0.10 + 0.14 * progress),
                        colors.surface,
                      ),
                      child: Align(
                        alignment: toRight
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _SwipeHint(
                            icon: toRight
                                ? LucideIcons.circleCheckBig
                                : LucideIcons.timer,
                            label: toRight ? 'Fait' : '+$swipeShiftMinutes min',
                            color: color,
                            armed: progress >= 1,
                            pop: _pop,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.translate(offset: Offset(_dx, 0), child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.icon,
    required this.label,
    required this.color,
    required this.armed,
    required this.pop,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool armed;
  final Animation<double> pop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: pop,
      builder: (context, child) {
        // Grossit puis revient : 1 → 1,35 → 1.
        final bump = math.sin(pop.value * math.pi) * 0.35;
        return Transform.scale(scale: (armed ? 1.1 : 0.9) + bump, child: child);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
