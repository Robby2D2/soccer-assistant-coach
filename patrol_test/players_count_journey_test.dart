import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/core/router.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';
import 'helpers/screenshot.dart';

/// Journey test: roster count summary is visible on the Players screen.
///
/// Seed state: 3 players, 2 active (isPresent = true), 1 inactive.
/// Expected: "3 players · 2 active" label visible without scrolling.
void main() {
  patrolTest(
    'players screen shows roster count summary',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      final seasonId = await db.createSeason(
        name: 'Count Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Count FC',
      );

      // Two active players
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'Alice',
          lastName: 'Smith',
          isPresent: const drift.Value(true),
        ),
      );
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'Bob',
          lastName: 'Jones',
          isPresent: const drift.Value(true),
        ),
      );
      // One inactive player
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'Carol',
          lastName: 'Lee',
          isPresent: const drift.Value(false),
        ),
      );

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Navigate directly to the players screen.
      router.push('/team/$teamId/players');
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // The count summary should be visible without any scrolling.
      expect($('3 players · 2 active'), findsOneWidget);

      // Capture the fixed UI for the QA screenshot review.
      await captureScreenshot($, 'players-count-summary');
    },
  );
}
