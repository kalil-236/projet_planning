import 'package:flutter/widgets.dart';

import '../../app/destinations.dart';
import '../../app/widgets/coming_soon_view.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      destination: AppDestination.today,
      message: 'La frise de la journée sera affichée ici.',
    );
  }
}
