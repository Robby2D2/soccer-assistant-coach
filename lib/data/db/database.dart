import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'schema.dart';

part 'database.g.dart';

/// Combined Game and Team data for active game views
class GameWithTeam {
  final Game game;
  final Team team;

  const GameWithTeam({required this.game, required this.team});
}

@DriftDatabase(
  tables: [
    Teams,
    Players,
    Games,
    Shifts,
    PlayerShifts,
    PlayerMetrics,
    GamePlayers,
    PlayerPositionTotals,
    Formations,
    FormationPositions,
  ],
)
class AppDb extends _$AppDb {
  AppDb()
    : super(SqfliteQueryExecutor.inDatabaseFolder(path: 'soccer_manager.db'));
  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Add team-level shift length setting (seconds), default 300
      await customStatement(
        'ALTER TABLE teams ADD COLUMN shift_length_seconds INTEGER NOT NULL DEFAULT 300',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(gamePlayers);
      }
      if (from < 3) {
        await m.addColumn(teams, teams.isArchived);
        await m.addColumn(games, games.isArchived);
      }
      if (from < 4) {
        await m.addColumn(shifts, shifts.actualSeconds);
      }
      if (from < 5) {
        await m.createTable(playerPositionTotals);
      }
      if (from < 6) {
        await m.createTable(formations);
        await m.createTable(formationPositions);
      }
      if (from < 7) {
        await customStatement(
          'ALTER TABLE teams ADD COLUMN shift_length_seconds INTEGER NOT NULL DEFAULT 300',
        );
      }
      if (from < 8) {
        await m.addColumn(teams, teams.teamMode);
        await m.addColumn(teams, teams.halfDurationSeconds);
      }
      if (from < 9) {
        await m.addColumn(games, games.currentHalf);
        await m.addColumn(games, games.gameTimeSeconds);
        await m.addColumn(games, games.isGameActive);
      }
      if (from < 10) {
        // Force rebuild for traditional mode support
        // All necessary columns should be added through the try-catch blocks above
      }
      if (from < 11) {
        await m.addColumn(games, games.formationId);
      }
    },
  );

  /// Helper method to reset database if migrations fail
  /// Use this only in development when database schema changes cause issues
  Future<void> resetDatabase() async {
    await customStatement('DROP TABLE IF EXISTS teams');
    await customStatement('DROP TABLE IF EXISTS players');
    await customStatement('DROP TABLE IF EXISTS games');
    await customStatement('DROP TABLE IF EXISTS shifts');
    await customStatement('DROP TABLE IF EXISTS player_shifts');
    await customStatement('DROP TABLE IF EXISTS player_metrics');
    await customStatement('DROP TABLE IF EXISTS game_players');
    await customStatement('DROP TABLE IF EXISTS player_position_totals');
    await customStatement('DROP TABLE IF EXISTS formations');
    await customStatement('DROP TABLE IF EXISTS formation_positions');

    // Recreate all tables with current schema
    final m = createMigrator();
    await m.createAll();
  }
}

extension TeamQueries on AppDb {
  Future<int> addTeam(TeamsCompanion t) async {
    final teamId = await into(teams).insert(t);
    // Create a default formation to help users get started
    await createDefaultFormation(teamId);
    return teamId;
  }

  Stream<List<Team>> watchTeams({bool includeArchived = false}) {
    final query = select(teams);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.watch();
  }

  Future<Team?> getTeam(int id) =>
      (select(teams)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> updateTeamName(int id, String name) => (update(
    teams,
  )..where((t) => t.id.equals(id))).write(TeamsCompanion(name: Value(name)));
  Future<void> deleteTeam(int id) =>
      (delete(teams)..where((t) => t.id.equals(id))).go();
  Future<void> setTeamArchived(int id, {required bool archived}) =>
      (update(teams)..where((t) => t.id.equals(id))).write(
        TeamsCompanion(isArchived: Value(archived)),
      );

  Future<int> getTeamShiftLengthSeconds(int teamId) async {
    final row = await customSelect(
      'SELECT COALESCE(shift_length_seconds, 300) AS sl FROM teams WHERE id = ?',
      variables: [Variable<int>(teamId)],
      readsFrom: {teams},
    ).getSingleOrNull();
    return row?.read<int>('sl') ?? 300;
  }

  Future<void> setTeamShiftLengthSeconds(int teamId, int seconds) async {
    if (seconds <= 0) seconds = 300;
    await customUpdate(
      'UPDATE teams SET shift_length_seconds = ? WHERE id = ?',
      variables: [Variable<int>(seconds), Variable<int>(teamId)],
      updates: {teams},
    );
  }

  Future<String> getTeamMode(int teamId) async {
    final row = await customSelect(
      'SELECT COALESCE(team_mode, "shift") AS tm FROM teams WHERE id = ?',
      variables: [Variable<int>(teamId)],
      readsFrom: {teams},
    ).getSingleOrNull();
    return row?.read<String>('tm') ?? 'shift';
  }

  Future<void> setTeamMode(int teamId, String mode) async {
    await customUpdate(
      'UPDATE teams SET team_mode = ? WHERE id = ?',
      variables: [Variable<String>(mode), Variable<int>(teamId)],
      updates: {teams},
    );
  }

  Future<int> getTeamHalfDurationSeconds(int teamId) async {
    final row = await customSelect(
      'SELECT COALESCE(half_duration_seconds, 1200) AS hd FROM teams WHERE id = ?',
      variables: [Variable<int>(teamId)],
      readsFrom: {teams},
    ).getSingleOrNull();
    return row?.read<int>('hd') ?? 1200;
  }

  Future<void> setTeamHalfDurationSeconds(int teamId, int seconds) async {
    if (seconds <= 0) seconds = 1200; // Default 20 minutes
    await customUpdate(
      'UPDATE teams SET half_duration_seconds = ? WHERE id = ?',
      variables: [Variable<int>(seconds), Variable<int>(teamId)],
      updates: {teams},
    );
  }
}

extension FormationQueries on AppDb {
  Future<Formation?> getFormation(int id) =>
      (select(formations)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<int> createFormation({
    required int teamId,
    required String name,
    required int playerCount,
    required List<String> positions,
  }) async {
    final formationId = await into(formations).insert(
      FormationsCompanion.insert(
        teamId: teamId,
        name: name,
        playerCount: playerCount,
      ),
    );
    for (var i = 0; i < positions.length; i++) {
      await into(formationPositions).insert(
        FormationPositionsCompanion.insert(
          formationId: formationId,
          index: i,
          positionName: positions[i],
        ),
      );
    }
    return formationId;
  }

  Future<void> updateFormation({
    required int id,
    required String name,
    required int playerCount,
    required List<String> positions,
  }) async {
    await transaction(() async {
      await (update(formations)..where((f) => f.id.equals(id))).write(
        FormationsCompanion(name: Value(name), playerCount: Value(playerCount)),
      );
      await (delete(
        formationPositions,
      )..where((fp) => fp.formationId.equals(id))).go();
      for (var i = 0; i < positions.length; i++) {
        await into(formationPositions).insert(
          FormationPositionsCompanion.insert(
            formationId: id,
            index: i,
            positionName: positions[i],
          ),
        );
      }
    });
  }

  Future<void> deleteFormation(int formationId) async {
    await (delete(
      formationPositions,
    )..where((fp) => fp.formationId.equals(formationId))).go();
    await (delete(formations)..where((f) => f.id.equals(formationId))).go();
  }

  Stream<List<Formation>> watchTeamFormations(int teamId) =>
      (select(formations)..where((f) => f.teamId.equals(teamId))).watch();

  Future<List<Formation>> getTeamFormations(int teamId) =>
      (select(formations)..where((f) => f.teamId.equals(teamId))).get();

  Future<List<FormationPosition>> getFormationPositions(int formationId) =>
      (select(formationPositions)
            ..where((fp) => fp.formationId.equals(formationId))
            ..orderBy([(fp) => OrderingTerm.asc(fp.index)]))
          .get();

  /// Heuristic: most-used formation for a team based on shift notes saved as
  /// `Formation: <name>`. Returns null if no formations exist.
  Future<int?> mostUsedFormationIdForTeam(int teamId) async {
    final list = await getTeamFormations(teamId);
    if (list.isEmpty) return null;
    int? bestId;
    int bestCount = -1;
    for (final f in list) {
      final rows = await customSelect(
        'SELECT COUNT(*) AS c FROM shifts s '
        'INNER JOIN games g ON g.id = s.game_id '
        'WHERE g.team_id = ? AND s.notes = ?',
        variables: [
          Variable<int>(teamId),
          Variable<String>('Formation: ${f.name}'),
        ],
        readsFrom: {shifts, games},
      ).get();
      final c = rows.isEmpty ? 0 : (rows.first.read<int?>('c') ?? 0);
      if (c > bestCount) {
        bestCount = c;
        bestId = f.id;
      }
    }
    return bestId;
  }

  /// Creates a default "2-2-1" formation for new teams to help users get started
  Future<int> createDefaultFormation(int teamId) async {
    return createFormation(
      teamId: teamId,
      name: '2-2-1',
      playerCount: 6,
      positions: [
        'Goalie',
        'Left Defense',
        'Right Defense',
        'Left Midfield',
        'Right Midfield',
        'Striker',
      ],
    );
  }
}

extension PlayerQueries on AppDb {
  Stream<List<Player>> watchPlayersByTeam(int teamId) =>
      (select(players)..where((p) => p.teamId.equals(teamId))).watch();
  Future<List<Player>> getPlayersByTeam(int teamId) =>
      (select(players)..where((p) => p.teamId.equals(teamId))).get();
  Future<Player?> getPlayer(int id) =>
      (select(players)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<void> updatePlayer({
    required int id,
    required String firstName,
    required String lastName,
    required bool isPresent,
  }) => (update(players)..where((p) => p.id.equals(id))).write(
    PlayersCompanion(
      firstName: Value(firstName),
      lastName: Value(lastName),
      isPresent: Value(isPresent),
    ),
  );
  Future<void> deletePlayer(int id) =>
      (delete(players)..where((p) => p.id.equals(id))).go();
}

extension GameQueries on AppDb {
  Future<int> addGame(GamesCompanion g) => into(games).insert(g);
  Stream<List<Game>> watchTeamGames(
    int teamId, {
    bool includeArchived = false,
  }) {
    final query = select(games)..where((g) => g.teamId.equals(teamId));
    if (!includeArchived) {
      query.where((g) => g.isArchived.equals(false));
    }
    return query.watch();
  }

  Future<Game?> getGame(int id) =>
      (select(games)..where((g) => g.id.equals(id))).getSingleOrNull();
  Future<void> updateGame({
    required int id,
    String? opponent,
    DateTime? startTime,
    int? formationId,
  }) => (update(games)..where((g) => g.id.equals(id))).write(
    GamesCompanion(
      opponent: opponent == null ? const Value.absent() : Value(opponent),
      startTime: startTime == null ? const Value.absent() : Value(startTime),
      formationId: formationId == null
          ? const Value.absent()
          : Value(formationId),
    ),
  );
  Future<void> deleteGame(int id) =>
      (delete(games)..where((g) => g.id.equals(id))).go();
  Future<void> setGameArchived(int id, {required bool archived}) =>
      (update(games)..where((g) => g.id.equals(id))).write(
        GamesCompanion(isArchived: Value(archived)),
      );

  // Traditional mode game management methods
  Future<void> startGameTimer(int gameId) async {
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      const GamesCompanion(isGameActive: Value(true)),
    );
  }

  Future<void> pauseGameTimer(int gameId) async {
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      const GamesCompanion(isGameActive: Value(false)),
    );
  }

  Future<void> updateGameTime(int gameId, int seconds) async {
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(gameTimeSeconds: Value(seconds)),
    );
  }

  Future<void> startSecondHalf(int gameId) async {
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      const GamesCompanion(currentHalf: Value(2), isGameActive: Value(false)),
    );
  }

  Future<void> resetGameTimer(int gameId) async {
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      const GamesCompanion(
        gameTimeSeconds: Value(0),
        isGameActive: Value(false),
        currentHalf: Value(1),
      ),
    );
  }

  /// Watch active games across all teams (games with isGameActive = true or recent active shifts)
  Stream<List<GameWithTeam>> watchActiveGames() {
    return (select(
            games,
          ).join([leftOuterJoin(teams, teams.id.equalsExp(games.teamId))])
          ..where(
            games.isGameActive.equals(true) & games.isArchived.equals(false),
          )
          ..orderBy([OrderingTerm.desc(games.startTime)]))
        .watch()
        .map(
          (rows) => rows.map((row) {
            final game = row.readTable(games);
            final team = row.readTable(teams);
            return GameWithTeam(game: game, team: team);
          }).toList(),
        );
  }

  /// Get the most recent completed game for a team (excluding current game)
  Future<Game?> getMostRecentCompletedGame(
    int teamId,
    int excludeGameId,
  ) async {
    return await (select(games)
          ..where(
            (g) =>
                g.teamId.equals(teamId) &
                g.id.equals(excludeGameId).not() &
                g.isArchived.equals(false),
          )
          ..orderBy([(g) => OrderingTerm.desc(g.startTime)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Save traditional game lineup configuration
  Future<void> saveTraditionalLineup({
    required int gameId,
    required Map<String, int> lineup, // position -> playerId
  }) async {
    // Delete any existing lineup for this game
    await (delete(playerShifts)..where(
          (ps) => ps.shiftId.equals(-gameId),
        )) // Use negative gameId as special shiftId
        .go();

    // Insert new lineup assignments
    for (final entry in lineup.entries) {
      await into(playerShifts).insert(
        PlayerShiftsCompanion.insert(
          shiftId:
              -gameId, // Use negative gameId as special identifier for traditional lineup
          playerId: entry.value,
          position: entry.key,
        ),
      );
    }
  }

  /// Get traditional game lineup from previous games
  Future<Map<String, int>?> getTraditionalLineupFromGame(int gameId) async {
    final lineupData = await (select(
      playerShifts,
    )..where((ps) => ps.shiftId.equals(-gameId))).get();

    if (lineupData.isEmpty) return null;

    final lineup = <String, int>{};
    for (final ps in lineupData) {
      lineup[ps.position] = ps.playerId;
    }
    return lineup;
  }

  /// Generate random lineup based on formation and available players
  Future<Map<String, int>> generateRandomLineup({
    required int gameId,
    required int? formationId,
  }) async {
    final lineup = <String, int>{};

    if (formationId == null) return lineup;

    // Get formation positions
    final positions = await getFormationPositions(formationId);
    if (positions.isEmpty) return lineup;

    // Get available players for this game
    final availablePlayers =
        await (select(gamePlayers)..where(
              (gp) => gp.gameId.equals(gameId) & gp.isPresent.equals(true),
            ))
            .get();

    if (availablePlayers.isEmpty) return lineup;

    // Shuffle players for random assignment
    final playerIds = availablePlayers.map((gp) => gp.playerId).toList();
    playerIds.shuffle();

    // Assign players to positions
    for (int i = 0; i < positions.length && i < playerIds.length; i++) {
      lineup[positions[i].positionName] = playerIds[i];
    }

    return lineup;
  }
}

extension ShiftQueries on AppDb {
  Future<int> startShift(int gameId, int startSeconds, {String? notes}) async {
    final id = await into(shifts).insert(
      ShiftsCompanion.insert(
        gameId: gameId,
        startSeconds: startSeconds,
        notes: Value(notes),
      ),
    );
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(currentShiftId: Value(id)),
    );
    return id;
  }

  Future<void> endShiftAt(int gameId, int endSeconds) async {
    final g = await getGame(gameId);
    if (g?.currentShiftId == null) return;

    // Flush any remaining cached position time for this shift
    await _flushPositionTimeCache(g!.currentShiftId!);

    await (update(shifts)..where((s) => s.id.equals(g.currentShiftId!))).write(
      ShiftsCompanion(endSeconds: Value(endSeconds)),
    );
  }

  Future<void> _flushPositionTimeCache(int shiftId) async {
    final cache = _positionTimeCache[shiftId];
    if (cache == null || cache.isEmpty) return;

    for (final entry in cache.entries) {
      final parts = entry.key.split('-');
      final playerId = int.parse(parts[0]);
      final position = parts
          .sublist(1)
          .join('-'); // Handle positions with dashes

      await _incrementPositionTotal(
        playerId: playerId,
        position: position,
        seconds: entry.value,
      );
    }

    // Clean up cache
    _positionTimeCache.remove(shiftId);
    _lastPositionUpdate.remove(shiftId);
  }

  // Cache for accumulated position time before batch updates
  static final Map<int, Map<String, int>> _positionTimeCache = {};
  static final Map<int, int> _lastPositionUpdate = {};

  Future<void> incrementShiftDuration(int shiftId, int seconds) async {
    if (seconds <= 0) return;

    // Always update shift duration immediately (this is fast)
    await customUpdate(
      'UPDATE shifts SET actual_seconds = actual_seconds + ? WHERE id = ?',
      variables: [Variable<int>(seconds), Variable<int>(shiftId)],
      updates: {shifts},
    );

    final totalPlayers = await (select(
      playerShifts,
    )..where((ps) => ps.shiftId.equals(shiftId))).get();

    if (totalPlayers.isEmpty) return;

    // Batch position updates: accumulate time and update every 10 seconds
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final lastUpdate = _lastPositionUpdate[shiftId] ?? now;
    final shouldUpdate = (now - lastUpdate) >= 10; // Update every 10 seconds

    // Accumulate time for each player position
    final cache = _positionTimeCache.putIfAbsent(shiftId, () => {});
    for (final assignment in totalPlayers) {
      final key = '${assignment.playerId}-${assignment.position}';
      cache[key] = (cache[key] ?? 0) + seconds;
    }

    if (shouldUpdate) {
      // Flush accumulated time to database
      for (final entry in cache.entries) {
        final parts = entry.key.split('-');
        final playerId = int.parse(parts[0]);
        final position = parts
            .sublist(1)
            .join('-'); // Handle positions with dashes

        await _incrementPositionTotal(
          playerId: playerId,
          position: position,
          seconds: entry.value,
        );
      }

      // Clear cache and update timestamp
      _positionTimeCache.remove(shiftId);
      _lastPositionUpdate[shiftId] = now;
    }
  }

  Stream<List<Shift>> watchGameShifts(int gameId) =>
      (select(shifts)..where((s) => s.gameId.equals(gameId))).watch();

  Future<Shift?> getShift(int shiftId) =>
      (select(shifts)..where((s) => s.id.equals(shiftId))).getSingleOrNull();

  Future<Shift?> nextShiftAfter(int gameId, int startSeconds) =>
      (select(shifts)
            ..where(
              (s) =>
                  s.gameId.equals(gameId) &
                  s.startSeconds.isBiggerThanValue(startSeconds),
            )
            ..orderBy([(s) => OrderingTerm.asc(s.startSeconds)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> updateShiftStartSeconds(int shiftId, int startSeconds) async {
    await (update(shifts)..where((s) => s.id.equals(shiftId))).write(
      ShiftsCompanion(startSeconds: Value(startSeconds)),
    );
  }

  Stream<Shift?> watchActiveShift(int gameId) =>
      (select(shifts)
            ..where((s) => s.gameId.equals(gameId) & s.endSeconds.isNull())
            ..orderBy([(s) => OrderingTerm.desc(s.id)]))
          .watchSingleOrNull();
}

extension PlayerShiftQueries on AppDb {
  Future<void> setPlayerPosition({
    required int shiftId,
    required int playerId,
    required String position,
  }) async {
    await (delete(playerShifts)..where(
          (ps) => ps.shiftId.equals(shiftId) & ps.playerId.equals(playerId),
        ))
        .go();
    await into(playerShifts).insert(
      PlayerShiftsCompanion.insert(
        shiftId: shiftId,
        playerId: playerId,
        position: position,
      ),
    );
  }

  Stream<List<PlayerShift>> watchAssignments(int shiftId) =>
      (select(playerShifts)..where((ps) => ps.shiftId.equals(shiftId))).watch();

  Future<List<PlayerShift>> getAssignments(int shiftId) =>
      (select(playerShifts)..where((ps) => ps.shiftId.equals(shiftId))).get();
}

// Traditional mode playing time tracking
extension TraditionalModeQueries on AppDb {
  // Track individual playing time sessions for traditional mode
  Future<void> updateTraditionalPlayingTime({
    required int gameId,
    required int playerId,
    required String position,
    required int seconds,
  }) async {
    // Update position totals for this session
    await _incrementPositionTotal(
      playerId: playerId,
      position: position,
      seconds: seconds,
    );

    // Create or update player metric for this game session
    final existing =
        await (select(playerMetrics)..where(
              (m) =>
                  m.gameId.equals(gameId) &
                  m.playerId.equals(playerId) &
                  m.metric.equals('traditional_playing_time'),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await into(playerMetrics).insert(
        PlayerMetricsCompanion.insert(
          gameId: gameId,
          playerId: playerId,
          metric: 'traditional_playing_time',
          value: Value(seconds),
        ),
      );
    } else {
      await (update(
        playerMetrics,
      )..where((m) => m.id.equals(existing.id))).write(
        PlayerMetricsCompanion(value: Value(existing.value + seconds)),
      );
    }
  }

  Future<Map<int, int>> getTraditionalPlayingTimeByPlayer(int gameId) async {
    final result =
        await (select(playerMetrics)..where(
              (m) =>
                  m.gameId.equals(gameId) &
                  m.metric.equals('traditional_playing_time'),
            ))
            .get();

    final map = <int, int>{};
    for (final metric in result) {
      map[metric.playerId] = metric.value;
    }
    return map;
  }

  Stream<Map<int, int>> watchTraditionalPlayingTimeByPlayer(int gameId) {
    final query = select(playerMetrics)
      ..where(
        (m) =>
            m.gameId.equals(gameId) &
            m.metric.equals('traditional_playing_time'),
      );
    return query.watch().map((metrics) {
      final map = <int, int>{};
      for (final metric in metrics) {
        map[metric.playerId] = metric.value;
      }
      return map;
    });
  }
}

extension PlayerMetricQueries on AppDb {
  Future<void> incrementMetric({
    required int gameId,
    required int playerId,
    required String metric,
  }) async {
    final existing =
        await (select(playerMetrics)..where(
              (m) =>
                  m.gameId.equals(gameId) &
                  m.playerId.equals(playerId) &
                  m.metric.equals(metric),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await into(playerMetrics).insert(
        PlayerMetricsCompanion.insert(
          gameId: gameId,
          playerId: playerId,
          metric: metric,
          value: const Value(1),
        ),
      );
    } else {
      await (update(playerMetrics)..where((m) => m.id.equals(existing.id)))
          .write(PlayerMetricsCompanion(value: Value(existing.value + 1)));
    }
  }

  Stream<List<PlayerMetric>> watchMetricsForGame(int gameId) =>
      (select(playerMetrics)..where((m) => m.gameId.equals(gameId))).watch();

  Future<Map<int, int>> playedSecondsByPlayer(int gameId) async {
    final result = await customSelect(
      'SELECT ps.player_id AS playerId, SUM(s.actual_seconds) AS totalSeconds '
      'FROM player_shifts ps '
      'INNER JOIN shifts s ON s.id = ps.shift_id '
      'WHERE s.game_id = ? '
      'GROUP BY ps.player_id',
      variables: [Variable<int>(gameId)],
      readsFrom: {playerShifts, shifts},
    ).get();
    final map = <int, int>{};
    for (final row in result) {
      final playerId = row.read<int>('playerId');
      final total = row.read<int?>('totalSeconds') ?? 0;
      map[playerId] = total;
    }
    return map;
  }

  Stream<Map<int, int>> watchPlayedSecondsByPlayer(int gameId) {
    final query = customSelect(
      'SELECT ps.player_id AS playerId, SUM(s.actual_seconds) AS totalSeconds '
      'FROM player_shifts ps '
      'INNER JOIN shifts s ON s.id = ps.shift_id '
      'WHERE s.game_id = ? '
      'GROUP BY ps.player_id',
      variables: [Variable<int>(gameId)],
      readsFrom: {playerShifts, shifts},
    );
    return query.watch().map((rows) {
      final map = <int, int>{};
      for (final row in rows) {
        final playerId = row.read<int>('playerId');
        final total = row.read<int?>('totalSeconds') ?? 0;
        map[playerId] = total;
      }
      return map;
    });
  }
}

extension AttendanceQueries on AppDb {
  Future<void> setAttendance({
    required int gameId,
    required int playerId,
    required bool isPresent,
  }) async {
    final existing =
        await (select(gamePlayers)..where(
              (gp) => gp.gameId.equals(gameId) & gp.playerId.equals(playerId),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await into(gamePlayers).insert(
        GamePlayersCompanion.insert(
          gameId: gameId,
          playerId: playerId,
          isPresent: Value(isPresent),
        ),
      );
    } else {
      await (update(gamePlayers)..where((gp) => gp.id.equals(existing.id)))
          .write(GamePlayersCompanion(isPresent: Value(isPresent)));
    }

    if (!isPresent) {
      final shiftRows = await (select(
        shifts,
      )..where((s) => s.gameId.equals(gameId))).get();
      if (shiftRows.isNotEmpty) {
        final shiftIds = shiftRows.map((s) => s.id).toList();
        await (delete(playerShifts)..where(
              (ps) => ps.playerId.equals(playerId) & ps.shiftId.isIn(shiftIds),
            ))
            .go();
      }
    }
  }

  Stream<List<GamePlayer>> watchAttendance(int gameId) =>
      (select(gamePlayers)..where((gp) => gp.gameId.equals(gameId))).watch();

  Future<List<Player>> presentPlayersForGame(int gameId, int teamId) async {
    final attendance =
        await (select(gamePlayers)..where(
              (gp) => gp.gameId.equals(gameId) & gp.isPresent.equals(true),
            ))
            .get();
    if (attendance.isEmpty) {
      return (select(players)
            ..where((p) => p.teamId.equals(teamId) & p.isPresent.equals(true)))
          .get();
    }
    final ids = attendance.map((a) => a.playerId).toList();
    return (select(
      players,
    )..where((p) => p.teamId.equals(teamId) & p.id.isIn(ids))).get();
  }

  Future<bool> hasPresentPlayersForGame(int gameId) async {
    final row =
        await (select(gamePlayers)
              ..where(
                (gp) => gp.gameId.equals(gameId) & gp.isPresent.equals(true),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}

extension _PositionTotals on AppDb {
  Future<void> _incrementPositionTotal({
    required int playerId,
    required String position,
    required int seconds,
  }) async {
    await into(playerPositionTotals).insert(
      PlayerPositionTotalsCompanion.insert(
        playerId: playerId,
        position: position,
        totalSeconds: const Value(0),
      ),
      mode: InsertMode.insertOrIgnore,
    );

    await customUpdate(
      'UPDATE player_position_totals '
      'SET total_seconds = total_seconds + ? '
      'WHERE player_id = ? AND position = ?',
      variables: [
        Variable<int>(seconds),
        Variable<int>(playerId),
        Variable<String>(position),
      ],
    );
  }
}

extension AutoRotation on AppDb {
  Future<int> _shiftCount(int gameId) async {
    final res = await (select(
      shifts,
    )..where((s) => s.gameId.equals(gameId))).get();
    return res.length;
  }

  Future<int> _teamShiftCount(int teamId) async {
    final res = await customSelect(
      'SELECT COUNT(*) as count FROM shifts s '
      'INNER JOIN games g ON g.id = s.game_id '
      'WHERE g.team_id = ?',
      variables: [Variable<int>(teamId)],
      readsFrom: {shifts, games},
    ).getSingle();
    return res.read<int>('count');
  }

  Future<Map<int, int>> _totalPlayedSecondsByPlayer(int teamId) async {
    final result = await customSelect(
      'SELECT ps.player_id AS playerId, SUM(s.actual_seconds) AS totalSeconds '
      'FROM player_shifts ps '
      'INNER JOIN shifts s ON s.id = ps.shift_id '
      'INNER JOIN games g ON g.id = s.game_id '
      'WHERE g.team_id = ? '
      'GROUP BY ps.player_id',
      variables: [Variable<int>(teamId)],
      readsFrom: {playerShifts, shifts, games},
    ).get();
    final map = <int, int>{};
    for (final row in result) {
      final playerId = row.read<int>('playerId');
      final total = row.read<int?>('totalSeconds') ?? 0;
      map[playerId] = total;
    }
    return map;
  }

  Future<int> createAutoShift({
    required int gameId,
    required int startSeconds,
    required List<String> positions,
    bool activate = true,
    bool forceReassign = false,
  }) async {
    final game = await getGame(gameId);
    if (game == null) throw Exception('Game $gameId not found');

    final existing =
        await (select(shifts)
              ..where(
                (s) =>
                    s.gameId.equals(gameId) &
                    s.startSeconds.equals(startSeconds),
              )
              ..orderBy([(s) => OrderingTerm.asc(s.id)])
              ..limit(1))
            .getSingleOrNull();

    if (activate) {
      await endShiftAt(gameId, startSeconds);
    }

    final totalShifts = await _shiftCount(gameId);
    final present = await presentPlayersForGame(gameId, game.teamId);
    var players = List.of(present);

    int shiftId;
    // Use team-wide shift count for better rotation across games
    final teamShiftCount = await _teamShiftCount(game.teamId);
    final sequenceIndex = existing != null ? (totalShifts - 1) : teamShiftCount;

    if (existing != null) {
      shiftId = existing.id;
      if (activate) {
        await (update(shifts)..where((s) => s.id.equals(shiftId))).write(
          const ShiftsCompanion(actualSeconds: Value(0)),
        );
        await (update(games)..where((g) => g.id.equals(gameId))).write(
          GamesCompanion(currentShiftId: Value(shiftId)),
        );
      }
    } else {
      if (activate) {
        shiftId = await startShift(
          gameId,
          startSeconds,
          notes: 'Auto #${sequenceIndex + 1}',
        );
      } else {
        shiftId = await into(shifts).insert(
          ShiftsCompanion.insert(
            gameId: gameId,
            startSeconds: startSeconds,
            notes: Value('Auto #${sequenceIndex + 1}'),
            actualSeconds: const Value(0),
          ),
        );
      }
    }

    if (players.isEmpty) return shiftId;

    final existingAssignments = await getAssignments(shiftId);
    if (existingAssignments.isNotEmpty) {
      if (!forceReassign) {
        return shiftId;
      }
      await (delete(
        playerShifts,
      )..where((ps) => ps.shiftId.equals(shiftId))).go();
    }

    // Get playing time from current game
    final currentGamePlayedSeconds = await playedSecondsByPlayer(gameId);

    // Get total playing time across all games for better fairness
    final totalPlayedSeconds = await _totalPlayedSecondsByPlayer(game.teamId);

    // Combine current game + historical data for better fairness decisions
    final playedSeconds = <int, int>{};
    for (final player in players) {
      final currentGame = currentGamePlayedSeconds[player.id] ?? 0;
      final historical = totalPlayedSeconds[player.id] ?? 0;
      final total = currentGame + historical;
      playedSeconds[player.id] = total;
    }

    final positionTotalsRows =
        await (select(playerPositionTotals)..where(
              (ppt) => ppt.playerId.isIn(players.map((p) => p.id).toList()),
            ))
            .get();
    final totalsByPlayer = <int, Map<String, int>>{};
    for (final row in positionTotalsRows) {
      totalsByPlayer.putIfAbsent(
        row.playerId,
        () => <String, int>{},
      )[row.position] = row.totalSeconds;
    }
    final lastStartsRows = await customSelect(
      'SELECT ps.player_id AS playerId, MAX(s.start_seconds) AS lastStart '
      'FROM player_shifts ps '
      'INNER JOIN shifts s ON s.id = ps.shift_id '
      'WHERE s.game_id = ? '
      'GROUP BY ps.player_id',
      variables: [Variable<int>(gameId)],
      readsFrom: {playerShifts, shifts},
    ).get();
    final lastStarts = <int, int>{
      for (final row in lastStartsRows)
        row.read<int>('playerId'): row.read<int?>('lastStart') ?? -1,
    };

    final previousShift =
        await (select(shifts)
              ..where(
                (s) =>
                    s.gameId.equals(gameId) &
                    s.startSeconds.isSmallerThanValue(startSeconds),
              )
              ..orderBy([(s) => OrderingTerm.desc(s.startSeconds)])
              ..limit(1))
            .getSingleOrNull();
    final previousShiftPlayers = <int>{};
    final lastPositionByPlayer = <int, String>{};
    if (previousShift != null) {
      final prevAssignments = await getAssignments(previousShift.id);
      for (final assignment in prevAssignments) {
        previousShiftPlayers.add(assignment.playerId);
        lastPositionByPlayer[assignment.playerId] = assignment.position;
      }
    }

    // Assume players in the previous shift will have played one full shift
    // by the time the next shift starts. This helps avoid back-to-back
    // assignments when creating the upcoming shift before real time elapses.
    if (previousShift != null) {
      final assumedShiftSeconds = await getTeamShiftLengthSeconds(game.teamId);

      for (final id in previousShiftPlayers) {
        final currentTime = playedSeconds[id] ?? 0;
        final assumedTime = currentTime + assumedShiftSeconds;
        // Only apply the assumption if the previous shift hasn't been fully recorded yet
        // This prevents double-counting when shifts are created after timers update
        if (previousShift.actualSeconds < assumedShiftSeconds) {
          playedSeconds[id] = assumedTime;
        }
      }
    }

    final benchSeconds = playedSeconds.values
        .where((value) => value > 0)
        .toList();
    if (benchSeconds.isNotEmpty) {
      final averageSeconds =
          benchSeconds.reduce((a, b) => a + b) ~/ benchSeconds.length;
      for (final player in players) {
        final current = playedSeconds[player.id] ?? 0;
        if (current == 0) {
          playedSeconds[player.id] = averageSeconds;
        }
      }
    }

    // Hard avoid back-to-back if we have enough players to fill all positions.
    final slots = positions.length;
    final nonBackToBack = players
        .where((p) => !previousShiftPlayers.contains(p.id))
        .toList();
    if (nonBackToBack.length >= slots) {
      players = nonBackToBack;
    }

    players.sort((a, b) {
      final secondsA = playedSeconds[a.id] ?? 0;
      final secondsB = playedSeconds[b.id] ?? 0;
      if (secondsA != secondsB) {
        return secondsA.compareTo(secondsB);
      }
      final totalsA = totalsByPlayer[a.id] ?? const {};
      final totalsB = totalsByPlayer[b.id] ?? const {};
      final minTotalA = _minPositionTotals(totalsA, positions);
      final minTotalB = _minPositionTotals(totalsB, positions);
      if (minTotalA != minTotalB) {
        return minTotalA.compareTo(minTotalB);
      }
      final wasInPrevA = previousShiftPlayers.contains(a.id);
      final wasInPrevB = previousShiftPlayers.contains(b.id);
      if (wasInPrevA != wasInPrevB) {
        return wasInPrevA ? 1 : -1;
      }
      final lastStartA = lastStarts[a.id] ?? -1;
      final lastStartB = lastStarts[b.id] ?? -1;
      if (lastStartA != lastStartB) {
        return lastStartA.compareTo(lastStartB);
      }
      return a.id.compareTo(b.id);
    });

    final n = positions.length;
    final selected = players.take(n).toList();
    if (selected.isEmpty) return shiftId;

    final rotation = selected.length <= 1 ? 0 : sequenceIndex % selected.length;

    final ordered = rotation == 0
        ? selected
        : [...selected.sublist(rotation), ...selected.sublist(0, rotation)];

    final totalsSnapshot = Map<int, Map<String, int>>.fromEntries(
      totalsByPlayer.entries.map(
        (entry) => MapEntry(entry.key, Map<String, int>.from(entry.value)),
      ),
    );

    for (var i = 0; i < n && i < ordered.length; i++) {
      final desiredPosition = positions[i];

      if (lastPositionByPlayer[ordered[i].id] == desiredPosition) {
        for (var j = i + 1; j < ordered.length; j++) {
          if (lastPositionByPlayer[ordered[j].id] != desiredPosition) {
            final swap = ordered[j];
            ordered[j] = ordered[i];
            ordered[i] = swap;
            break;
          }
        }
      }

      final totals = totalsSnapshot.putIfAbsent(
        ordered[i].id,
        () => <String, int>{},
      );
      totals.update(desiredPosition, (value) => value + 1, ifAbsent: () => 1);
      await setPlayerPosition(
        shiftId: shiftId,
        playerId: ordered[i].id,
        position: positions[i],
      );
    }
    return shiftId;
  }

  Future<void> removePlayerFromShift({
    required int shiftId,
    required int playerId,
    required String position,
    required int gameId,
    required int startSeconds,
  }) async {
    final game = await getGame(gameId);
    if (game == null) return;

    final existingAssignment =
        await (select(playerShifts)..where(
              (ps) => ps.shiftId.equals(shiftId) & ps.playerId.equals(playerId),
            ))
            .getSingleOrNull();
    if (existingAssignment == null) return;

    await (delete(playerShifts)..where(
          (ps) => ps.shiftId.equals(shiftId) & ps.playerId.equals(playerId),
        ))
        .go();

    final currentAssignments = await getAssignments(shiftId);
    final excludedPlayerIds = currentAssignments.map((a) => a.playerId).toSet()
      ..add(playerId);

    final replacementId = await _selectReplacementPlayer(
      gameId: gameId,
      teamId: game.teamId,
      startSeconds: startSeconds,
      position: position,
      excludedPlayerIds: excludedPlayerIds,
    );

    if (replacementId != null) {
      await setPlayerPosition(
        shiftId: shiftId,
        playerId: replacementId,
        position: position,
      );
    }
  }

  Future<int?> _selectReplacementPlayer({
    required int gameId,
    required int teamId,
    required int startSeconds,
    required String position,
    required Set<int> excludedPlayerIds,
  }) async {
    final candidates = (await presentPlayersForGame(
      gameId,
      teamId,
    )).where((player) => !excludedPlayerIds.contains(player.id)).toList();
    if (candidates.isEmpty) return null;

    final playedSeconds = await playedSecondsByPlayer(gameId);
    final totalsRows =
        await (select(playerPositionTotals)..where(
              (ppt) => ppt.playerId.isIn(candidates.map((p) => p.id).toList()),
            ))
            .get();
    final totalsByPlayer = <int, Map<String, int>>{};
    for (final row in totalsRows) {
      totalsByPlayer.putIfAbsent(
        row.playerId,
        () => <String, int>{},
      )[row.position] = row.totalSeconds;
    }

    final lastStartsRows = await customSelect(
      'SELECT ps.player_id AS playerId, MAX(s.start_seconds) AS lastStart '
      'FROM player_shifts ps '
      'INNER JOIN shifts s ON s.id = ps.shift_id '
      'WHERE s.game_id = ? '
      'GROUP BY ps.player_id',
      variables: [Variable<int>(gameId)],
      readsFrom: {playerShifts, shifts},
    ).get();
    final lastStarts = <int, int>{
      for (final row in lastStartsRows)
        row.read<int>('playerId'): row.read<int?>('lastStart') ?? -1,
    };

    final previousShift =
        await (select(shifts)
              ..where(
                (s) =>
                    s.gameId.equals(gameId) &
                    s.startSeconds.isSmallerThanValue(startSeconds),
              )
              ..orderBy([(s) => OrderingTerm.desc(s.startSeconds)])
              ..limit(1))
            .getSingleOrNull();
    final lastPositionByPlayer = <int, String>{};
    if (previousShift != null) {
      final prevAssignments = await getAssignments(previousShift.id);
      for (final assignment in prevAssignments) {
        lastPositionByPlayer[assignment.playerId] = assignment.position;
      }
    }

    final nonZeroMinutes = playedSeconds.values
        .where((value) => value > 0)
        .toList();
    if (nonZeroMinutes.isNotEmpty) {
      final average =
          nonZeroMinutes.reduce((a, b) => a + b) ~/ nonZeroMinutes.length;
      for (final player in candidates) {
        final current = playedSeconds[player.id] ?? 0;
        if (current == 0) {
          playedSeconds[player.id] = average;
        }
      }
    }

    candidates.sort((a, b) {
      final secondsA = playedSeconds[a.id] ?? 0;
      final secondsB = playedSeconds[b.id] ?? 0;
      if (secondsA != secondsB) {
        return secondsA.compareTo(secondsB);
      }
      final totalsA = totalsByPlayer[a.id] ?? const {};
      final totalsB = totalsByPlayer[b.id] ?? const {};
      final positionTimeA = totalsA[position] ?? 0;
      final positionTimeB = totalsB[position] ?? 0;
      if (positionTimeA != positionTimeB) {
        return positionTimeA.compareTo(positionTimeB);
      }
      final lastPosA = lastPositionByPlayer[a.id];
      final lastPosB = lastPositionByPlayer[b.id];
      if ((lastPosA == position) != (lastPosB == position)) {
        return lastPosA == position ? 1 : -1;
      }
      final lastStartA = lastStarts[a.id] ?? -1;
      final lastStartB = lastStarts[b.id] ?? -1;
      if (lastStartA != lastStartB) {
        return lastStartA.compareTo(lastStartB);
      }
      return a.id.compareTo(b.id);
    });

    return candidates.first.id;
  }
}

int _minPositionTotals(Map<String, int> totals, List<String> positions) {
  if (totals.isEmpty) return 0;
  var min = totals.values.first;
  for (final pos in positions) {
    final value = totals[pos];
    if (value == null) {
      return 0;
    }
    if (value < min) {
      min = value;
    }
  }
  return min;
}
