import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'data/services/notification_service.dart';

/// Alternate app entry-point used only by `store/capture_screenshots.ps1`.
///
/// Boots `SoccerApp` against an in-memory DB seeded from the scrubbed
/// `marketing_screenshots.json` fixture, then cycles through the marketing
/// routes using a marker-file handshake with the host runner:
///
///   1. navigate to a route (via the global `router`)
///   2. settle for ~1.2s so FutureBuilders/Streams resolve
///   3. touch `<extDir>/screenshot_ready_<name>`
///   4. poll for the runner to delete that marker (then proceed to next)
///
/// The runner deletes the marker once it has captured the screen with
/// `adb exec-out screencap`. This avoids `flutter drive`'s flaky VM-service
/// handshake while still using the production widget tree for real visuals.
///
/// Run with:
///   flutter run -t lib/main_screenshots.dart -d emulator-5554
void main() async {
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

  final db = AppDb.test();
  final fixtureJson = await rootBundle.loadString(
    'test/fixtures/marketing_screenshots.json',
  );
  await db.importDatabase(fixtureJson);
  await db.updateGame(
    id: 1,
    gameStatus: 'in-progress',
    isGameActive: true,
  );

  runApp(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: const SoccerApp(),
    ),
  );

  // Kick off the screenshot cycle once the first frame has been rendered.
  WidgetsBinding.instance.addPostFrameCallback((_) => _captureCycle());
}

Future<void> _captureCycle() async {
  // Clean any stale markers from a previous interrupted run.
  final extDir = await getExternalStorageDirectory();
  if (extDir == null) {
    debugPrint('SCREENSHOT_ABORT: getExternalStorageDirectory returned null');
    return;
  }
  for (final f in extDir.listSync()) {
    if (f is File && f.path.contains('screenshot_ready_')) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
  debugPrint('SCREENSHOT_MARKER_DIR: ${extDir.path}');

  Future<void> waitForRunner(String name) async {
    final marker = File('${extDir.path}/screenshot_ready_$name');
    await marker.writeAsString(DateTime.now().toIso8601String());
    debugPrint('SCREENSHOT_READY:$name');
    final deadline = DateTime.now().add(const Duration(seconds: 120));
    while (await marker.exists()) {
      if (DateTime.now().isAfter(deadline)) {
        debugPrint('SCREENSHOT_TIMEOUT:$name');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    debugPrint('SCREENSHOT_DONE:$name');
  }

  Future<void> step(String route, String name) async {
    router.go(route);
    // Let nav transitions + FutureBuilders + Streams settle. 1.2s is generous
    // for non-animated routes; bump if a screen looks half-loaded.
    await Future.delayed(const Duration(milliseconds: 1200));
    await waitForRunner(name);
  }

  await step('/teams', 'teams');
  await step('/team/1/formations', 'formations');
  await step('/game/1', 'live_game');
  await step('/team/1/players', 'roster');
  await step('/team/1/metrics', 'stats');

  debugPrint('SCREENSHOT_RUN_COMPLETE');
}
