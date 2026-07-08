import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';
import 'helpers/screenshot.dart';

/// End-to-end team management journey.
///
/// Drives the same UI a coach uses to set up a fresh install:
///   1. Open "Manage Teams" from the home dashboard.
///   2. Use the FAB to open the Create Team dialog and submit a name.
///   3. Verify the new team appears in the seeded season's roster.
///   4. Tap into the team to confirm the detail screen loads.
///
/// Seeds an active season directly through the DB so the dialog has a
/// season to attach the team to (the production "no active season" fallback
/// asks the user to visit /seasons first — covered separately by
/// [season_clone_journey_test.dart]).
void main() {
  patrolTest(
    'creating a team from the home dashboard adds it to the active season',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      await db.createSeason(name: 'E2E Active', startDate: DateTime.now());

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Tap the "Manage Teams" quick-action card on the home screen.
      expect($('Manage Teams'), findsAtLeastNWidgets(1));
      await $('Manage Teams').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // The empty-state on /teams shows a Create Team button. Either it or
      // the FAB will start the dialog — the FAB is always present.
      await $(find.byIcon(Icons.add)).first.tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // Type the new team name and submit.
      await $(find.byType(TextField)).enterText('Galaxy FC');
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));
      await $('Create').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // The teams list should now include the newly created team.
      expect(
        $('Galaxy FC'),
        findsAtLeastNWidgets(1),
        reason: 'New team should appear in the active-season roster',
      );

      // Verify by drilling into the team detail screen — the game-first landing
      // (#38) opens with the recent/next game sections and a Create New Game
      // action (there's no longer a "Team Management" hub card grid).
      await $('Galaxy FC').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));
      expect(
        $('Create New Game'),
        findsOneWidget,
        reason: 'Tapping the team should open the game-first team landing',
      );

      await captureScreenshot($, 'team-detail-after-create');

      // DB-side sanity check: the team is owned by the seeded season.
      final teams = await db.getAllTeams();
      expect(teams.where((t) => t.name == 'Galaxy FC'), hasLength(1));
    },
  );
}
