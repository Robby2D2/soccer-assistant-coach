import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Tables expected to exist after a fresh install at the current schema version.
/// Update this list when adding a new table — the matching `onCreate` path
/// runs automatically via Drift's generated `createAll`, so a forgotten entry
/// here means we forgot to add coverage, not that something broke.
const _expectedTables = <String>{
  'seasons',
  'teams',
  'players',
  'games',
  'shifts',
  'player_shifts',
  'player_metrics',
  'game_players',
  'player_position_totals',
  'formations',
  'formation_positions',
};

/// Columns that must exist on `teams` after every migration step that adds them.
/// If a future migration drops one of these the test fails loudly.
const _expectedTeamColumns = <String>{
  'id',
  'season_id',
  'name',
  'is_archived',
  'team_mode',
  'half_duration_seconds',
  'shift_length_seconds',
  'logo_image_path',
  'primary_color1',
  'primary_color2',
  'primary_color3',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fresh install (onCreate)', () {
    late AppDb db;

    setUp(() {
      db = AppDb.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('reports the expected schema version', () {
      expect(db.schemaVersion, 18);
    });

    test('creates every expected table', () async {
      final tables = (await db.listTables()).toSet();
      for (final t in _expectedTables) {
        expect(tables, contains(t), reason: 'missing table: $t');
      }
    });

    test('teams table has all migration-added columns', () async {
      final cols = (await db.describeTeamsTable())
          .map((c) => c['name'] as String?)
          .whereType<String>()
          .toSet();
      for (final c in _expectedTeamColumns) {
        expect(cols, contains(c), reason: 'missing teams column: $c');
      }
    });

    test('a fresh DB starts with no rows', () async {
      expect(await db.getTeamCount(), 0);
    });
  });

  group('upgrade from v17 to v18 (seasons rollout)', () {
    late Directory tmpDir;
    late File dbFile;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('sac_mig_v17_');
      dbFile = File('${tmpDir.path}/test.db');
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('preserves pre-existing rows and back-fills season_id', () async {
      _seedV17DatabaseFile(dbFile);

      // Reopen the same file via AppDb — onUpgrade(17, 18) must run.
      final upgraded = AppDb.forTesting(NativeDatabase(dbFile));
      try {
        // Force the LazyDatabase / migration to actually execute.
        final tables = (await upgraded.listTables()).toSet();

        expect(tables, contains('seasons'), reason: 'v18 must create seasons');

        final seasons = await upgraded
            .customSelect('SELECT id, name, is_active FROM seasons')
            .get();
        expect(seasons, hasLength(1), reason: 'a default season must be seeded');
        expect(seasons.first.read<String>('name'), 'Default Season');

        // Pre-existing data preserved
        expect(await upgraded.getTeamCount(), 1);
        final team = (await upgraded
                .customSelect('SELECT name, season_id FROM teams WHERE id = 1')
                .get())
            .single;
        expect(team.read<String>('name'), 'Legacy FC');
        expect(team.read<int>('season_id'), seasons.first.read<int>('id'));

        final player = (await upgraded
                .customSelect(
                  'SELECT first_name, season_id FROM players WHERE id = 10',
                )
                .get())
            .single;
        expect(player.read<String>('first_name'), 'Old');
        expect(player.read<int>('season_id'), seasons.first.read<int>('id'));

        final game = (await upgraded
                .customSelect('SELECT team_score, season_id FROM games WHERE id = 100')
                .get())
            .single;
        expect(game.read<int>('team_score'), 2);
        expect(game.read<int>('season_id'), seasons.first.read<int>('id'));
      } finally {
        await upgraded.close();
      }
    });
  });
}

/// Bootstraps a sqlite file with the v17 schema, sample rows, and
/// `user_version = 17` — all via raw sqlite3 so Drift's `onCreate` is never
/// invoked. When AppDb later opens this file it will see version 17 and run
/// `onUpgrade(17, 18)`, which is the path under test.
void _seedV17DatabaseFile(File dbFile) {
  final db = sqlite.sqlite3.open(dbFile.path);
  try {
    db.execute('''
      CREATE TABLE teams (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        team_mode TEXT NOT NULL DEFAULT 'shift',
        half_duration_seconds INTEGER NOT NULL DEFAULT 1200,
        shift_length_seconds INTEGER NOT NULL DEFAULT 300,
        logo_image_path TEXT,
        primary_color1 TEXT,
        primary_color2 TEXT,
        primary_color3 TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE players (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        team_id INTEGER NOT NULL REFERENCES teams (id),
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        is_present INTEGER NOT NULL DEFAULT 1,
        jersey_number INTEGER,
        profile_image_path TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE games (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER,
        opponent TEXT,
        current_shift_id INTEGER,
        team_id INTEGER NOT NULL REFERENCES teams (id),
        is_archived INTEGER NOT NULL DEFAULT 0,
        current_half INTEGER NOT NULL DEFAULT 1,
        game_time_seconds INTEGER NOT NULL DEFAULT 0,
        is_game_active INTEGER NOT NULL DEFAULT 0,
        timer_start_time INTEGER,
        formation_id INTEGER,
        game_status TEXT NOT NULL DEFAULT 'in-progress',
        end_time INTEGER,
        team_score INTEGER NOT NULL DEFAULT 0,
        opponent_score INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE shifts (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL REFERENCES games (id),
        start_seconds INTEGER NOT NULL,
        end_seconds INTEGER,
        notes TEXT,
        actual_seconds INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE player_shifts (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        shift_id INTEGER NOT NULL REFERENCES shifts (id),
        player_id INTEGER NOT NULL REFERENCES players (id),
        position TEXT NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE player_metrics (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL REFERENCES players (id),
        game_id INTEGER NOT NULL REFERENCES games (id),
        metric TEXT NOT NULL,
        value INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE game_players (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL REFERENCES games (id),
        player_id INTEGER NOT NULL REFERENCES players (id),
        is_present INTEGER NOT NULL DEFAULT 1
      )
    ''');
    db.execute('''
      CREATE TABLE player_position_totals (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL REFERENCES players (id),
        position TEXT NOT NULL,
        total_seconds INTEGER NOT NULL DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE formations (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        team_id INTEGER NOT NULL REFERENCES teams (id),
        name TEXT NOT NULL,
        player_count INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE formation_positions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        formation_id INTEGER NOT NULL REFERENCES formations (id),
        "index" INTEGER NOT NULL,
        position_name TEXT NOT NULL,
        abbreviation TEXT NOT NULL DEFAULT ''
      )
    ''');

    db.execute(
      "INSERT INTO teams (id, name, is_archived, team_mode, half_duration_seconds, shift_length_seconds) "
      "VALUES (1, 'Legacy FC', 0, 'shift', 1200, 300)",
    );
    db.execute(
      "INSERT INTO players (id, team_id, first_name, last_name, is_present) "
      "VALUES (10, 1, 'Old', 'Player', 1)",
    );
    db.execute(
      "INSERT INTO games (id, team_id, current_half, game_time_seconds, is_game_active, "
      "game_status, team_score, opponent_score, is_archived) "
      "VALUES (100, 1, 1, 0, 0, 'completed', 2, 1, 0)",
    );

    db.execute('PRAGMA user_version = 17');
  } finally {
    db.dispose();
  }
}
