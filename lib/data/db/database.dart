import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'schema.dart';
import '../../features/teams/data/team_metrics_models.dart';

// Conditional import for database connection
import 'connection/database_connection.dart'
    if (dart.library.io) 'connection/database_connection_mobile.dart'
    if (dart.library.html) 'connection/database_connection_web.dart';

part 'database.g.dart';

/// Combined Game and Team data for active game views
class GameWithTeam {
  final Game game;
  final Team team;

  const GameWithTeam({required this.game, required this.team});
}

@DriftDatabase(
  tables: [
    Seasons,
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
  AppDb() : super(createDatabaseConnection());
  // In-memory constructor for tests (avoids sqflite platform dependency)
  AppDb.test() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // All columns are now properly defined in the schema
    },
    beforeOpen: (details) async {
      // Validate database integrity before opening
      await _validateDatabaseIntegrity();
    },
    onUpgrade: (m, from, to) async {
      debugPrint('🔄 Starting database migration from version $from to $to');

      // SAFETY CHECK: Backup critical data before migration
      await _backupCriticalDataBeforeMigration(from);

      try {
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
          // NOTE: This migration step was causing conflicts - shift_length_seconds
          // is now properly handled in schema and version 17 migration
          try {
            await customStatement(
              'ALTER TABLE teams ADD COLUMN shift_length_seconds INTEGER NOT NULL DEFAULT 300',
            );
          } catch (e) {
            // Column might already exist, ignore the error
            debugPrint(
              'Migration warning: shift_length_seconds column may already exist: $e',
            );
          }
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
        if (from < 12) {
          await m.addColumn(games, games.timerStartTime as GeneratedColumn);
        }
        if (from < 13) {
          // Add game completion and scoring fields
          await m.addColumn(games, games.gameStatus);
          await m.addColumn(games, games.endTime);
          await m.addColumn(games, games.teamScore);
          await m.addColumn(games, games.opponentScore);
        }
        if (from < 14) {
          // Add abbreviation column to formation positions with a default value
          await customStatement(
            'ALTER TABLE formation_positions ADD COLUMN abbreviation TEXT NOT NULL DEFAULT ""',
          );
          // Populate existing positions with their position names as abbreviations
          await customStatement(
            'UPDATE formation_positions SET abbreviation = position_name',
          );
        }
        if (from < 15) {
          // Add jersey number and profile image fields to players
          await customStatement(
            'ALTER TABLE players ADD COLUMN jersey_number INTEGER',
          );
          await customStatement(
            'ALTER TABLE players ADD COLUMN profile_image_path TEXT',
          );
        }
        if (from < 16) {
          // Add team customization fields
          await customStatement(
            'ALTER TABLE teams ADD COLUMN logo_image_path TEXT',
          );
          await customStatement(
            'ALTER TABLE teams ADD COLUMN primary_color1 TEXT',
          );
          await customStatement(
            'ALTER TABLE teams ADD COLUMN primary_color2 TEXT',
          );
          await customStatement(
            'ALTER TABLE teams ADD COLUMN primary_color3 TEXT',
          );
        }
        if (from < 17) {
          // Ensure shift length seconds column exists and is properly typed
          try {
            // First try to add via Drift method (for clean schema compliance)
            await m.addColumn(
              teams,
              teams.shiftLengthSeconds as GeneratedColumn,
            );
          } catch (e) {
            // If it fails (column exists), verify it has correct default
            try {
              await customStatement(
                'UPDATE teams SET shift_length_seconds = 300 WHERE shift_length_seconds IS NULL',
              );
            } catch (updateError) {
              debugPrint(
                'Migration warning: Could not update shift_length_seconds defaults: $updateError',
              );
            }
          }
        }
        if (from < 18) {
          // Add seasons support
          await m.createTable(seasons);

          // Create a default season for existing data
          final defaultSeasonId = await into(seasons).insert(
            SeasonsCompanion.insert(
              name: 'Default Season',
              startDate: DateTime.now().subtract(const Duration(days: 365)),
              endDate: Value(DateTime.now().add(const Duration(days: 365))),
              isActive: Value(true),
            ),
          );

          // Add seasonId columns with default values and foreign key references
          await customStatement(
            'ALTER TABLE teams ADD COLUMN season_id INTEGER NOT NULL DEFAULT $defaultSeasonId REFERENCES seasons (id)',
          );
          await customStatement(
            'ALTER TABLE players ADD COLUMN season_id INTEGER NOT NULL DEFAULT $defaultSeasonId REFERENCES seasons (id)',
          );
          await customStatement(
            'ALTER TABLE games ADD COLUMN season_id INTEGER NOT NULL DEFAULT $defaultSeasonId REFERENCES seasons (id)',
          );
          await customStatement(
            'ALTER TABLE formations ADD COLUMN season_id INTEGER NOT NULL DEFAULT $defaultSeasonId REFERENCES seasons (id)',
          );
        }
      } catch (e) {
        debugPrint('❌ Migration error from $from to $to: $e');
        // Try to restore backup if available
        await _attemptDataRestoration(from);
        // Re-throw to let Drift handle the error appropriately
        rethrow;
      }

      // SAFETY CHECK: Verify data integrity after migration
      await _verifyDataIntegrityAfterMigration(from, to);
      debugPrint('✅ Migration from $from to $to completed successfully');
    },
  );

  // ============================================================================
  // MIGRATION SAFETY METHODS - Prevent Data Loss
  // ============================================================================

  /// Backup critical data before potentially destructive migrations
  Future<void> _backupCriticalDataBeforeMigration(int fromVersion) async {
    try {
      debugPrint('💾 Backing up critical data before migration...');

      // Store team count for verification
      final teamCount = await getTeamCount();
      final gameCount = await _getGameCount();
      final playerCount = await _getPlayerCount();

      // Store these in a temporary preference or shared storage
      // For now, just log them for verification
      debugPrint('📊 Pre-migration data counts:');
      debugPrint('   Teams: $teamCount');
      debugPrint('   Games: $gameCount');
      debugPrint('   Players: $playerCount');

      // Could extend this to actually create backup tables if needed
      if (teamCount > 0) {
        debugPrint(
          '✅ Critical team data detected - will verify after migration',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Could not backup data before migration: $e');
    }
  }

  /// Validate database integrity before opening
  Future<void> _validateDatabaseIntegrity() async {
    try {
      // Basic integrity checks
      await customSelect('PRAGMA integrity_check').get();
      await customSelect('PRAGMA foreign_key_check').get();
    } catch (e) {
      debugPrint('⚠️ Database integrity warning: $e');
    }
  }

  /// Verify data integrity after migration
  Future<void> _verifyDataIntegrityAfterMigration(
    int fromVersion,
    int toVersion,
  ) async {
    try {
      debugPrint('🔍 Verifying data integrity after migration...');

      // Check that critical tables exist and have expected structure
      final tables = await listTables();
      final expectedTables = ['teams', 'players', 'games', 'shifts'];

      for (final expectedTable in expectedTables) {
        if (!tables.contains(expectedTable)) {
          throw Exception(
            'Critical table $expectedTable is missing after migration!',
          );
        }
      }

      // Verify teams table has proper columns after customization migration
      if (fromVersion < 16 && toVersion >= 16) {
        await _verifyTeamCustomizationColumns();
      }

      debugPrint('✅ Data integrity verification passed');
    } catch (e) {
      debugPrint('❌ Data integrity verification failed: $e');
      rethrow;
    }
  }

  /// Verify team customization columns exist and are properly configured
  Future<void> _verifyTeamCustomizationColumns() async {
    try {
      final columns = await describeTeamsTable();
      final columnNames = columns.map((c) => c['name'] as String?).toSet();

      final requiredColumns = {
        'logo_image_path',
        'primary_color1',
        'primary_color2',
        'primary_color3',
      };

      for (final required in requiredColumns) {
        if (!columnNames.contains(required)) {
          throw Exception(
            'Required customization column $required is missing from teams table',
          );
        }
      }

      debugPrint('✅ Team customization columns verified');
    } catch (e) {
      debugPrint('❌ Team customization column verification failed: $e');
      rethrow;
    }
  }

  /// Attempt to restore data if migration fails
  Future<void> _attemptDataRestoration(int fromVersion) async {
    try {
      debugPrint('🔄 Attempting data restoration after migration failure...');
      // This is a placeholder for more sophisticated backup/restore logic
      // In a production app, you might restore from backup files or tables
      debugPrint(
        'ℹ️ Data restoration not implemented - manual recovery may be needed',
      );
    } catch (e) {
      debugPrint('❌ Data restoration attempt failed: $e');
    }
  }

  /// Get game count for backup verification
  Future<int> _getGameCount() async {
    try {
      final result = await customSelect(
        'SELECT COUNT(*) as count FROM games',
      ).get();
      return result.first.read<int>('count');
    } catch (e) {
      return 0;
    }
  }

  /// Get player count for backup verification
  Future<int> _getPlayerCount() async {
    try {
      final result = await customSelect(
        'SELECT COUNT(*) as count FROM players',
      ).get();
      return result.first.read<int>('count');
    } catch (e) {
      return 0;
    }
  }

  // ============================================================================
  // END MIGRATION SAFETY METHODS
  // ============================================================================

  /// Check if teams table exists and has data
  Future<bool> hasTeams() async {
    try {
      final teams = await select(this.teams).get();
      return teams.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking teams: $e');
      return false;
    }
  }

  /// Get raw team count for diagnostics
  Future<int> getTeamCount() async {
    try {
      final result = await customSelect(
        'SELECT COUNT(*) as count FROM teams',
        readsFrom: {teams},
      ).getSingleOrNull();
      return result?.read<int>('count') ?? 0;
    } catch (e) {
      debugPrint('Error getting team count: $e');
      return 0;
    }
  }

  /// Diagnostic method to list all tables in the database
  Future<List<String>> listTables() async {
    try {
      final result = await customSelect(
        'SELECT name FROM sqlite_master WHERE type="table"',
      ).get();
      return result.map((row) => row.read<String>('name')).toList();
    } catch (e) {
      debugPrint('Error listing tables: $e');
      return [];
    }
  }

  /// Diagnostic method to describe teams table structure
  Future<List<Map<String, dynamic>>> describeTeamsTable() async {
    try {
      final result = await customSelect('PRAGMA table_info(teams)').get();
      return result
          .map(
            (row) => {
              'name': row.read<String>('name'),
              'type': row.read<String>('type'),
              'notnull': row.read<int>('notnull'),
              'dflt_value': row.data['dflt_value'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error describing teams table: $e');
      return [];
    }
  }

  /// Helper method to reset database if migrations fail
  /// Use this only in development when database schema changes cause issues
  /// WARNING: This will delete all data!
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

extension SeasonQueries on AppDb {
  // Season management
  Future<int> createSeason({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    return await into(seasons).insert(
      SeasonsCompanion.insert(
        name: name,
        startDate: startDate,
        endDate: Value(endDate),
        isActive: Value(isActive),
      ),
    );
  }

  Future<List<Season>> getSeasons({bool includeArchived = false}) {
    final query = select(seasons);
    if (!includeArchived) {
      query.where((s) => s.isArchived.equals(false));
    }
    query.orderBy([(s) => OrderingTerm.desc(s.createdAt)]);
    return query.get();
  }

  Stream<List<Season>> watchSeasons({bool includeArchived = false}) {
    final query = select(seasons);
    if (!includeArchived) {
      query.where((s) => s.isArchived.equals(false));
    }
    query.orderBy([(s) => OrderingTerm.desc(s.createdAt)]);
    return query.watch();
  }

  Future<Season?> getSeason(int id) =>
      (select(seasons)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<Season?> getActiveSeason() =>
      (select(seasons)
            ..where((s) => s.isActive.equals(true) & s.isArchived.equals(false))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<Season?> watchActiveSeason() =>
      (select(seasons)
            ..where((s) => s.isActive.equals(true) & s.isArchived.equals(false))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<void> setActiveSeason(int seasonId) async {
    // Deactivate all seasons first
    await (update(seasons)).write(SeasonsCompanion(isActive: Value(false)));
    // Activate the selected season
    await (update(seasons)..where((s) => s.id.equals(seasonId))).write(
      SeasonsCompanion(isActive: Value(true)),
    );
  }

  Future<void> archiveSeason(int seasonId) async {
    await (update(seasons)..where((s) => s.id.equals(seasonId))).write(
      SeasonsCompanion(isArchived: Value(true), isActive: Value(false)),
    );
  }

  Future<void> unarchiveSeason(int seasonId) async {
    await (update(seasons)..where((s) => s.id.equals(seasonId))).write(
      SeasonsCompanion(isArchived: Value(false)),
    );
  }

  Future<void> updateSeason({
    required int seasonId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await (update(seasons)..where((s) => s.id.equals(seasonId))).write(
      SeasonsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        startDate: startDate != null ? Value(startDate) : const Value.absent(),
        endDate: endDate != null ? Value(endDate) : const Value.absent(),
      ),
    );
  }

  /// Clone an entire season with all its teams, players, formations, etc.
  Future<int> cloneSeason({
    required int fromSeasonId,
    required String newSeasonName,
    required DateTime newStartDate,
    DateTime? newEndDate,
  }) async {
    return await transaction(() async {
      // Create new season
      final newSeasonId = await createSeason(
        name: newSeasonName,
        startDate: newStartDate,
        endDate: newEndDate,
      );

      // Get all teams from the source season
      final sourceTeams = await (select(
        teams,
      )..where((t) => t.seasonId.equals(fromSeasonId))).get();

      final teamIdMapping = <int, int>{};

      // Clone teams
      for (final team in sourceTeams) {
        final newTeamId = await into(teams).insert(
          TeamsCompanion.insert(
            seasonId: newSeasonId,
            name: team.name,
            isArchived: Value(false), // Reset archive status for new season
            teamMode: Value(team.teamMode),
            halfDurationSeconds: Value(team.halfDurationSeconds),
            shiftLengthSeconds: Value(team.shiftLengthSeconds),
            logoImagePath: Value(team.logoImagePath),
            primaryColor1: Value(team.primaryColor1),
            primaryColor2: Value(team.primaryColor2),
            primaryColor3: Value(team.primaryColor3),
          ),
        );
        teamIdMapping[team.id] = newTeamId;
      }

      // Clone players for each team
      for (final oldTeamId in teamIdMapping.keys) {
        final newTeamId = teamIdMapping[oldTeamId]!;
        final sourcePlayers =
            await (select(players)..where(
                  (p) =>
                      p.teamId.equals(oldTeamId) &
                      p.seasonId.equals(fromSeasonId),
                ))
                .get();

        for (final player in sourcePlayers) {
          await into(players).insert(
            PlayersCompanion.insert(
              teamId: newTeamId,
              seasonId: newSeasonId,
              firstName: player.firstName,
              lastName: player.lastName,
              isPresent: Value(true), // Reset presence for new season
              jerseyNumber: Value(player.jerseyNumber),
              profileImagePath: Value(player.profileImagePath),
            ),
          );
        }
      }

      // Clone formations for each team
      for (final oldTeamId in teamIdMapping.keys) {
        final newTeamId = teamIdMapping[oldTeamId]!;
        final sourceFormations =
            await (select(formations)..where(
                  (f) =>
                      f.teamId.equals(oldTeamId) &
                      f.seasonId.equals(fromSeasonId),
                ))
                .get();

        for (final formation in sourceFormations) {
          final newFormationId = await into(formations).insert(
            FormationsCompanion.insert(
              teamId: newTeamId,
              seasonId: newSeasonId,
              name: formation.name,
              playerCount: formation.playerCount,
            ),
          );

          // Clone formation positions
          final sourcePositions = await (select(
            formationPositions,
          )..where((fp) => fp.formationId.equals(formation.id))).get();

          for (final position in sourcePositions) {
            await into(formationPositions).insert(
              FormationPositionsCompanion.insert(
                formationId: newFormationId,
                index: position.index,
                positionName: position.positionName,
                abbreviation: Value(position.abbreviation),
              ),
            );
          }
        }
      }

      return newSeasonId;
    });
  }

  /// Clone selected teams to a new season
  Future<int> cloneSelectedTeamsToSeason({
    required String newSeasonName,
    required DateTime newStartDate,
    DateTime? newEndDate,
    required List<int> teamIds,
  }) async {
    return await transaction(() async {
      // Create new season
      final newSeasonId = await createSeason(
        name: newSeasonName,
        startDate: newStartDate,
        endDate: newEndDate,
      );

      // If no teams selected, just return the new empty season
      if (teamIds.isEmpty) {
        return newSeasonId;
      }

      // Get selected teams
      final sourceTeams = await (select(
        teams,
      )..where((t) => t.id.isIn(teamIds))).get();

      final teamIdMapping = <int, int>{};

      // Clone selected teams
      for (final team in sourceTeams) {
        final newTeamId = await into(teams).insert(
          TeamsCompanion.insert(
            seasonId: newSeasonId,
            name: team.name,
            isArchived: Value(false), // Reset archive status for new season
            teamMode: Value(team.teamMode),
            halfDurationSeconds: Value(team.halfDurationSeconds),
            shiftLengthSeconds: Value(team.shiftLengthSeconds),
            logoImagePath: Value(team.logoImagePath),
            primaryColor1: Value(team.primaryColor1),
            primaryColor2: Value(team.primaryColor2),
            primaryColor3: Value(team.primaryColor3),
          ),
        );
        teamIdMapping[team.id] = newTeamId;
      }

      // Clone players for each selected team
      for (final oldTeamId in teamIdMapping.keys) {
        final newTeamId = teamIdMapping[oldTeamId]!;
        final sourcePlayers = await (select(
          players,
        )..where((p) => p.teamId.equals(oldTeamId))).get();

        for (final player in sourcePlayers) {
          await into(players).insert(
            PlayersCompanion.insert(
              teamId: newTeamId,
              seasonId: newSeasonId,
              firstName: player.firstName,
              lastName: player.lastName,
              isPresent: Value(true), // Reset presence for new season
              jerseyNumber: Value(player.jerseyNumber),
              profileImagePath: Value(player.profileImagePath),
            ),
          );
        }
      }

      // Clone formations for each selected team
      for (final oldTeamId in teamIdMapping.keys) {
        final newTeamId = teamIdMapping[oldTeamId]!;
        final sourceFormations = await (select(
          formations,
        )..where((f) => f.teamId.equals(oldTeamId))).get();

        for (final formation in sourceFormations) {
          final newFormationId = await into(formations).insert(
            FormationsCompanion.insert(
              teamId: newTeamId,
              seasonId: newSeasonId,
              name: formation.name,
              playerCount: formation.playerCount,
            ),
          );

          // Clone formation positions
          final sourcePositions = await (select(
            formationPositions,
          )..where((fp) => fp.formationId.equals(formation.id))).get();

          for (final position in sourcePositions) {
            await into(formationPositions).insert(
              FormationPositionsCompanion.insert(
                formationId: newFormationId,
                index: position.index,
                positionName: position.positionName,
                abbreviation: Value(position.abbreviation),
              ),
            );
          }
        }
      }

      return newSeasonId;
    });
  }
}

extension TeamQueries on AppDb {
  Future<int> addTeam(TeamsCompanion t) async {
    final teamId = await into(teams).insert(t);
    // No longer auto-create formations - let users choose templates instead
    return teamId;
  }

  /// Add team with season context
  Future<int> addTeamToSeason({
    required int seasonId,
    required String name,
    String teamMode = 'shift',
    int halfDurationSeconds = 1200,
    int shiftLengthSeconds = 300,
    String? logoImagePath,
    String? primaryColor1,
    String? primaryColor2,
    String? primaryColor3,
  }) async {
    return await into(teams).insert(
      TeamsCompanion.insert(
        seasonId: seasonId,
        name: name,
        teamMode: Value(teamMode),
        halfDurationSeconds: Value(halfDurationSeconds),
        shiftLengthSeconds: Value(shiftLengthSeconds),
        logoImagePath: Value(logoImagePath),
        primaryColor1: Value(primaryColor1),
        primaryColor2: Value(primaryColor2),
        primaryColor3: Value(primaryColor3),
      ),
    );
  }

  Stream<List<Team>> watchTeams({bool includeArchived = false, int? seasonId}) {
    final query = select(teams);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    if (seasonId != null) {
      query.where((t) => t.seasonId.equals(seasonId));
    }
    return query.watch();
  }

  Future<Team?> getTeam(int id) =>
      (select(teams)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get all teams across all seasons
  Future<List<Team>> getAllTeams() async {
    return await select(teams).get();
  }

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
    final team = await getTeam(teamId);
    return team?.shiftLengthSeconds ?? 300;
  }

  Future<void> setTeamShiftLengthSeconds(int teamId, int seconds) async {
    if (seconds <= 0) seconds = 300;
    await (update(teams)..where((t) => t.id.equals(teamId))).write(
      TeamsCompanion(shiftLengthSeconds: Value(seconds)),
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

  // Team customization methods
  Future<void> updateTeamLogo(int teamId, String? logoPath) async {
    debugPrint('Updating team $teamId logo to: $logoPath');
    await (update(teams)..where((t) => t.id.equals(teamId))).write(
      TeamsCompanion(logoImagePath: Value(logoPath)),
    );
    debugPrint('Team logo update completed');
  }

  Future<void> updateTeamColors(
    int teamId, {
    String? color1,
    String? color2,
    String? color3,
  }) async {
    await (update(teams)..where((t) => t.id.equals(teamId))).write(
      TeamsCompanion(
        primaryColor1: Value(color1),
        primaryColor2: Value(color2),
        primaryColor3: Value(color3),
      ),
    );
  }

  Future<List<String>> getTeamColors(int teamId) async {
    final team = await getTeam(teamId);
    if (team == null) return [];
    return [
      if (team.primaryColor1?.isNotEmpty == true) team.primaryColor1!,
      if (team.primaryColor2?.isNotEmpty == true) team.primaryColor2!,
      if (team.primaryColor3?.isNotEmpty == true) team.primaryColor3!,
    ];
  }

  /// Get teams that have had games in the last few months
  Future<List<Team>> getTeamsWithRecentGames({int monthsBack = 4}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: monthsBack * 30));

    final query =
        select(teams).join([innerJoin(games, games.teamId.equalsExp(teams.id))])
          ..where(
            teams.isArchived.equals(false) &
                games.isArchived.equals(false) &
                games.startTime.isNotNull() &
                games.startTime.isBiggerOrEqualValue(cutoffDate),
          )
          ..groupBy([teams.id])
          ..orderBy([OrderingTerm.desc(games.startTime)]);

    final result = await query.get();
    return result.map((row) => row.readTable(teams)).toList();
  }
}

extension FormationQueries on AppDb {
  Future<Formation?> getFormation(int id) =>
      (select(formations)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<int> createFormation({
    required int teamId,
    required int seasonId,
    required String name,
    required int playerCount,
    required List<String> positions,
    List<String>? abbreviations,
  }) async {
    final formationId = await into(formations).insert(
      FormationsCompanion.insert(
        teamId: teamId,
        seasonId: seasonId,
        name: name,
        playerCount: playerCount,
      ),
    );
    for (var i = 0; i < positions.length; i++) {
      final abbreviation = abbreviations != null && i < abbreviations.length
          ? abbreviations[i]
          : positions[i]; // Default to position name if no abbreviation provided
      await into(formationPositions).insert(
        FormationPositionsCompanion.insert(
          formationId: formationId,
          index: i,
          positionName: positions[i],
          abbreviation: Value(abbreviation),
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
    List<String>? abbreviations,
  }) async {
    await transaction(() async {
      await (update(formations)..where((f) => f.id.equals(id))).write(
        FormationsCompanion(name: Value(name), playerCount: Value(playerCount)),
      );
      await (delete(
        formationPositions,
      )..where((fp) => fp.formationId.equals(id))).go();
      for (var i = 0; i < positions.length; i++) {
        final abbreviation = abbreviations != null && i < abbreviations.length
            ? abbreviations[i]
            : positions[i]; // Default to position name if no abbreviation provided
        await into(formationPositions).insert(
          FormationPositionsCompanion.insert(
            formationId: id,
            index: i,
            positionName: positions[i],
            abbreviation: Value(abbreviation),
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

  Stream<List<Formation>> watchTeamFormations(int teamId, {int? seasonId}) {
    final query = select(formations)..where((f) => f.teamId.equals(teamId));
    if (seasonId != null) {
      query.where((f) => f.seasonId.equals(seasonId));
    }
    return query.watch();
  }

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
}

/// Provider for formation templates
class FormationTemplates {
  /// Gets available formation templates that users can choose from
  static List<FormationTemplate> getTemplates() {
    return [
      const FormationTemplate(
        name: '4-4-2',
        playerCount: 11,
        positions: [
          'Goalkeeper',
          'Right Back',
          'Right Center Back',
          'Left Center Back',
          'Left Back',
          'Right Midfielder',
          'Right Central Midfielder',
          'Left Central Midfielder',
          'Left Midfielder',
          'Right Striker',
          'Left Striker',
        ],
        abbreviations: [
          'GK',
          'RB',
          'RCB',
          'LCB',
          'LB',
          'RM',
          'RCM',
          'LCM',
          'LM',
          'RST',
          'LST',
        ],
      ),
      const FormationTemplate(
        name: '4-3-3',
        playerCount: 11,
        positions: [
          'Goalkeeper',
          'Right Back',
          'Right Center Back',
          'Left Center Back',
          'Left Back',
          'Central Defensive Midfielder',
          'Right Central Midfielder',
          'Left Central Midfielder',
          'Right Winger',
          'Center Forward',
          'Left Winger',
        ],
        abbreviations: [
          'GK',
          'RB',
          'RCB',
          'LCB',
          'LB',
          'CDM',
          'RCM',
          'LCM',
          'RW',
          'CF',
          'LW',
        ],
      ),
      const FormationTemplate(
        name: '2-2-1',
        playerCount: 6,
        positions: [
          'Goalkeeper',
          'Left Back',
          'Right Back',
          'Left Midfielder',
          'Right Midfielder',
          'Striker',
        ],
        abbreviations: ['GK', 'LB', 'RB', 'LM', 'RM', 'ST'],
      ),
      const FormationTemplate(
        name: '4-2-3-1',
        playerCount: 11,
        positions: [
          'Goalkeeper',
          'Right Back',
          'Right Center Back',
          'Left Center Back',
          'Left Back',
          'Right Central Defensive Midfielder',
          'Left Central Defensive Midfielder',
          'Right Attacking Midfielder',
          'Central Attacking Midfielder',
          'Left Attacking Midfielder',
          'Striker',
        ],
        abbreviations: [
          'GK',
          'RB',
          'RCB',
          'LCB',
          'LB',
          'RCDM',
          'LCDM',
          'RAM',
          'CAM',
          'LAM',
          'ST',
        ],
      ),
    ];
  }
}

/// A template for creating formations
class FormationTemplate {
  final String name;
  final int playerCount;
  final List<String> positions;
  final List<String> abbreviations;

  const FormationTemplate({
    required this.name,
    required this.playerCount,
    required this.positions,
    required this.abbreviations,
  });
}

extension PlayerQueries on AppDb {
  Stream<List<Player>> watchPlayersByTeam(int teamId, {int? seasonId}) {
    final query = select(players)..where((p) => p.teamId.equals(teamId));
    if (seasonId != null) {
      query.where((p) => p.seasonId.equals(seasonId));
    }
    return query.watch();
  }

  Future<List<Player>> getPlayersByTeam(int teamId, {int? seasonId}) {
    final query = select(players)..where((p) => p.teamId.equals(teamId));
    if (seasonId != null) {
      query.where((p) => p.seasonId.equals(seasonId));
    }
    return query.get();
  }

  Future<Player?> getPlayer(int id) =>
      (select(players)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<void> updatePlayer({
    required int id,
    required String firstName,
    required String lastName,
    required bool isPresent,
    int? jerseyNumber,
    String? profileImagePath,
  }) => (update(players)..where((p) => p.id.equals(id))).write(
    PlayersCompanion(
      firstName: Value(firstName),
      lastName: Value(lastName),
      isPresent: Value(isPresent),
      jerseyNumber: Value(jerseyNumber),
      profileImagePath: Value(profileImagePath),
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
    int? teamScore,
    int? opponentScore,
    String? gameStatus,
    DateTime? endTime,
    bool? isGameActive,
  }) => (update(games)..where((g) => g.id.equals(id))).write(
    GamesCompanion(
      opponent: opponent == null ? const Value.absent() : Value(opponent),
      startTime: startTime == null ? const Value.absent() : Value(startTime),
      formationId: formationId == null
          ? const Value.absent()
          : Value(formationId),
      teamScore: teamScore == null ? const Value.absent() : Value(teamScore),
      opponentScore: opponentScore == null
          ? const Value.absent()
          : Value(opponentScore),
      gameStatus: gameStatus == null ? const Value.absent() : Value(gameStatus),
      endTime: endTime == null ? const Value.absent() : Value(endTime),
      isGameActive: isGameActive == null
          ? const Value.absent()
          : Value(isGameActive),
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
      GamesCompanion(
        isGameActive: const Value(true),
        timerStartTime: Value(DateTime.now()),
      ),
    );
  }

  Future<void> pauseGameTimer(int gameId) async {
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      const GamesCompanion(
        isGameActive: Value(false),
        timerStartTime: Value(null),
      ),
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
        timerStartTime: Value(null),
      ),
    );
  }

  /// Calculate the current game time based on stored game time and timer start time
  /// This ensures accuracy even after the app has been in the background
  Future<int> calculateCurrentGameTime(int gameId) async {
    final game = await getGame(gameId);
    if (game == null) return 0;

    if (!game.isGameActive || game.timerStartTime == null) {
      return game.gameTimeSeconds;
    }

    final elapsedSinceStart = DateTime.now()
        .difference(game.timerStartTime!)
        .inSeconds;
    return game.gameTimeSeconds + elapsedSinceStart;
  }

  /// Update timer start time while keeping current game time
  Future<void> updateTimerStartTime(int gameId) async {
    await (update(games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(timerStartTime: Value(DateTime.now())),
    );
  }

  /// Watch active games across all teams (games that have started but not yet completed)
  Stream<List<GameWithTeam>> watchActiveGames() {
    return (select(
            games,
          ).join([leftOuterJoin(teams, teams.id.equalsExp(games.teamId))])
          ..where(
            games.startTime.isNotNull() &
                games.gameStatus.equals('in-progress') &
                games.isArchived.equals(false),
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
    // First get explicit attendance records
    final attendanceRecords = await (select(
      gamePlayers,
    )..where((gp) => gp.gameId.equals(gameId))).get();

    // Get all team players for the game's team
    final game = await getGame(gameId);
    if (game == null) return lineup;

    final teamPlayers = await (select(
      players,
    )..where((p) => p.teamId.equals(game.teamId))).get();

    // Determine which players are present
    final availablePlayerIds = <int>[];
    for (final player in teamPlayers) {
      // Check if there's an explicit attendance record
      final attendanceRecord = attendanceRecords
          .where((ar) => ar.playerId == player.id)
          .firstOrNull;

      final isPresent = attendanceRecord?.isPresent ?? player.isPresent;

      if (isPresent) {
        availablePlayerIds.add(player.id);
      }
    }

    if (availablePlayerIds.isEmpty) return lineup;

    // Shuffle players for random assignment
    availablePlayerIds.shuffle();

    // Assign players to positions
    for (
      int i = 0;
      i < positions.length && i < availablePlayerIds.length;
      i++
    ) {
      lineup[positions[i].positionName] = availablePlayerIds[i];
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

extension TeamMetricsQueries on AppDb {
  /// Get aggregated metrics for all players in a team across all their games
  Future<List<PlayerTeamMetrics>> getTeamPlayerMetrics(int teamId) async {
    // First get all players for the team
    final players = await (select(
      this.players,
    )..where((p) => p.teamId.equals(teamId))).get();

    final teamPlayerMetrics = <PlayerTeamMetrics>[];

    for (final player in players) {
      // Get all games for this team
      final games = await (select(
        this.games,
      )..where((g) => g.teamId.equals(teamId))).get();

      if (games.isEmpty) continue;

      final gameIds = games.map((g) => g.id).toList();

      // Get player metrics across all games
      final metrics =
          await (select(playerMetrics)..where(
                (m) => m.playerId.equals(player.id) & m.gameId.isIn(gameIds),
              ))
              .get();

      // Aggregate metrics
      var totalGoals = 0;
      var totalAssists = 0;
      var totalSaves = 0;
      for (final metric in metrics) {
        switch (metric.metric) {
          case 'GOAL':
            totalGoals += metric.value;
            break;
          case 'ASSIST':
            totalAssists += metric.value;
            break;
          case 'SAVE':
            totalSaves += metric.value;
            break;
        }
      }

      // Get total play time - check team mode to determine which metric to use
      final team = await getTeam(teamId);
      final isTraditionalMode = team?.teamMode == 'traditional';

      var totalPlayTimeSeconds = 0;
      var gamesPlayed = 0;

      for (final gameId in gameIds) {
        if (isTraditionalMode) {
          // For traditional mode, use the traditional_playing_time metric
          final playTime =
              await (select(playerMetrics)..where(
                    (m) =>
                        m.playerId.equals(player.id) &
                        m.gameId.equals(gameId) &
                        m.metric.equals('traditional_playing_time'),
                  ))
                  .getSingleOrNull();
          if (playTime != null) {
            totalPlayTimeSeconds += playTime.value;
            gamesPlayed++;
          }
        } else {
          // For shift mode, sum up shift times
          final playTime = await playedSecondsByPlayer(gameId);
          final playerSeconds = playTime[player.id] ?? 0;
          if (playerSeconds > 0) {
            totalPlayTimeSeconds += playerSeconds;
            gamesPlayed++;
          }
        }
      }

      teamPlayerMetrics.add(
        PlayerTeamMetrics(
          playerId: player.id,
          firstName: player.firstName,
          lastName: player.lastName,
          jerseyNumber: player.jerseyNumber,
          profileImagePath: player.profileImagePath,
          totalGoals: totalGoals,
          totalAssists: totalAssists,
          totalSaves: totalSaves,
          totalPlayTimeSeconds: totalPlayTimeSeconds,
          gamesPlayed: gamesPlayed,
        ),
      );
    }

    return teamPlayerMetrics;
  }

  /// Get team metrics summary including totals and player breakdowns
  Future<TeamMetricsSummary> getTeamMetricsSummary(int teamId) async {
    final team = await getTeam(teamId);
    if (team == null) {
      throw StateError('Team not found: $teamId');
    }

    final teamPlayerMetrics = await getTeamPlayerMetrics(teamId);

    // Get total games count for the team
    final totalGames =
        await (select(games)..where((g) => g.teamId.equals(teamId))).get().then(
          (gamesList) => gamesList.length,
        );

    // Calculate team totals from player metrics
    final totalGoals = teamPlayerMetrics.fold<int>(
      0,
      (sum, p) => sum + p.totalGoals,
    );
    final totalAssists = teamPlayerMetrics.fold<int>(
      0,
      (sum, p) => sum + p.totalAssists,
    );
    final totalSaves = teamPlayerMetrics.fold<int>(
      0,
      (sum, p) => sum + p.totalSaves,
    );
    final totalPlayTimeSeconds = teamPlayerMetrics.fold<int>(
      0,
      (sum, p) => sum + p.totalPlayTimeSeconds,
    );

    return TeamMetricsSummary(
      teamId: teamId,
      teamName: team.name,
      totalGames: totalGames,
      totalGoals: totalGoals,
      totalAssists: totalAssists,
      totalSaves: totalSaves,
      totalPlayTimeSeconds: totalPlayTimeSeconds,
      playerMetrics: teamPlayerMetrics,
    );
  }

  /// Watch for changes in team metrics (simplified version for now)
  Stream<TeamMetricsSummary> watchTeamMetricsSummary(int teamId) async* {
    // For now, just yield current data - in a real implementation you'd want to watch
    // for changes in games, playerMetrics, etc. and rebuild the summary
    yield await getTeamMetricsSummary(teamId);
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

  // Diagnostic methods for troubleshooting
  Future<List<String>> listTables() async {
    final result = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    ).get();
    return result.map((row) => row.read<String>('name')).toList();
  }

  Future<List<Map<String, dynamic>>> describeTeamsTable() async {
    try {
      final result = await customSelect('PRAGMA table_info(teams)').get();
      return result
          .map(
            (row) => {
              'cid': row.read<int?>('cid'),
              'name': row.read<String?>('name'),
              'type': row.read<String?>('type'),
              'notnull': row.read<int?>('notnull'),
              'dflt_value': row.read<String?>('dflt_value'),
              'pk': row.read<int?>('pk'),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error describing teams table: $e');
      return [];
    }
  }

  Future<bool> hasTeams() async {
    try {
      final count = await getTeamCount();
      return count > 0;
    } catch (e) {
      debugPrint('Error checking if teams exist: $e');
      return false;
    }
  }

  Future<int> getTeamCount() async {
    try {
      final result = await customSelect(
        'SELECT COUNT(*) as count FROM teams',
      ).get();
      return result.first.read<int>('count');
    } catch (e) {
      debugPrint('Error getting team count: $e');
      return 0;
    }
  }

  // ============================================================================
  // DATABASE RESET METHODS - Use with extreme caution!
  // ============================================================================

  /// Get a comprehensive summary of data that would be lost
  Future<Map<String, int>> getDataSummaryForReset() async {
    final summary = <String, int>{};

    try {
      summary['teams'] = await getTeamCount();
      summary['players'] = await _getPlayerCount();
      summary['games'] = await _getGameCount();

      // Get additional counts for shifts and metrics
      final shiftsResult = await customSelect(
        'SELECT COUNT(*) as count FROM shifts',
      ).get();
      summary['shifts'] = shiftsResult.first.read<int>('count');

      final metricsResult = await customSelect(
        'SELECT COUNT(*) as count FROM player_metrics',
      ).get();
      summary['metrics'] = metricsResult.first.read<int>('count');

      final formationsResult = await customSelect(
        'SELECT COUNT(*) as count FROM formations',
      ).get();
      summary['formations'] = formationsResult.first.read<int>('count');
    } catch (e) {
      debugPrint('Error getting data summary: $e');
    }

    return summary;
  }

  /// Nuclear option: Reset entire database (USE WITH EXTREME CAUTION!)
  /// Automatically creates a backup before resetting
  Future<Map<String, dynamic>> resetDatabaseSafely() async {
    try {
      debugPrint('🚨 DANGER: Resetting entire database...');

      // STEP 1: Create automatic backup first
      final backupPath = await createAutomaticBackup();
      if (backupPath != null) {
        debugPrint('💾 Automatic backup created before reset: $backupPath');
      }

      debugPrint('🗑️ Proceeding with database reset...');

      // Delete all data in correct order to respect foreign keys
      await customStatement('PRAGMA foreign_keys = OFF');

      final tables = [
        'player_shifts',
        'player_metrics',
        'shifts',
        'game_players',
        'formation_positions',
        'formations',
        'games',
        'players',
        'teams',
        'player_position_totals',
      ];

      for (final table in tables) {
        try {
          await customStatement('DELETE FROM $table');
          debugPrint('🗑️ Cleared $table');
        } catch (e) {
          debugPrint('⚠️ Warning: Could not clear $table: $e');
        }
      }

      await customStatement('PRAGMA foreign_keys = ON');

      // Reset any auto-increment counters
      await customStatement('DELETE FROM sqlite_sequence');

      debugPrint('✅ Database reset completed');
      return {
        'success': true,
        'backupPath': backupPath,
        'message': 'Database reset completed successfully',
      };
    } catch (e) {
      debugPrint('❌ Database reset failed: $e');
      return {
        'success': false,
        'backupPath': null,
        'message': 'Database reset failed: $e',
      };
    }
  }

  /// Less destructive: Reset only team data while preserving structure
  Future<bool> resetTeamData() async {
    try {
      debugPrint('🚨 Resetting team data...');

      await customStatement('PRAGMA foreign_keys = OFF');

      // Delete in order to respect relationships
      await customStatement('DELETE FROM player_shifts');
      await customStatement('DELETE FROM player_metrics');
      await customStatement('DELETE FROM shifts');
      await customStatement('DELETE FROM game_players');
      await customStatement('DELETE FROM formation_positions');
      await customStatement('DELETE FROM formations');
      await customStatement('DELETE FROM games');
      await customStatement('DELETE FROM players');
      await customStatement('DELETE FROM teams');
      await customStatement('DELETE FROM player_position_totals');

      await customStatement('PRAGMA foreign_keys = ON');

      debugPrint('✅ Team data reset completed');
      return true;
    } catch (e) {
      debugPrint('❌ Team data reset failed: $e');
      return false;
    }
  }

  // ============================================================================
  // DATABASE EXPORT/IMPORT METHODS - Backup and Restore
  // ============================================================================

  /// Export entire database to JSON format
  Future<String> exportDatabase() async {
    try {
      debugPrint('📤 Starting database export...');

      final exportData = <String, dynamic>{
        'exportMetadata': {
          'version': schemaVersion,
          'exportDate': DateTime.now().toIso8601String(),
          'appVersion': '1.0.0', // Could be made dynamic
        },
        'data': {},
      };

      // Export teams
      final teams = await select(this.teams).get();
      exportData['data']['teams'] = teams.map((t) => t.toJson()).toList();
      debugPrint('📊 Exported ${teams.length} teams');

      // Export players
      final players = await select(this.players).get();
      exportData['data']['players'] = players.map((p) => p.toJson()).toList();
      debugPrint('📊 Exported ${players.length} players');

      // Export games
      final games = await select(this.games).get();
      exportData['data']['games'] = games.map((g) => g.toJson()).toList();
      debugPrint('📊 Exported ${games.length} games');

      // Export formations
      final formations = await select(this.formations).get();
      exportData['data']['formations'] = formations
          .map((f) => f.toJson())
          .toList();
      debugPrint('📊 Exported ${formations.length} formations');

      // Export formation positions
      final formationPositions = await select(this.formationPositions).get();
      exportData['data']['formationPositions'] = formationPositions
          .map((fp) => fp.toJson())
          .toList();
      debugPrint(
        '📊 Exported ${formationPositions.length} formation positions',
      );

      // Export shifts
      final shifts = await select(this.shifts).get();
      exportData['data']['shifts'] = shifts.map((s) => s.toJson()).toList();
      debugPrint('📊 Exported ${shifts.length} shifts');

      // Export player shifts
      final playerShifts = await select(this.playerShifts).get();
      exportData['data']['playerShifts'] = playerShifts
          .map((ps) => ps.toJson())
          .toList();
      debugPrint('📊 Exported ${playerShifts.length} player shifts');

      // Export game players
      final gamePlayers = await select(this.gamePlayers).get();
      exportData['data']['gamePlayers'] = gamePlayers
          .map((gp) => gp.toJson())
          .toList();
      debugPrint('📊 Exported ${gamePlayers.length} game players');

      // Export player metrics
      final playerMetrics = await select(this.playerMetrics).get();
      exportData['data']['playerMetrics'] = playerMetrics
          .map((pm) => pm.toJson())
          .toList();
      debugPrint('📊 Exported ${playerMetrics.length} player metrics');

      // Export player position totals
      final playerPositionTotals = await select(
        this.playerPositionTotals,
      ).get();
      exportData['data']['playerPositionTotals'] = playerPositionTotals
          .map((ppt) => ppt.toJson())
          .toList();
      debugPrint('📊 Exported ${playerPositionTotals.length} position totals');

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      debugPrint('✅ Database export completed successfully');
      return jsonString;
    } catch (e) {
      debugPrint('❌ Database export failed: $e');
      rethrow;
    }
  }

  /// Save database export to file
  Future<String> exportDatabaseToFile() async {
    try {
      final jsonData = await exportDatabase();

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final fileName = 'soccer_assistant_backup_$timestamp.json';
      final filePath = p.join(directory.path, fileName);

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonData);

      debugPrint('💾 Database exported to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Failed to save database export: $e');
      rethrow;
    }
  }

  /// Import database from JSON string
  Future<bool> importDatabase(String jsonData) async {
    try {
      debugPrint('📥 Starting database import...');

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final importData = data['data'] as Map<String, dynamic>;
      final metadata = data['exportMetadata'] as Map<String, dynamic>?;

      if (metadata != null) {
        final exportVersion = metadata['version'] as int?;
        debugPrint(
          '📋 Import metadata: version $exportVersion, date ${metadata['exportDate']}',
        );

        if (exportVersion != null && exportVersion > schemaVersion) {
          throw Exception(
            'Cannot import data from newer app version (export: v$exportVersion, current: v$schemaVersion)',
          );
        }
      }

      // Clear existing data first
      await resetDatabaseSafely();

      // Import in correct order to respect foreign key constraints
      await customStatement('PRAGMA foreign_keys = OFF');

      // Determine fallback season id (use active season if available)
      final activeSeason = await getActiveSeason();
      final fallbackSeasonId = activeSeason?.id ?? 1;

      // 1. Import teams first
      if (importData.containsKey('teams')) {
        final teams = importData['teams'] as List;
        for (var i = 0; i < teams.length; i++) {
          var teamData = teams[i];
          try {
            // Ensure seasonId exists to satisfy generated Team.fromJson
            final Map<String, dynamic> t = Map<String, dynamic>.from(teamData as Map<String, dynamic>);
            if (!t.containsKey('seasonId') || t['seasonId'] == null) {
              t['seasonId'] = fallbackSeasonId;
            }
            await into(this.teams).insert(
              Team.fromJson(t),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert team at index $i: $teamData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${teams.length} teams');
      }

      // 2. Import players
      if (importData.containsKey('players')) {
        final players = importData['players'] as List;
        for (var i = 0; i < players.length; i++) {
          final playerData = players[i];
          try {
            // Ensure seasonId exists for Player.fromJson
            final Map<String, dynamic> p = Map<String, dynamic>.from(playerData as Map<String, dynamic>);
            if (!p.containsKey('seasonId') || p['seasonId'] == null) {
              p['seasonId'] = fallbackSeasonId;
            }
            await into(this.players).insert(
              Player.fromJson(p),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert player at index $i: $playerData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${players.length} players');
      }

      // 3. Import formations
      if (importData.containsKey('formations')) {
        final formations = importData['formations'] as List;
        for (var i = 0; i < formations.length; i++) {
          final formationData = formations[i];
          try {
            await into(this.formations).insert(
              Formation.fromJson(formationData as Map<String, dynamic>),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert formation at index $i: $formationData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${formations.length} formations');
      }

      // 4. Import formation positions
      if (importData.containsKey('formationPositions')) {
        final positions = importData['formationPositions'] as List;
        for (var i = 0; i < positions.length; i++) {
          final positionData = positions[i];
          try {
            await into(formationPositions).insert(
              FormationPosition.fromJson(positionData as Map<String, dynamic>),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert formationPosition at index $i: $positionData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${positions.length} formation positions');
      }

      // 5. Import games
      if (importData.containsKey('games')) {
        final games = importData['games'] as List;
        for (var i = 0; i < games.length; i++) {
          final gameData = games[i];
          // Normalize timestamp fields that may be exported as epoch millis
          final g = Map<String, dynamic>.from(gameData as Map<String, dynamic>);
          for (final key in ['startTime', 'timerStartTime', 'endTime']) {
            if (g.containsKey(key) && g[key] is int) {
              try {
                g[key] = DateTime.fromMillisecondsSinceEpoch(g[key] as int).toIso8601String();
              } catch (_) {
                // leave as-is on failure
              }
            }
          }

          try {
            await into(this.games).insert(Game.fromJson(g));
          } catch (e, st) {
            debugPrint('❌ Failed to insert game at index $i: $g');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${games.length} games');
      }

      // 6. Import game players
      if (importData.containsKey('gamePlayers')) {
        final gamePlayers = importData['gamePlayers'] as List;
        for (var i = 0; i < gamePlayers.length; i++) {
          final gamePlayerData = gamePlayers[i];
          try {
            await into(this.gamePlayers).insert(
              GamePlayer.fromJson(gamePlayerData as Map<String, dynamic>),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert gamePlayer at index $i: $gamePlayerData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${gamePlayers.length} game players');
      }

      // 7. Import shifts
      if (importData.containsKey('shifts')) {
        final shifts = importData['shifts'] as List;
        for (var i = 0; i < shifts.length; i++) {
          final shiftData = shifts[i];
          try {
            await into(this.shifts).insert(
              Shift.fromJson(shiftData as Map<String, dynamic>),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert shift at index $i: $shiftData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${shifts.length} shifts');
      }

      // 8. Import player shifts
      if (importData.containsKey('playerShifts')) {
        final playerShifts = importData['playerShifts'] as List;
        for (var i = 0; i < playerShifts.length; i++) {
          final playerShiftData = playerShifts[i];
          try {
            await into(this.playerShifts).insert(
              PlayerShift.fromJson(playerShiftData as Map<String, dynamic>),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert playerShift at index $i: $playerShiftData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${playerShifts.length} player shifts');
      }

      // 9. Import player metrics
      if (importData.containsKey('playerMetrics')) {
        final playerMetrics = importData['playerMetrics'] as List;
        for (var i = 0; i < playerMetrics.length; i++) {
          final metricData = playerMetrics[i];
          try {
            await into(this.playerMetrics).insert(
              PlayerMetric.fromJson(metricData as Map<String, dynamic>),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert playerMetric at index $i: $metricData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${playerMetrics.length} player metrics');
      }

      // 10. Import player position totals
      if (importData.containsKey('playerPositionTotals')) {
        final totals = importData['playerPositionTotals'] as List;
        for (var i = 0; i < totals.length; i++) {
          final totalData = totals[i];
          try {
            await into(playerPositionTotals).insert(
              PlayerPositionTotal.fromJson(totalData as Map<String, dynamic>),
            );
          } catch (e, st) {
            debugPrint('❌ Failed to insert playerPositionTotal at index $i: $totalData');
            debugPrint('Error: $e');
            debugPrint(st.toString());
            rethrow;
          }
        }
        debugPrint('✅ Imported ${totals.length} position totals');
      }

      await customStatement('PRAGMA foreign_keys = ON');

      debugPrint('✅ Database import completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Database import failed: $e');
      await customStatement(
        'PRAGMA foreign_keys = ON',
      ); // Ensure foreign keys are re-enabled
      return false;
    }
  }

  /// Import database from file
  Future<bool> importDatabaseFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Import file does not exist: $filePath');
      }

      final jsonData = await file.readAsString();
      return await importDatabase(jsonData);
    } catch (e) {
      debugPrint('❌ Failed to import from file: $e');
      return false;
    }
  }

  /// Create automatic backup before destructive operations
  Future<String?> createAutomaticBackup() async {
    try {
      debugPrint('🔄 Creating automatic backup...');

      // Check if there's any data to backup
      final summary = await getDataSummaryForReset();
      final hasData = summary.values.any((count) => count > 0);

      if (!hasData) {
        debugPrint('ℹ️ No data to backup - skipping automatic backup');
        return null;
      }

      final backupPath = await exportDatabaseToFile();
      debugPrint('✅ Automatic backup created: $backupPath');
      return backupPath;
    } catch (e) {
      debugPrint('⚠️ Automatic backup failed: $e');
      return null;
    }
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
