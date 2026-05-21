import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/core/router.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end roster CSV import journey.
///
/// Drives the paste-text path (the file-picker button opens the OS file
/// chooser which cannot be driven in a headless emulator test). The paste
/// path exercises the same diff → confirmation → write pipeline as the
/// file-upload path, so this gives full coverage of the business logic
/// through the UI.
///
/// Seed state:
///   • Jane Doe  #10  — present in CSV unchanged → no change
///   • John Smith #5  — present in CSV with new jersey #99 → update
///   • Alex Johnson #7 — absent from CSV → archive (isPresent = false)
///
/// CSV being imported:
///   Jane Doe    #10  (no-op)
///   John Smith  #99  (jersey update)
///   New Player  #1   (add)
///
/// Expected after import:
///   • Jane Doe    active, jersey 10   (unchanged)
///   • John Smith  active, jersey 99   (updated)
///   • Alex Johnson  isPresent = false (archived)
///   • New Player  active, jersey 1    (added)
void main() {
  patrolTest(
    'roster CSV import adds, updates, and archives players via paste input',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      final seasonId = await db.createSeason(
        name: 'Import Season',
        startDate: DateTime.now(),
      );
      final teamId = await db.addTeamToSeason(
        seasonId: seasonId,
        name: 'Import FC',
      );

      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'Jane',
          lastName: 'Doe',
          jerseyNumber: const drift.Value(10),
        ),
      );
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'John',
          lastName: 'Smith',
          jerseyNumber: const drift.Value(5),
        ),
      );
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: 'Alex',
          lastName: 'Johnson',
          jerseyNumber: const drift.Value(7),
        ),
      );

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Navigate directly to the import screen via the production GoRouter.
      router.push('/team/$teamId/players/import');
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Paste CSV text into the text area.
      const csv =
          'firstName,lastName,jerseyNumber\nJane,Doe,10\nJohn,Smith,99\nNew,Player,1';
      await $(find.byType(TextField)).first.enterText(csv);
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // Preview should show 3 rows.
      expect($('Preview: 3 rows'), findsOneWidget);

      // Tap the Review & Import button.
      await $('Review & Import').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Confirmation dialog is showing.
      expect($('Confirm import'), findsOneWidget);

      // Verify the dialog surfaces the expected action summary.
      expect($('Add 1 players'), findsOneWidget);
      expect($('Update 1 players (jersey number)'), findsOneWidget);
      expect($('Archive 1 players (no longer in roster)'), findsOneWidget);

      // Confirm the import.
      await $('Import').tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // DB-side assertions — the screen pops on success, so we check the DB
      // directly rather than relying on UI state.
      final all = await db.getPlayersByTeam(teamId, seasonId: seasonId);

      final jane = all.firstWhere((p) => p.firstName == 'Jane');
      expect(jane.jerseyNumber, 10, reason: 'Jane should be unchanged');
      expect(jane.isPresent, isTrue);

      final john = all.firstWhere((p) => p.firstName == 'John');
      expect(
        john.jerseyNumber,
        99,
        reason: 'John jersey should be updated from 5 to 99',
      );
      expect(john.isPresent, isTrue);

      final alex = all.firstWhere((p) => p.firstName == 'Alex');
      expect(
        alex.isPresent,
        isFalse,
        reason: 'Alex should be archived (not in CSV)',
      );

      final newPlayer = all.firstWhere((p) => p.firstName == 'New');
      expect(newPlayer.jerseyNumber, 1);
      expect(newPlayer.isPresent, isTrue);
    },
  );
}
