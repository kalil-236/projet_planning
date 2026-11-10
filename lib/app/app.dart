import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_settings.dart';
import '../platform/shared_plan.dart';
import 'destinations.dart';
import 'in_app_reminders.dart';
import 'keyboard_shortcuts.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class AssistantPlanningApp extends ConsumerWidget {
  const AssistantPlanningApp({super.key});

  static const _locale = Locale('fr', 'FR');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderLifecycleProvider);
    ref.watch(syncLifecycleProvider);
    ref.watch(inAppRemindersProvider);
    final router = ref.watch(routerProvider);
    // Fichier ouvert ou partagé depuis une autre application : aperçu d'import.
    ref.listen(pendingSharedPlanProvider, (_, next) {
      if (next != null) router.go(AppDestination.importPlan.path);
    });
    return MaterialApp.router(
      title: 'F.R.I.D.A.Y',
      scaffoldMessengerKey: rootMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (ref.watch(currentSettingsProvider).themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      locale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      // Sous les raccourcis par défaut : une touche non utilisée ici, ou un
      // raccourci inactif, garde son comportement habituel.
      builder: (context, child) {
        final shortcuts = Shortcuts(
          shortcuts: appShortcuts,
          child: Actions(
            actions: appShortcutActions(ref, router),
            child: child!,
          ),
        );
        if (!MediaQuery.disableAnimationsOf(context)) return shortcuts;
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(pageTransitionsTheme: reducedMotionTransitions),
          child: shortcuts,
        );
      },
    );
  }
}
