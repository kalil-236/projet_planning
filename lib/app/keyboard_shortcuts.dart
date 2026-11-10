import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/local_date.dart';
import '../features/task_editor/task_editor.dart';
import 'destinations.dart';
import 'providers.dart';

/// Raccourcis clavier sur PC (8.5) : `N` nouvelle tâche, `T` aujourd'hui,
/// `←` et `→` jour précédent ou suivant dans Semaine.
class NewTaskIntent extends Intent {
  const NewTaskIntent();
}

class TodayIntent extends Intent {
  const TodayIntent();
}

class MoveDayIntent extends Intent {
  const MoveDayIntent(this.days);

  final int days;
}

const appShortcuts = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.keyN): NewTaskIntent(),
  SingleActivator(LogicalKeyboardKey.keyT): TodayIntent(),
  SingleActivator(LogicalKeyboardKey.arrowLeft): MoveDayIntent(-1),
  SingleActivator(LogicalKeyboardKey.arrowRight): MoveDayIntent(1),
};

Map<Type, Action<Intent>> appShortcutActions(WidgetRef ref, GoRouter router) {
  final shortcuts = _AppShortcuts(ref, router);
  return {
    NewTaskIntent: _ShortcutAction<NewTaskIntent>(
      isEnabled: shortcuts.available,
      onInvoke: (_) => shortcuts.newTask(),
    ),
    TodayIntent: _ShortcutAction<TodayIntent>(
      isEnabled: shortcuts.available,
      onInvoke: (_) => shortcuts.today(),
    ),
    MoveDayIntent: _ShortcutAction<MoveDayIntent>(
      isEnabled: () => shortcuts.available() && shortcuts.onWeek,
      onInvoke: shortcuts.moveDay,
    ),
  };
}

class _AppShortcuts {
  _AppShortcuts(this._ref, this._router);

  final WidgetRef _ref;
  final GoRouter _router;

  NavigatorState? get _navigator =>
      _router.routerDelegate.navigatorKey.currentState;

  String get _path => _router.routerDelegate.currentConfiguration.uri.path;

  bool get onWeek => _path.startsWith(AppDestination.week.path);

  /// Inactif pendant une saisie, quand une fenêtre est ouverte, et hors des
  /// quatre écrans principaux (connexion par exemple).
  bool available() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        (focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    if (_navigator?.canPop() ?? true) return false;
    return AppDestination.values.any(
      (destination) => _path.startsWith(destination.path),
    );
  }

  void newTask() {
    final context = _navigator?.context;
    if (context != null) showTaskEditor(context);
  }

  void today() {
    if (onWeek) {
      _ref.read(weekSelectedDayProvider.notifier).select(null);
    } else {
      _router.go(AppDestination.today.path);
    }
  }

  void moveDay(MoveDayIntent intent) {
    final LocalDate today = _ref.read(nowProvider).date;
    final LocalDate selected = _ref.read(weekSelectedDayProvider) ?? today;
    _ref
        .read(weekSelectedDayProvider.notifier)
        .select(selected.addDays(intent.days));
  }
}

class _ShortcutAction<T extends Intent> extends Action<T> {
  _ShortcutAction({required this._isEnabled, required this._onInvoke});

  final bool Function() _isEnabled;
  final void Function(T intent) _onInvoke;

  /// Désactivée, la touche poursuit son chemin (défilement, saisie...).
  @override
  bool isEnabled(T intent) => _isEnabled();

  @override
  Object? invoke(T intent) {
    _onInvoke(intent);
    return null;
  }
}
