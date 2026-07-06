import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/fixtures.dart';

/// Covers the two queries backing the game-first team landing screen (issue #37):
/// [AppDb.watchMostRecentCompletedGame] and [AppDb.watchNextUpcomingGame].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDb db;
  late int teamId;
  late int seasonId;

  setUp(() async {
    db = AppDb.test();
    final ids = await seedTeam(db);
    teamId = ids.teamId;
    seasonId = ids.seasonId;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertGame({
    required String status,
    DateTime? startTime,
    int teamScore = 0,
    int opponentScore = 0,
    bool archived = false,
  }) {
    return db.addGame(
      GamesCompanion.insert(
        teamId: teamId,
        seasonId: seasonId,
        gameStatus: drift.Value(status),
        startTime: drift.Value(startTime),
        teamScore: drift.Value(teamScore),
        opponentScore: drift.Value(opponentScore),
        isArchived: drift.Value(archived),
      ),
    );
  }

  group('watchMostRecentCompletedGame', () {
    test('returns the latest completed game by start time', () async {
      await insertGame(
        status: 'completed',
        startTime: DateTime(2026, 4, 1),
        teamScore: 1,
        opponentScore: 0,
      );
      await insertGame(
        status: 'completed',
        startTime: DateTime(2026, 5, 1),
        teamScore: 3,
        opponentScore: 2,
      );

      final game = await db.watchMostRecentCompletedGame(teamId).first;
      expect(game, isNotNull);
      expect(game!.teamScore, 3);
      expect(game.opponentScore, 2);
      expect(game.startTime, DateTime(2026, 5, 1));
    });

    test('ignores in-progress and archived games', () async {
      await insertGame(status: 'in-progress', startTime: DateTime(2026, 6, 1));
      await insertGame(
        status: 'completed',
        startTime: DateTime(2026, 6, 2),
        archived: true,
      );

      final game = await db.watchMostRecentCompletedGame(teamId).first;
      expect(game, isNull);
    });

    test('returns null when the team has no completed games', () async {
      final game = await db.watchMostRecentCompletedGame(teamId).first;
      expect(game, isNull);
    });
  });

  group('watchNextUpcomingGame', () {
    test('returns the soonest future game that is not completed', () async {
      final later = DateTime.now().add(const Duration(days: 7));
      final sooner = DateTime.now().add(const Duration(days: 2));
      await insertGame(status: 'in-progress', startTime: later);
      final soonId = await insertGame(status: 'in-progress', startTime: sooner);

      final game = await db.watchNextUpcomingGame(teamId).first;
      expect(game, isNotNull);
      expect(game!.id, soonId);
    });

    test('ignores past, completed, cancelled, and archived games', () async {
      await insertGame(
        status: 'in-progress',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      );
      await insertGame(
        status: 'completed',
        startTime: DateTime.now().add(const Duration(days: 3)),
      );
      await insertGame(
        status: 'cancelled',
        startTime: DateTime.now().add(const Duration(days: 3)),
      );
      await insertGame(
        status: 'in-progress',
        startTime: DateTime.now().add(const Duration(days: 3)),
        archived: true,
      );

      final game = await db.watchNextUpcomingGame(teamId).first;
      expect(game, isNull);
    });

    test('returns null when there are no upcoming games', () async {
      final game = await db.watchNextUpcomingGame(teamId).first;
      expect(game, isNull);
    });
  });
}
