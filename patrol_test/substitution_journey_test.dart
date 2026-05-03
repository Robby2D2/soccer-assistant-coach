import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/core/router.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end substitution journey.
///
/// Mirrors the production flow a coach uses to swap a player into a
/// position mid-game: open the per-shift Assign Players screen and pick
/// a position from the dropdown next to the player's name.
///
/// Verifies:
///   1. The Assign Players route renders the present roster (and excludes
///      players marked absent in attendance).
///   2. Selecting a position from the dropdown writes a player_shifts row
///      via [setPlayerPosition].
///   3. The change is observable via [watchAssignments] (i.e. the in-memory
///      store and the Drift stream stay consistent).
void main() {
  patrolTest(
    'assigning a present player to a position writes the substitution to the DB',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      final seasonId = await db.createSeason(
        name: 'Sub Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Sub FC',
        shiftLengthSeconds: 300,
      );
      final gameId = await db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          opponent: const drift.Value('Bench Warmers'),
          gameStatus: const drift.Value('in-progress'),
        ),
      );

      // Two players — one starter (present) and one bench (absent).
      final starterId = await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              teamId: teamId,
              seasonId: seasonId,
              firstName: 'Sara',
              lastName: 'Starter',
            ),
          );
      final benchId = await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              teamId: teamId,
              seasonId: seasonId,
              firstName: 'Ben',
              lastName: 'Bench',
            ),
          );
      await db.setAttendance(
        gameId: gameId,
        playerId: starterId,
        isPresent: true,
      );
      await db.setAttendance(
        gameId: gameId,
        playerId: benchId,
        isPresent: false,
      );

      // Seed a live shift so the assign screen has something to bind to.
      final shiftId = await db.startShift(gameId, 0);

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Drive the production GoRouter into the assign-players screen for
      // this shift. This is the same URL the app generates internally and
      // exercising it via the router (not the in-memory state) keeps the
      // test honest about deep-link behavior.
      router.push('/game/$gameId/assign/$shiftId');
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Present player shows up; absent player is hidden by the screen's
      // attendance filter (covered at the DB layer in
      // `test/substitution_test.dart` — here we verify the UI honors it).
      expect($('Sara Starter'), findsOneWidget);
      expect($('Ben Bench'), findsNothing);

      // Sanity: no assignment yet for this shift.
      expect(await db.watchAssignments(shiftId).first, isEmpty);

      // Pick a position from the dropdown. The list comes from
      // `kPositions` in `assign_players_screen.dart`.
      await $(find.byType(DropdownButton<String>)).first.tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));
      await $('CENTER_FORWARD').last.tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      final assigns = await db.watchAssignments(shiftId).first;
      expect(
        assigns,
        hasLength(1),
        reason: 'Selecting a position should insert exactly one player_shifts row',
      );
      expect(assigns.single.playerId, starterId);
      expect(assigns.single.position, 'CENTER_FORWARD');
    },
  );
}
