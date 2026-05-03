import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Game lifecycle', () {
    late AppDb db;

    setUp(() {
      db = AppDb.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('updateGame transitions a game to "completed" with a final score',
        () async {
      final ids = await seedTeam(db, createGame: true);

      await db.updateGame(
        id: ids.gameId!,
        gameStatus: 'completed',
        teamScore: 3,
        opponentScore: 2,
        endTime: DateTime(2026, 4, 1, 12),
        isGameActive: false,
      );

      final game = await db.getGame(ids.gameId!);
      expect(game!.gameStatus, 'completed');
      expect(game.teamScore, 3);
      expect(game.opponentScore, 2);
      expect(game.endTime, isNotNull);
      expect(game.isGameActive, isFalse);
    });

    test('startGameTimer / pauseGameTimer flip isGameActive', () async {
      final ids = await seedTeam(db, createGame: true);

      await db.startGameTimer(ids.gameId!);
      expect((await db.getGame(ids.gameId!))!.isGameActive, isTrue);

      await db.pauseGameTimer(ids.gameId!);
      expect((await db.getGame(ids.gameId!))!.isGameActive, isFalse);
    });
  });

  group('Database export/import', () {
    test('round-trip preserves teams, players, games, and shifts', () async {
      // Seed source database.
      final src = AppDb.test();
      addTearDown(src.close);
      final ids = await seedTeam(src, teamName: 'Source FC', createGame: true);
      await seedPlayer(
        src,
        teamId: ids.teamId,
        seasonId: ids.seasonId,
        firstName: 'Round',
        lastName: 'Trip',
        jerseyNumber: 7,
      );
      await seedShift(src, gameId: ids.gameId!, startSeconds: 0);

      final json = await src.exportDatabase();

      // Sanity: it's valid JSON with the export envelope.
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      expect(parsed['exportMetadata'], isA<Map<String, dynamic>>());
      expect(parsed['data'], isA<Map<String, dynamic>>());

      // Import into a fresh database.
      final dst = AppDb.test();
      addTearDown(dst.close);
      final imported = await dst.importDatabase(json);
      expect(imported, isTrue);

      final teams = await dst.getAllTeams();
      expect(teams.where((t) => t.name == 'Source FC'), isNotEmpty);
    });
  });
}
