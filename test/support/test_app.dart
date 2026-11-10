import 'package:assistant_planning/app/app.dart';
import 'package:assistant_planning/app/in_app_reminders.dart';
import 'package:assistant_planning/app/providers.dart';
import 'package:assistant_planning/core/clock.dart';
import 'package:assistant_planning/core/french_format.dart';
import 'package:assistant_planning/core/time_zones.dart';
import 'package:assistant_planning/data/database.dart';
import 'package:assistant_planning/notifications/notification_gateway.dart';
import 'package:assistant_planning/platform/shared_plan.dart';
import 'package:assistant_planning/sync/sync_backend.dart';
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
  NotificationGateway? gateway,
  SyncBackend? syncBackend,
  bool loginRequired = false,
  bool inAppReminders = false,
  SharedPlanSource? sharedPlanSource,
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
        notificationGatewayProvider.overrideWithValue(gateway),
        syncBackendProvider.overrideWithValue(syncBackend),
        loginRequiredProvider.overrideWithValue(loginRequired),
        inAppRemindersEnabledProvider.overrideWithValue(inAppReminders),
        sharedPlanSourceProvider.overrideWithValue(sharedPlanSource),
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
