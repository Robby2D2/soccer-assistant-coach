import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccer_assistant_coach/core/router.dart';
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

      // Remove any stale StopwatchCtrl state saved by previous test runs.
      // Without this, GameScreen._restore() picks up a stale start-time for
      // gameId=1 (always the same in an in-memory DB), starts the timer
      // immediately on mount, and prevents pumpAndSettle from ever settling.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

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
      await db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          opponent: const drift.Value('Test United'),
          gameStatus: const drift.Value('in-progress'),
          // Active Games card on Home filters on startTime IS NOT NULL.
          startTime: drift.Value(DateTime.now()),
        ),
      );

      // Insert a player but do NOT mark them present — hasPresentPlayersForGame
      // returns false, so _ensureInitialShift exits early and the button stays
      // "Start" (not "Resume").
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'Alex',
          lastName: 'Striker',
        ),
      );

      await $.pumpWidget(appUnderTest(db: db));
      // Home screen has no running timer yet — pumpAndSettle is safe here.
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Active Games card on the home screen shows "vs Test United".
      expect($('vs Test United'), findsAtLeastNWidgets(1));
      // Default settlePolicy (trySettle) properly settles the navigation
      // animation. The StopwatchCtrl timer is NOT yet running (no SharedPrefs
      // state, Start not pressed), so pumpAndSettle completes normally.
      await $('vs Test United').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Game screen has rendered with Start button.
      // Use noSettle for the Start tap: once pressed the StopwatchCtrl
      // Timer.periodic fires every second, so pumpAndSettle never settles.
      // $.pump(Duration) hangs in Patrol/LiveTestWidgetsFlutterBinding when
      // Timer.periodic is running. Use Future.delayed for all real-time waits.
      await $('Start').tap(settlePolicy: SettlePolicy.noSettle);

      // Wait real wall-clock time for the 3-second shift to elapse.
      // StopwatchCtrl computes elapsed via DateTime.now(), so pump-frame
      // loops don't advance its clock — only real time does.
      await Future.delayed(const Duration(seconds: 5));

      // The game screen surfaces the alarm via a SnackBar.
      expect(
        $('Shift time! Tap to acknowledge alert.'),
        findsOneWidget,
        reason: 'Shift alarm SnackBar should appear once shift length elapses',
      );

      // Acknowledge.
      await $('OK').tap(settlePolicy: SettlePolicy.noSettle);

      // Navigate back to trigger GameScreen.dispose() which cancels the
      // StopwatchCtrl + _startAlertStatusMonitoring timers. Without this,
      // the StopwatchCtrl tick keeps calling db.incrementShiftDuration()
      // every second, preventing db.close() in the teardown from draining
      // Drift's executor queue and hanging the PatrolBinding teardown.
      router.pop();

      // Wait for the pop animation (~300 ms) and dispose() to complete.
      await Future.delayed(const Duration(milliseconds: 600));
    },
  );
}
