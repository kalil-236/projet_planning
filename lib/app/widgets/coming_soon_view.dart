import 'package:flutter/material.dart';

import '../destinations.dart';
import '../theme/app_colors.dart';

/// Écran provisoire d'une destination dont le contenu n'est pas encore livré.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    required this.destination,
    required this.message,
    super.key,
  });

  final AppDestination destination;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(destination.label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, size: 48, color: colors.mutedForeground),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
