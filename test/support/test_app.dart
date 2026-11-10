import 'package:assistant_planning/app/app.dart';
import 'package:assistant_planning/app/providers.dart';
import 'package:assistant_planning/core/clock.dart';
import 'package:assistant_planning/core/french_format.dart';
import 'package:assistant_planning/core/time_zones.dart';
import 'package:assistant_planning/data/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Future<void> initAppFormats() async {
  initTimeZones();
  await initFrenchFormats();
}

AppDatabase createTestDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Lance l'application complète sur une base en mémoire.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  double width = 390,
  double height = 900,
  Clock? clock,
  AppDatabase? database,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = database ?? createTestDatabase();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock ?? FakeClock.porto(tuesday, 9)),
      ],
      child: const AssistantPlanningApp(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
  return db;
}
