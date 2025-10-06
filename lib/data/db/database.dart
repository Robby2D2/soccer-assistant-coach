import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'schema.dart';

part 'database.g.dart';

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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
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
    },
  );
}

extension TeamQueries on AppDb {
  Future<int> addTeam(TeamsCompanion t) => into(teams).insert(t);
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
}

extension FormationQueries on AppDb {
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

  Future<void> deleteFormation(int formationId) async {
    await (delete(formationPositions)
          ..where((fp) => fp.formationId.equals(formationId)))
        .go();
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
  }) => (update(games)..where((g) => g.id.equals(id))).write(
    GamesCompanion(
      opponent: opponent == null ? const Value.absent() : Value(opponent),
      startTime: startTime == null ? const Value.absent() : Value(startTime),
    ),
  );
  Future<void> deleteGame(int id) =>
      (delete(games)..where((g) => g.id.equals(id))).go();
  Future<void> setGameArchived(int id, {required bool archived}) =>
      (update(games)..where((g) => g.id.equals(id))).write(
        GamesCompanion(isArchived: Value(archived)),
      );
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
    await (update(shifts)..where((s) => s.id.equals(g!.currentShiftId!))).write(
      ShiftsCompanion(endSeconds: Value(endSeconds)),
    );
  }

  Future<void> incrementShiftDuration(int shiftId, int seconds) async {
    if (seconds <= 0) return;
    await customUpdate(
      'UPDATE shifts SET actual_seconds = actual_seconds + ? WHERE id = ?',
      variables: [Variable<int>(seconds), Variable<int>(shiftId)],
      updates: {shifts},
    );

    final totalPlayers = await (select(
      playerShifts,
    )..where((ps) => ps.shiftId.equals(shiftId))).get();
    if (totalPlayers.isEmpty) return;
    final increment = seconds ~/ totalPlayers.length;
    if (increment <= 0) return;
    for (final assignment in totalPlayers) {
      await _incrementPositionTotal(
        playerId: assignment.playerId,
        position: assignment.position,
        seconds: increment,
      );
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
    final players = List.of(present);

    int shiftId;
    final sequenceIndex = existing != null ? (totalShifts - 1) : totalShifts;

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

    final playedSeconds = await playedSecondsByPlayer(gameId);
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
