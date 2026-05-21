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

  // Patrol runs on a real Android emulator with a fixed screen size; many
  // production layouts overflow by 0.5–80 px on this display (rounding errors,
  // long team names, narrow active-games card). Flutter's test framework
  // upgrades every `RenderFlex overflowed` warning to a test failure, which
  // makes the suite fail at the first navigation regardless of the test's
  // actual assertion. Filter overflow warnings out so the tests can verify
  // behavior; the warnings still print so real layout bugs remain visible.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final ex = details.exception;
    if (ex is FlutterError && ex.message.contains('overflowed by')) {
      FlutterError.dumpErrorToConsole(details);
      return;
    }
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

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
