import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/destinations.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/time_zones.dart';
import '../../domain/app_settings.dart';
import '../../domain/device_preferences.dart';
import '../../domain/local_time.dart';
import '../shared/common_widgets.dart';
import 'account_card.dart';
import 'voice_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _maxContentWidth = 720.0;
  static const _reminderChoices = [0, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value;

    Future<void> save(AppSettings updated) =>
        ref.read(planningServiceProvider).saveSettings(updated);

    return Scaffold(
      appBar: AppBar(title: Text(AppDestination.settings.label)),
      body: settings == null
          ? const LoadingSkeleton()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (kIsWeb) const _WebNotice(),
                    const AccountCard(),
                    const VoiceCard(),
                    Card(
                      child: Column(
                        children: [
                          _TimeTile(
                            icon: LucideIcons.sun,
                            title: 'Début de journée',
                            value: settings.dayStart,
                            onPicked: (time) => _saveBounds(
                              context,
                              save,
                              settings,
                              start: time,
                            ),
                          ),
                          _TimeTile(
                            icon: LucideIcons.clock,
                            title: 'Fin de journée',
                            value: settings.dayEnd,
                            onPicked: (time) =>
                                _saveBounds(context, save, settings, end: time),
                          ),
                          ListTile(
                            leading: const Icon(LucideIcons.bell),
                            title: const Text('Rappel par défaut'),
                            trailing: DropdownButton<int>(
                              value:
                                  _reminderOptions(settings)
                                      .contains(settings.defaultReminderMin)
                                  ? settings.defaultReminderMin
                                  : null,
                              underline: const SizedBox.shrink(),
                              items: [
                                for (final minutes in _reminderOptions(
                                  settings,
                                ))
                                  DropdownMenuItem(
                                    value: minutes,
                                    child: Text(
                                      minutes == 0 ? 'Aucun' : '$minutes min',
                                    ),
                                  ),
                              ],
                              onChanged: (value) => save(
                                settings.copyWith(defaultReminderMin: value),
                              ),
                            ),
                          ),
                          SwitchListTile(
                            secondary: const Icon(LucideIcons.sunrise),
                            title: const Text('Résumé du matin'),
                            value: settings.morningSummaryEnabled,
                            onChanged: (value) => save(
                              settings.copyWith(morningSummaryEnabled: value),
                            ),
                          ),
                          if (settings.morningSummaryEnabled)
                            _TimeTile(
                              icon: LucideIcons.alarmClock,
                              title: 'Heure du résumé',
                              value: settings.morningSummaryTime,
                              onPicked: (time) => save(
                                settings.copyWith(morningSummaryTime: time),
                              ),
                            ),
                          if (ref.watch(notificationGatewayProvider) != null)
                            const _ReportSwitches(),
                          ListTile(
                            leading: const Icon(LucideIcons.calendarClock),
                            title: const Text('Fuseau horaire'),
                            subtitle: Text(settings.timezone),
                            onTap: () async {
                              final picked = await _pickTimezone(
                                context,
                                settings.timezone,
                              );
                              if (picked != null) {
                                await save(settings.copyWith(timezone: picked));
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(LucideIcons.settings),
                            title: const Text('Thème'),
                            trailing: DropdownButton<AppThemeMode>(
                              value: settings.themeMode,
                              underline: const SizedBox.shrink(),
                              items: [
                                for (final mode in AppThemeMode.values)
                                  DropdownMenuItem(
                                    value: mode,
                                    child: Text(mode.label),
                                  ),
                              ],
                              onChanged: (value) =>
                                  save(settings.copyWith(themeMode: value)),
                            ),
                          ),
                          if (ref.watch(notificationGatewayProvider) != null)
                            ListTile(
                              leading: const Icon(LucideIcons.batteryCharging),
                              title: const Text('Assistance batterie'),
                              subtitle: const Text(
                                "Pour recevoir les rappels à l'heure.",
                              ),
                              trailing: const Icon(LucideIcons.chevronRight),
                              onTap: () => context.go(
                                '${AppDestination.settings.path}/'
                                '$batteryAssistanceSegment',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<int> _reminderOptions(AppSettings settings) =>
      {..._reminderChoices, settings.defaultReminderMin}.toList()..sort();

  Future<void> _saveBounds(
    BuildContext context,
    Future<void> Function(AppSettings) save,
    AppSettings settings, {
    LocalTime? start,
    LocalTime? end,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final newStart = start ?? settings.dayStart;
    final newEnd = end ?? settings.dayEnd;
    if (!newEnd.isAfter(newStart)) {
      showMessage(messenger, 'La fin de journée doit être après le début.');
      return;
    }
    await save(settings.copyWith(dayStart: newStart, dayEnd: newEnd));
  }

  Future<String?> _pickTimezone(BuildContext context, String current) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TimezoneDialog(current: current),
    );
  }
}

class _WebNotice extends StatelessWidget {
  const _WebNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Icon(LucideIcons.info),
          title: Text(
            'Les rappels sonnent sur le téléphone. Sur PC, ils s\'affichent '
            'seulement tant que l\'onglet est ouvert.',
          ),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onPicked,
  });

  final IconData icon;
  final String title;
  final LocalTime value;
  final ValueChanged<LocalTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(value.toHHmm()),
      onTap: () async {
        final picked = await pickLocalTime(context, value);
        if (picked != null) onPicked(picked);
      },
    );
  }
}

class _TimezoneDialog extends StatefulWidget {
  const _TimezoneDialog({required this.current});

  final String current;

  @override
  State<_TimezoneDialog> createState() => _TimezoneDialogState();
}

class _TimezoneDialogState extends State<_TimezoneDialog> {
  final List<String> _all = allTimezones();
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final query = _filter.toLowerCase();
    final matches = _all.where((z) => z.toLowerCase().contains(query)).toList();
    return AlertDialog(
      title: const Text('Fuseau horaire'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Rechercher'),
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (_, index) => ListTile(
                  title: Text(matches[index]),
                  selected: matches[index] == widget.current,
                  onTap: () => Navigator.pop(context, matches[index]),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

/// Rapports propres au téléphone, là où les notifications sonnent.
class _ReportSwitches extends ConsumerWidget {
  const _ReportSwitches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(currentDevicePrefsProvider);
    Future<void> save(DevicePreferences updated) =>
        ref.read(planningServiceProvider).saveDevicePrefs(updated);
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(LucideIcons.moon),
          title: const Text('Rapport du soir'),
          subtitle: const Text(
            'À la fin de journée : missions accomplies et report des '
            'restantes.',
          ),
          value: prefs.eveningReportEnabled,
          onChanged: (value) =>
              save(prefs.copyWith(eveningReportEnabled: value)),
        ),
        SwitchListTile(
          secondary: const Icon(LucideIcons.chartColumn),
          title: const Text('Bilan de la semaine'),
          subtitle: const Text('Le dimanche soir, avec le détail dans Bilan.'),
          value: prefs.weeklyReportEnabled,
          onChanged: (value) =>
              save(prefs.copyWith(weeklyReportEnabled: value)),
        ),
      ],
    );
  }
}
