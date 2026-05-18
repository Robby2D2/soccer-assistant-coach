import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// JSON import end-to-end test.
///
/// The production import flow goes through `file_picker`, which is awkward
/// to drive natively from Patrol on every platform. We exercise the rest of
/// the pipeline by reading the same fixture used by the unit test
/// (`test/fixtures/full_season_fixed_metrics.json`) and feeding it directly
/// into `AppDb.importDatabase`. The integration value here is that the call
/// happens inside the running app with all platform plugins (path_provider,
/// shared_preferences) initialized — closer to a real device run.
///
/// The fixture is bundled as a Flutter asset (pubspec.yaml) so it is
/// available inside the APK on both emulator and physical devices via
/// rootBundle — dart:io File paths are relative to the device filesystem,
/// not the project root.
void main() {
  patrolTest('importing the seeded fixture populates the running database', (
    PatrolIntegrationTester $,
  ) async {
    await initApp();

    final db = AppDb.test();
    addTearDown(db.close);

    await $.pumpWidget(appUnderTest(db: db));
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    final json = await rootBundle.loadString(
      'test/fixtures/full_season_fixed_metrics.json',
    );
    final imported = await db.importDatabase(json);
    expect(imported, isTrue);

    final teams = await db.getAllTeams();
    expect(
      teams,
      isNotEmpty,
      reason: 'Imported fixture should have produced at least one team',
    );

    // Re-pump so the home screen's StreamBuilder picks up the new data.
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));
  });
}
