import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_assistant_coach/app.dart';
import 'package:soccer_assistant_coach/core/providers.dart';
import 'package:soccer_assistant_coach/data/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

/// Initializes the same platform glue that `lib/main.dart` does (system UI,
/// timezones, notifications). Call this once at the top of every Patrol test
/// before pumping the widget tree.
Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  tz.initializeTimeZones();
  await NotificationService.instance.init();
}

/// Builds the production [SoccerApp] wrapped in a [ProviderScope]. If [db]
/// is provided, [dbProvider] is overridden with it so tests can run against
/// an in-memory database (`AppDb.test()`) and stay isolated from the user's
/// real data.
///
/// We do **not** call `runApp` here — Patrol's `patrolTest` is responsible
/// for pumping the widget via `tester.pumpWidget`.
Widget appUnderTest({AppDb? db}) {
  return ProviderScope(
    overrides: [if (db != null) dbProvider.overrideWithValue(db)],
    child: const SoccerApp(),
  );
}
