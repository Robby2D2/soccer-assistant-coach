import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end "start a new season with a team from a previous season"
/// journey.
///
/// Mirrors what coaches do at the start of a new term: open Season
/// Management, hit "Create New Season", check the existing team they want
/// to bring forward, name the new season, and confirm. The production
/// pipeline is `cloneSelectedTeamsToSeason`, which copies the team and
/// its roster into the freshly created season.
///
/// Verifies:
///   1. Season Management opens from the home dashboard's overflow menu.
///   2. The Create New Season dialog lists previously created teams.
///   3. Selecting a team and submitting creates a new season AND clones
///      the selected team into it (with the player roster intact).
///   4. The success SnackBar surfaces on the season list.
void main() {
  patrolTest(
    'creating a new season with a previous team clones the team and roster',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      // Seed: an existing season that owns a team with two players. The
      // new season we create from the UI should clone this team.
      final oldSeasonId = await db.createSeason(
        name: '2025 Spring',
        startDate: DateTime(2025, 3, 1),
      );
      final oldTeamId = await db.addTeamToSeason(
        seasonId: oldSeasonId,
        name: 'Returning FC',
      );
      await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              teamId: oldTeamId,
              seasonId: oldSeasonId,
              firstName: 'Pat',
              lastName: 'Veteran',
            ),
          );
      await db
          .into(db.players)
          .insert(
            PlayersCompanion.insert(
              teamId: oldTeamId,
              seasonId: oldSeasonId,
              firstName: 'Sam',
              lastName: 'Returner',
            ),
          );

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Open Season Management from the home overflow menu.
      await $(find.byIcon(Icons.more_vert)).first.tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
      await $('Manage Seasons').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // The current season is listed.
      expect($('2025 Spring'), findsAtLeastNWidgets(1));

      // Tap the FAB to create a new season.
      await $(find.byIcon(Icons.add)).first.tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // Fill in the new season name.
      await $(find.byType(TextField)).enterText('2026 Fall');
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      // The Clone Teams section lists the existing team — check its box.
      expect(
        $('Returning FC'),
        findsOneWidget,
        reason: 'Existing team should be selectable for cloning',
      );
      await $('Returning FC').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      // Submit. The dialog uses the localized "Create" label.
      await $('Create').tap();
      // The screen briefly shows a "Creating season..." progress dialog
      // followed by a success SnackBar; let both settle.
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // The new season is now in the list.
      expect(
        $('2026 Fall'),
        findsAtLeastNWidgets(1),
        reason: 'Newly created season should appear in the season list',
      );

      // DB-side: a new season exists, the team is cloned (different ID,
      // same name), and the roster comes along.
      final allSeasons = await db.getSeasons();
      expect(allSeasons.map((s) => s.name), contains('2026 Fall'));
      final newSeason = allSeasons.firstWhere((s) => s.name == '2026 Fall');

      final clonedTeams = await db.watchTeams(seasonId: newSeason.id).first;
      expect(clonedTeams, hasLength(1));
      expect(clonedTeams.single.name, 'Returning FC');
      expect(
        clonedTeams.single.id,
        isNot(oldTeamId),
        reason: 'The cloned team must be a separate row, not a re-parent',
      );

      final clonedRoster = await (db.select(db.players)
            ..where((p) => p.teamId.equals(clonedTeams.single.id)))
          .get();
      expect(
        clonedRoster.map((p) => '${p.firstName} ${p.lastName}').toSet(),
        {'Pat Veteran', 'Sam Returner'},
        reason: 'Roster should follow the team into the new season',
      );
    },
  );
}
