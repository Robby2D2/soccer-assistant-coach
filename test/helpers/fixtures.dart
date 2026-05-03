import 'package:drift/drift.dart' as drift;
import 'package:soccer_assistant_coach/data/db/database.dart';

/// Minimal fixture builder for tests that need a season + team + (optional)
/// game + players. Returns the IDs as a record for ergonomic destructuring.
///
/// Defaults match production defaults except [shiftLengthSeconds], which
/// callers usually want to override (e.g. to 3 seconds for fast E2E shift
/// alarm tests).
Future<({int seasonId, int teamId, int? gameId})> seedTeam(
  AppDb db, {
  String seasonName = 'Test Season',
  String teamName = 'Test FC',
  String teamMode = 'shift',
  int shiftLengthSeconds = 300,
  int halfDurationSeconds = 1200,
  bool createGame = false,
  String gameStatus = 'in-progress',
  String? opponent,
}) async {
  final seasonId = await db.createSeason(
    name: seasonName,
    startDate: DateTime.now(),
  );
  final teamId = await db.addTeamToSeason(
    seasonId: seasonId,
    name: teamName,
    teamMode: teamMode,
    shiftLengthSeconds: shiftLengthSeconds,
    halfDurationSeconds: halfDurationSeconds,
  );
  int? gameId;
  if (createGame) {
    gameId = await db.addGame(
      GamesCompanion.insert(
        teamId: teamId,
        seasonId: seasonId,
        opponent: drift.Value(opponent),
        gameStatus: drift.Value(gameStatus),
      ),
    );
  }
  return (seasonId: seasonId, teamId: teamId, gameId: gameId);
}

/// Inserts a player onto the team and returns the player ID.
Future<int> seedPlayer(
  AppDb db, {
  required int teamId,
  required int seasonId,
  required String firstName,
  required String lastName,
  int? jerseyNumber,
  bool isPresent = true,
}) async {
  return db
      .into(db.players)
      .insert(
        PlayersCompanion.insert(
          teamId: teamId,
          seasonId: seasonId,
          firstName: firstName,
          lastName: lastName,
          jerseyNumber: drift.Value(jerseyNumber),
          isPresent: drift.Value(isPresent),
        ),
      );
}

/// Creates a shift on the game starting at [startSeconds]. Defaults to a
/// shift starting at zero with no end time (live shift).
Future<int> seedShift(
  AppDb db, {
  required int gameId,
  int startSeconds = 0,
  int? endSeconds,
}) async {
  return db
      .into(db.shifts)
      .insert(
        ShiftsCompanion.insert(
          gameId: gameId,
          startSeconds: startSeconds,
          endSeconds: drift.Value(endSeconds),
        ),
      );
}
