import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../sync/sync_service.dart';

/// Compte et état de la synchronisation. Absent si Supabase n'est pas configuré.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(syncBackendProvider);
    final service = ref.watch(syncServiceProvider);
    if (backend == null || service == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ValueListenableBuilder(
          valueListenable: service.phase,
          builder: (context, phase, _) {
            if (phase == SyncPhase.signedOut) {
              return ListTile(
                leading: const Icon(LucideIcons.logIn),
                title: const Text('Se connecter'),
                subtitle: const Text('Pour retrouver vos tâches sur PC.'),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => context.go(loginPath),
              );
            }
            return Column(
              children: [
                ListTile(
                  leading: Icon(_iconFor(phase)),
                  title: Text(backend.email ?? 'Compte connecté'),
                  subtitle: Text(_labelFor(phase)),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.refreshCw),
                    tooltip: 'Synchroniser maintenant',
                    onPressed: phase == SyncPhase.syncing
                        ? null
                        : () => unawaited(service.requestSync()),
                  ),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.logOut),
                  title: const Text('Se déconnecter'),
                  onTap: () => unawaited(backend.signOut()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(SyncPhase phase) => switch (phase) {
    SyncPhase.offline => LucideIcons.cloudOff,
    _ => LucideIcons.cloud,
  };

  String _labelFor(SyncPhase phase) => switch (phase) {
    SyncPhase.syncing => 'Synchronisation en cours',
    SyncPhase.offline =>
      'Hors ligne : vos modifications seront envoyées plus tard',
    _ => 'Synchronisé',
  };
}
