import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
void main() {
  patrolTest(
    'tapping Next Shift advances the current shift after confirmation',
    (PatrolIntegrationTester $) async {
      await initApp();

      // Clear stale timer state persisted by prior tests (shift_alarm runs
      // before this alphabetically and leaves timer_started_at_1 in prefs).
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
          // Active Games card on Home filters on startTime IS NOT NULL.
          startTime: drift.Value(DateTime.now()),
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

      // Navigate via the active-games card on Home.
      expect($('vs Substitutes United'), findsAtLeastNWidgets(1));
      await $('vs Substitutes United').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // The "Next Shift" control appears because there's a shift queued
      // after the current one. Tap it.
      expect($('Next Shift'), findsAtLeastNWidgets(1));
      await $('Next Shift').first.tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // Time is left on the current shift, so the confirmation dialog
      // surfaces. Confirm to advance.
      expect($('Start next shift early?'), findsOneWidget);
      await $('Start Next Shift').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // The queued shift is now current. Sanity-check both DB state and
      // that the prior shift ID is no longer the active one.
      final game = await db.getGame(gameId);
      expect(
        game?.currentShiftId,
        secondShiftId,
        reason: 'Confirming Next Shift should promote the queued shift',
      );
      expect(game?.currentShiftId, isNot(firstShiftId));
    },
  );
}
