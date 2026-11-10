import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/french_format.dart';
import 'core/time_zones.dart';
import 'sync/supabase_sync_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimeZones();
  await initFrenchFormats();
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: AssistantPlanningApp()));
}
