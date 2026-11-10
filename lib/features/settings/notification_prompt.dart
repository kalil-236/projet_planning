import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Explique puis demande l'autorisation des notifications au premier lancement
/// (section 10.5). Une seule fois : les réglages permettent d'y revenir.
class NotificationPrompt extends ConsumerStatefulWidget {
  const NotificationPrompt({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationPrompt> createState() => _NotificationPromptState();
}

class _NotificationPromptState extends ConsumerState<NotificationPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptIfNeeded());
  }

  Future<void> _promptIfNeeded() async {
    final gateway = ref.read(notificationGatewayProvider);
    if (gateway == null) return;
    final settings = ref.read(settingsRepositoryProvider);
    if (await settings.notificationPromptShown()) return;
    if (await gateway.notificationsAllowed()) {
      await settings.markNotificationPromptShown();
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Autoriser les rappels'),
        content: const Text(
          'Pour vous rappeler vos tâches et vous envoyer le résumé du matin, '
          "l'application a besoin d'afficher des notifications.",
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    await gateway.requestNotifications();
    await settings.markNotificationPromptShown();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
