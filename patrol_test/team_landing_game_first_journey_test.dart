import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/core/router.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';
import 'helpers/screenshot.dart';

/// Journey test: the team landing screen (/team/:id) is game-first (issue #37).
///
/// Seed state: one completed game (3-2 vs Riverside) and one upcoming game.
/// Expected: the landing screen shows the recent-game score and the next-game
/// details plus a "Create New Game" action — not the old management-card grid.
void main() {
  patrolTest(
    'team landing screen is game-first',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      final seasonId = await db.createSeason(
        name: 'Landing Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Landing FC',
      );

      // A completed game — surfaces in the "Most Recent Game" card.
      await db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          opponent: const drift.Value('Riverside'),
          gameStatus: const drift.Value('completed'),
          startTime: drift.Value(DateTime(2026, 5, 1)),
          teamScore: const drift.Value(3),
          opponentScore: const drift.Value(2),
        ),
      );

      // An upcoming game — surfaces in the "Next Game" card.
      await db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          opponent: const drift.Value('Lakeside'),
          gameStatus: const drift.Value('in-progress'),
          startTime: drift.Value(DateTime.now().add(const Duration(days: 3))),
        ),
      );

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      router.push('/team/$teamId');
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Game-first content is present.
      expect($('Most Recent Game'), findsOneWidget);
      expect($('Next Game'), findsOneWidget);
      expect($('3–2'), findsOneWidget);
      expect($('Create New Game'), findsOneWidget);

      // The old management-card grid is gone.
      expect($('Team Management'), findsNothing);

      await captureScreenshot($, 'team-landing-game-first');
    },
  );
}
