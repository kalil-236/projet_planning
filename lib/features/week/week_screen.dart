import 'package:flutter/widgets.dart';

import '../../app/destinations.dart';
import '../../app/widgets/coming_soon_view.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      destination: AppDestination.week,
      message: 'La vue des sept jours sera affichée ici.',
    );
  }
}
