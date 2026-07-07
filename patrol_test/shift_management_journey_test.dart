import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccer_assistant_coach/core/router.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end shift management journey for shift-mode games.
///
/// Complements [shift_alarm_journey_test.dart], which covers the
/// time-based alarm path. This test exercises **manual** shift
/// advancement: a coach tapping "Next Shift" while the prior shift is
/// still paused (e.g. half-time, an early sub).
///
/// Verifies:
///   1. A game with two queued shifts surfaces a "Next Shift" control.
///   2. Tapping it shows a confirmation dialog ("Start next shift early?")
///      because time remains on the current shift.
///   3. Confirming the dialog promotes the queued shift to current and
///      updates `games.currentShiftId` in the DB.
///
/// Navigation: we route directly to `/game/$gameId` rather than tapping
/// through the Home screen. This mirrors the pattern in
/// [substitution_journey_test.dart] and avoids two sources of instability:
///   - Waiting for the Home screen's own Drift streams to render the
///     active-games card (extra settling overhead).
///   - Setting `startTime: DateTime.now()` on the game, which would launch
///     an active shift timer. That timer continuously pumps frames, making
///     every Patrol driver interaction unreliable because the app is
///     perpetually "busy" and `pump()` calls stall.
/// Without `startTime`, the clock hasn't started, the timer is idle, and
/// the game screen is settleable — exactly what we need.
void main() {
  patrolTest(
    'See Next Shift then Start Shift advances the current shift after confirmation',
    (PatrolIntegrationTester $) async {
      await initApp();

      // Clear stale timer state persisted by prior tests.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final db = AppDb.test();
      addTearDown(db.close);

      final seasonId = await db.createSeason(
        name: 'Shift Mgmt Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Rotators FC',
        // 5-min shift so the "time remaining" confirmation dialog fires.
        shiftLengthSeconds: 300,
      );
      final gameId = await db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          opponent: const drift.Value('Substitutes United'),
          gameStatus: const drift.Value('in-progress'),
          // No startTime — the clock hasn't started so no active timer runs.
          // startTime is only needed for the Home screen "active games" filter,
          // which we bypass by navigating directly via router.push.
        ),
      );

      // Present player so the lineup doesn't render empty.
      final playerId = await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              teamId: teamId,
              seasonId: seasonId,
              firstName: 'Riley',
              lastName: 'Rotation',
            ),
          );
      await db.setAttendance(
        gameId: gameId,
        playerId: playerId,
        isPresent: true,
      );

      // Seed two shifts: a current one at 0 and a queued next at 300.
      // `startShift` also marks the inserted shift as `currentShiftId`,
      // so the "Resume + Next Shift" controls render on entry.
      final firstShiftId = await db.startShift(gameId, 0);
      final secondShiftId = await db
          .into(db.shifts)
          .insert(
            ShiftsCompanion.insert(gameId: gameId, startSeconds: 300),
          );

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Navigate directly to the game screen — no Home screen tap needed.
      router.push('/game/$gameId');
      await $.pumpAndSettle(timeout: const Duration(seconds: 10));

      // CRITICAL: wrap the interaction in try/finally so the GameScreen is
      // always disposed (router.pop) before the test ends — even on a failed
      // assertion. The GameScreen holds always-open Drift StreamBuilders; if
      // the test ends while it's still mounted, Patrol's teardown deadlocks
      // for the full job timeout (~24+ min) instead of tearing down cleanly.
      // Popping first turns any failure into a fast (~seconds) failure.
      try {
        // The bottom action bar shows "See Next Shift" while the coach is viewing
        // the current shift (a shift is queued after it). Use a plain expect (not
        // waitUntilVisible): a synchronous expect failure tears down fast, whereas
        // a waitUntilVisible timeout is what triggers the multi-minute teardown hang.
        expect($('See Next Shift'), findsAtLeastNWidgets(1));
        // Tapping it scrolls the planning pager to the queued shift; the bar then
        // flips to "Start Shift".
        await $('See Next Shift').first.tap(settlePolicy: SettlePolicy.noSettle);
        await Future.delayed(const Duration(seconds: 1));

        // Now viewing the queued shift, so the bar offers "Start Shift".
        expect($('Start Shift'), findsAtLeastNWidgets(1));
        await $('Start Shift').first.tap(settlePolicy: SettlePolicy.noSettle);
        await Future.delayed(const Duration(seconds: 1));

        // Time is left on the current shift, so the confirmation dialog surfaces.
        expect($('Start next shift early?'), findsOneWidget);
        await $('Start Next Shift').tap(settlePolicy: SettlePolicy.noSettle);
        await Future.delayed(const Duration(seconds: 1));

        // The queued shift is now current. Sanity-check the DB state.
        final game = await db.getGame(gameId);
        expect(
          game?.currentShiftId,
          secondShiftId,
          reason: 'Confirming Next Shift should promote the queued shift',
        );
        expect(game?.currentShiftId, isNot(firstShiftId));
      } finally {
        // Dispose GameScreen (cancel its StreamBuilder subscriptions) before
        // the patrolTest body returns and db.close() runs in tearDown.
        router.pop();
        await Future.delayed(const Duration(milliseconds: 600));
      }
    },
  );
}
