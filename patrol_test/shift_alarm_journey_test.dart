import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end shift alarm journey.
///
/// Seeds an in-memory database with a team configured for a **3-second
/// shift length** and an in-progress game so the shift-end alarm fires
/// quickly enough for an E2E test (per the user request: use the team's
/// real configurable shift length instead of a debug fast-forward hook).
///
/// Verifies:
///   1. The Active Games card on the home screen renders the seeded game.
///   2. Tapping the card navigates to the game screen.
///   3. Pressing **Start** on the game screen starts the stopwatch.
///   4. Once `shift_length_seconds` elapses, the shift-time SnackBar
///      ("Shift time! Tap to acknowledge alert.") appears.
///   5. Tapping **OK** acknowledges the alert.
///
/// Run with:
///   patrol test -t integration_test/shift_alarm_journey_test.dart
void main() {
  patrolTest(
    'shift alarm fires after the team-configured shift length elapses',
    (PatrolIntegrationTester $) async {
      await initApp();

      // 3-second shift = alarm fires within a normal test timeout.
      final db = AppDb.test();
      addTearDown(db.close);

      final seasonId = await db.createSeason(
        name: 'E2E Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Quick FC',
        shiftLengthSeconds: 3,
      );
      final gameId = await db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          opponent: const drift.Value('Test United'),
          gameStatus: const drift.Value('in-progress'),
          // Active Games card on Home filters on startTime IS NOT NULL.
          startTime: drift.Value(DateTime.now()),
        ),
      );

      // One present player so the screen has data to render.
      final playerId = await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              teamId: teamId,
              seasonId: seasonId,
              firstName: 'Alex',
              lastName: 'Striker',
            ),
          );
      await db.setAttendance(
        gameId: gameId,
        playerId: playerId,
        isPresent: true,
      );

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Active Games card on the home screen shows "vs Test United".
      expect($('vs Test United'), findsAtLeastNWidgets(1));
      await $('vs Test United').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Game screen has rendered. Press Start to begin the shift.
      expect($('Start'), findsOneWidget);
      await $('Start').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // Wait through the configured shift length plus a couple of ticks.
      // We pump real frames so timers advance.
      for (var i = 0; i < 6; i++) {
        await $.pump(const Duration(seconds: 1));
      }

      // The game screen surfaces the alarm via a SnackBar.
      expect(
        $('Shift time! Tap to acknowledge alert.'),
        findsOneWidget,
        reason: 'Shift alarm SnackBar should appear once shift length elapses',
      );

      // Acknowledge.
      await $('OK').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
    },
  );
}
