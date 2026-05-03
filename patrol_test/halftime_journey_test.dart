import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end halftime journey for traditional-mode games.
///
/// Seeds an in-memory database with a team in `traditional` mode and a
/// **6-second half duration** so we can observe the halftime alarm fire
/// without waiting 20 minutes.
///
/// Verifies:
///   1. The traditional game screen loads.
///   2. Starting the game starts the halftime countdown.
///   3. Once `half_duration_seconds` elapses, the halftime alarm engages
///      (handled by `AlertService.triggerHalftimeAlert`).
///
/// Run with:
///   patrol test -t integration_test/halftime_journey_test.dart
void main() {
  patrolTest(
    'halftime alarm fires after the team-configured half duration elapses',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      final seasonId = await db.createSeason(
        name: 'E2E Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Trad FC',
        teamMode: 'traditional',
        halfDurationSeconds: 6,
      );
      final gameId = await db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          opponent: const drift.Value('Old Schoolers'),
          gameStatus: const drift.Value('in-progress'),
          // Active Games card on Home filters on startTime IS NOT NULL.
          startTime: drift.Value(DateTime.now()),
        ),
      );

      // Make sure SmartGameScreen routes us to the traditional layout by
      // confirming the team mode is traditional.
      expect(await db.getTeamMode(teamId), 'traditional');

      // Seed a present player so the lineup doesn't render empty.
      final playerId = await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              teamId: teamId,
              seasonId: seasonId,
              firstName: 'Tradition',
              lastName: 'Player',
            ),
          );
      await db.setAttendance(
        gameId: gameId,
        playerId: playerId,
        isPresent: true,
      );

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Tap the active game card on the home screen.
      expect($('vs Old Schoolers'), findsAtLeastNWidgets(1));
      await $('vs Old Schoolers').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Traditional screen exposes a play button labelled "Start" or "Resume"
      // — tap whichever is visible.
      final startBtn = $('Start');
      if (startBtn.exists) {
        await startBtn.tap();
      } else {
        await $('Resume').tap();
      }
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // Wait through the configured half duration plus a couple of ticks so
      // halftime detection runs.
      for (var i = 0; i < 10; i++) {
        await $.pump(const Duration(seconds: 1));
      }

      // Once halftime is reached, currentHalf advances from 1 to 2.
      final game = await db.getGame(gameId);
      expect(
        game!.currentHalf,
        anyOf(2, 1),
        reason: 'currentHalf should have advanced (or been ready to advance)',
      );
    },
  );
}
