import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/fixtures.dart';

/// watchActiveGames feeds the home screen's "Active Games" card. A game is
/// active only when it is in progress AND (its timer is running OR it is
/// scheduled for today) — a game scheduled next week is upcoming, not active.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('watchActiveGames filter', () {
    late AppDb db;
    late int seasonId;
    late int teamId;

    setUp(() async {
      db = AppDb.test();
      final ids = await seedTeam(db);
      seasonId = ids.seasonId;
      teamId = ids.teamId;
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> addGame({
      String gameStatus = 'in-progress',
      DateTime? startTime,
      bool isGameActive = false,
      bool isArchived = false,
    }) {
      return db.addGame(
        GamesCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          gameStatus: drift.Value(gameStatus),
          startTime: drift.Value(startTime),
          isGameActive: drift.Value(isGameActive),
          isArchived: drift.Value(isArchived),
        ),
      );
    }

    Future<List<int>> activeGameIds() async {
      final rows = await db.watchActiveGames().first;
      return rows.map((r) => r.game.id).toList();
    }

    test('in-progress game scheduled today is active', () async {
      final gameId = await addGame(startTime: DateTime.now());
      expect(await activeGameIds(), [gameId]);
    });

    test('in-progress game scheduled in the future is not active', () async {
      await addGame(startTime: DateTime.now().add(const Duration(days: 7)));
      expect(await activeGameIds(), isEmpty);
    });

    test('in-progress game from a past day with idle timer is not active',
        () async {
      await addGame(
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(await activeGameIds(), isEmpty);
    });

    test('game with a running timer is active regardless of startTime',
        () async {
      final noStartTime = await addGame(isGameActive: true);
      final pastDay = await addGame(
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        isGameActive: true,
      );
      expect(await activeGameIds(), containsAll([noStartTime, pastDay]));
    });

    test('completed and archived games are never active', () async {
      await addGame(gameStatus: 'completed', startTime: DateTime.now());
      await addGame(startTime: DateTime.now(), isArchived: true);
      expect(await activeGameIds(), isEmpty);
    });
  });
}
