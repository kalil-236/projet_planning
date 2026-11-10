import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../domain/notification_plan.dart';
import '../../notifications/notification_gateway.dart';
import '../shared/common_widgets.dart';

typedef _Status = ({bool notifications, bool exactAlarms, bool battery});

class BatteryAssistanceScreen extends ConsumerStatefulWidget {
  const BatteryAssistanceScreen({super.key});

  @override
  ConsumerState<BatteryAssistanceScreen> createState() =>
      _BatteryAssistanceScreenState();
}

class _BatteryAssistanceScreenState
    extends ConsumerState<BatteryAssistanceScreen> {
  static const _maxContentWidth = 720.0;
  static final _helpUrl = Uri.parse('https://dontkillmyapp.com');
  static const _steps = [
    'Autorisez les notifications et les alarmes exactes ci-dessus.',
    "Désactivez l'optimisation de batterie pour cette application.",
    'Sur Xiaomi, Tecno, Infinix ou Samsung, ouvrez aussi les réglages '
        "système de l'application et autorisez le démarrage automatique "
        "et l'activité en arrière-plan.",
    'Envoyez une notification de test, puis éteignez l\'écran et attendez '
        'une minute.',
  ];

  late final AppLifecycleListener _lifecycle;
  _Status? _status;

  NotificationGateway get _gateway => ref.read(notificationGatewayProvider)!;

  @override
  void initState() {
    super.initState();
    // Les réglages système s'ouvrent hors de l'application.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    _refresh();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final status = (
      notifications: await _gateway.notificationsAllowed(),
      exactAlarms: await _gateway.canScheduleExact(),
      battery: await _gateway.batteryOptimizationIgnored(),
    );
    if (mounted) setState(() => _status = status);
  }

  Future<void> _thenRefresh(Future<Object?> action) async {
    await action;
    await _refresh();
  }

  Future<void> _openHelp() async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      _helpUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) showMessage(messenger, 'Impossible d\'ouvrir le lien.');
  }

  Future<void> _sendTest() async {
    final messenger = ScaffoldMessenger.of(context);
    final status = _status;
    if (status == null) return;
    if (!status.notifications) {
      showMessage(messenger, 'Autorisez d\'abord les notifications.');
      return;
    }
    final clock = ref.read(clockProvider);
    await _gateway.schedule(
      testNotification(clock.nowUtc()),
      timezone: ref.read(currentSettingsProvider).timezone,
      exact: status.exactAlarms,
    );
    showMessage(messenger, 'Notification de test prévue dans 1 minute.');
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'Retour',
          onPressed: () => context.pop(),
        ),
        title: const Text('Assistance batterie'),
      ),
      body: status == null
          ? const LoadingSkeleton()
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Column(
                        children: [
                          _StatusTile(
                            ok: status.notifications,
                            okLabel: 'Notifications autorisées',
                            problemLabel: 'Notifications refusées',
                            action: 'Autoriser',
                            onAction: () => _thenRefresh(
                              _gateway.requestNotifications(
                                openSettingsIfBlocked: true,
                              ),
                            ),
                          ),
                          _StatusTile(
                            ok: status.exactAlarms,
                            okLabel: 'Alarmes exactes autorisées',
                            problemLabel:
                                'Alarmes exactes refusées : les rappels '
                                'peuvent arriver en retard',
                            action: 'Ouvrir « Alarmes et rappels »',
                            onAction: () =>
                                _thenRefresh(_gateway.openExactAlarmSettings()),
                          ),
                          _StatusTile(
                            ok: status.battery,
                            okLabel: 'Optimisation de batterie désactivée',
                            problemLabel: 'Optimisation de batterie active',
                            action: 'Désactiver',
                            onAction: () => _thenRefresh(
                              _gateway.requestIgnoreBatteryOptimization(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pour recevoir les rappels à l\'heure',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            for (final (index, step) in _steps.indexed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('${index + 1}. $step'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(LucideIcons.externalLink),
                        title: const Text('Conseils par marque de téléphone'),
                        subtitle: const Text('dontkillmyapp.com'),
                        onTap: _openHelp,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _sendTest,
                      icon: const Icon(LucideIcons.bellRing),
                      label: const Text(
                        'Envoyer une notification de test dans 1 minute',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.ok,
    required this.okLabel,
    required this.problemLabel,
    required this.action,
    required this.onAction,
  });

  final bool ok;
  final String okLabel;
  final String problemLabel;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Icon(
        ok ? LucideIcons.circleCheck : LucideIcons.triangleAlert,
        color: ok ? colors.accent : colors.destructive,
      ),
      title: Text(ok ? okLabel : problemLabel),
      subtitle: ok
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onAction, child: Text(action)),
            ),
    );
  }
}
