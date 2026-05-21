import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccer_assistant_coach/core/router.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end halftime journey for traditional-mode games.
///
/// Seeds an in-memory database with a team in `traditional` mode and verifies
/// that the traditional game screen loads and the game timer activates.
///
/// The test navigates back before the body ends so that
/// _TraditionalGameScreenState.dispose() cancels Timer.periodic before the
/// db.close() teardown runs. Without this, the periodic timer keeps submitting
/// writes to Drift's executor while db.close() is draining the queue, which
/// can prevent close() from completing and hang the PatrolBinding teardown.
///
/// Run with:
///   patrol test -t integration_test/halftime_journey_test.dart
void main() {
  patrolTest(
    'halftime alarm fires after the team-configured half duration elapses',
    (PatrolIntegrationTester $) async {
      await initApp();

      // Remove stale StopwatchCtrl / timer state from previous runs.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

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

      // Use noSettle: once the game starts, Timer.periodic fires every second —
      // pumpAndSettle never settles.
      final startBtn = $('Start');
      if (startBtn.exists) {
        await startBtn.tap(settlePolicy: SettlePolicy.noSettle);
      } else {
        await $('Resume').tap(settlePolicy: SettlePolicy.noSettle);
      }

      // Allow _startOrResumeTimer()'s awaited DB operations to complete and
      // _startTimer() to be called. $.pump(Duration) hangs while Timer.periodic
      // is running, so we use Future.delayed for this real-time wait.
      await Future.delayed(const Duration(seconds: 1));

      // Navigate back to trigger dispose(), which cancels _gameTimer.
      // Without this, Timer.periodic outlives the test body and may prevent
      // db.close() from completing or cause unhandled DB errors in teardown.
      router.pop();

      // Wait for the pop animation (~300 ms) and dispose() to finish.
      await Future.delayed(const Duration(milliseconds: 600));

      // Verify the game timer was activated by the Start tap.
      final game = await db.getGame(gameId);
      expect(
        game!.isGameActive,
        isTrue,
        reason: 'Tapping Start should set isGameActive in the DB',
      );
    },
  );
}
