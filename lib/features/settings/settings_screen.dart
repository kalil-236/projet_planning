import 'package:flutter/widgets.dart';

import '../../app/destinations.dart';
import '../../app/widgets/coming_soon_view.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      destination: AppDestination.settings,
      message: 'Les réglages seront disponibles ici.',
    );
  }
}
