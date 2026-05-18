import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/utils/roster_diff.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/fixtures.dart';

void main() {
  late AppDb db;

  setUp(() => db = AppDb.test());
  tearDown(() => db.close());

  Future<List<Player>> players(int teamId, int seasonId) =>
      db.getPlayersByTeam(teamId, seasonId: seasonId);

  group('diffRoster', () {
    test('adds new players from CSV not in DB', () async {
      final (:teamId, :seasonId, gameId: _) = await seedTeam(db);
      final existing = await players(teamId, seasonId);

      final diff = diffRoster(existing, [
        {'firstName': 'Jane', 'lastName': 'Doe', 'jerseyNumber': '10'},
        {'firstName': 'John', 'lastName': 'Smith', 'jerseyNumber': ''},
      ]);

      expect(diff.toAdd.length, 2);
      expect(diff.toUpdate, isEmpty);
      expect(diff.toArchive, isEmpty);
      expect(diff.hasChanges, isTrue);
    });

    test('updates player with changed jersey number', () async {
      final (:teamId, :seasonId, gameId: _) = await seedTeam(db);
      await seedPlayer(
        db,
        teamId: teamId,
        seasonId: seasonId,
        firstName: 'Jane',
        lastName: 'Doe',
        jerseyNumber: 10,
      );
      final existing = await players(teamId, seasonId);

      final diff = diffRoster(existing, [
        {'firstName': 'Jane', 'lastName': 'Doe', 'jerseyNumber': '99'},
      ]);

      expect(diff.toAdd, isEmpty);
      expect(diff.toUpdate.length, 1);
      expect(diff.toUpdate.first.csvRow['jerseyNumber'], '99');
      expect(diff.toArchive, isEmpty);
    });

    test('archives active player not present in CSV', () async {
      final (:teamId, :seasonId, gameId: _) = await seedTeam(db);
      await seedPlayer(
        db,
        teamId: teamId,
        seasonId: seasonId,
        firstName: 'Jane',
        lastName: 'Doe',
      );
      final existing = await players(teamId, seasonId);

      final diff = diffRoster(existing, [
        {'firstName': 'John', 'lastName': 'Smith', 'jerseyNumber': ''},
      ]);

      expect(diff.toAdd.length, 1);
      expect(diff.toUpdate, isEmpty);
      expect(diff.toArchive.length, 1);
      expect(diff.toArchive.first.firstName, 'Jane');
    });

    test('does not archive already-inactive players', () async {
      final (:teamId, :seasonId, gameId: _) = await seedTeam(db);
      await seedPlayer(
        db,
        teamId: teamId,
        seasonId: seasonId,
        firstName: 'Jane',
        lastName: 'Doe',
        isPresent: false,
      );
      final existing = await players(teamId, seasonId);

      final diff = diffRoster(existing, []);

      expect(diff.toArchive, isEmpty);
    });

    test('detects no changes when CSV matches DB exactly', () async {
      final (:teamId, :seasonId, gameId: _) = await seedTeam(db);
      await seedPlayer(
        db,
        teamId: teamId,
        seasonId: seasonId,
        firstName: 'Jane',
        lastName: 'Doe',
        jerseyNumber: 10,
      );
      final existing = await players(teamId, seasonId);

      final diff = diffRoster(existing, [
        {'firstName': 'Jane', 'lastName': 'Doe', 'jerseyNumber': '10'},
      ]);

      expect(diff.hasChanges, isFalse);
    });

    test('matching is case-insensitive', () async {
      final (:teamId, :seasonId, gameId: _) = await seedTeam(db);
      await seedPlayer(
        db,
        teamId: teamId,
        seasonId: seasonId,
        firstName: 'Jane',
        lastName: 'Doe',
        jerseyNumber: 10,
      );
      final existing = await players(teamId, seasonId);

      final diff = diffRoster(existing, [
        {'firstName': 'JANE', 'lastName': 'DOE', 'jerseyNumber': '10'},
      ]);

      expect(diff.hasChanges, isFalse);
    });

    test('re-activates archived player found in CSV', () async {
      final (:teamId, :seasonId, gameId: _) = await seedTeam(db);
      await seedPlayer(
        db,
        teamId: teamId,
        seasonId: seasonId,
        firstName: 'Jane',
        lastName: 'Doe',
        jerseyNumber: 10,
        isPresent: false,
      );
      final existing = await players(teamId, seasonId);

      final diff = diffRoster(existing, [
        {'firstName': 'Jane', 'lastName': 'Doe', 'jerseyNumber': '10'},
      ]);

      expect(diff.toUpdate.length, 1);
      expect(diff.toAdd, isEmpty);
      expect(diff.toArchive, isEmpty);
    });
  });
}
