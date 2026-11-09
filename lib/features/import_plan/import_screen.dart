import 'package:flutter/widgets.dart';

import '../../app/destinations.dart';
import '../../app/widgets/coming_soon_view.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      destination: AppDestination.importPlan,
      message: "L'import d'un planning se fera ici.",
    );
  }
}
