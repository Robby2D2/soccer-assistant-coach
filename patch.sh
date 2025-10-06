bash -s <<'PATCH'
set -euo pipefail

# 1) --- Update schema: add GamePlayers (per-game attendance) ---
apply() {
  file="lib/data/db/schema.dart"
  tmp="$(mktemp)"
  awk '
    BEGIN{added=0}
    {print}
    END{
      # Only add GamePlayers class if not present
    }
  ' "$file" > "$tmp"
  if ! grep -q "class GamePlayers extends Table" "$tmp"; then
    cat >> "$tmp" <<'DART'

class GamePlayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId => integer().references(Games, #id)();
  IntColumn get playerId => integer().references(Players, #id)();
  BoolColumn get isPresent => boolean().withDefault(const Constant(true))();

  // Optional: prevent duplicates (gameId, playerId)
  // Drift cannot declare unique across multiple columns directly here,
  // but you can enforce in logic or create an index in migration if desired.
}
DART
  fi
  mv "$tmp" "$file"
}
apply

# 2) --- Update database: migration + attendance queries ---
cat > lib/data/db/database.dart <<'DART'
import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'schema.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Teams, Players, Games, Shifts, PlayerShifts, PlayerMetrics, GamePlayers])
class AppDb extends _$AppDb {
  AppDb() : super(SqfliteQueryExecutor.inDatabaseFolder(path: 'soccer_manager.db'));
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(gamePlayers);
      }
    },
  );
}

extension TeamQueries on AppDb {
  Future<int> addTeam(TeamsCompanion t) => into(teams).insert(t);
  Stream<List<Team>> watchTeams() => select(teams).watch();
  Future<Team?> getTeam(int id) => (select(teams)..where((t)=>t.id.equals(id))).getSingleOrNull();
  Future<void> updateTeamName(int id, String name) =>
    (update(teams)..where((t)=>t.id.equals(id))).write(TeamsCompanion(name: Value(name)));
  Future<void> deleteTeam(int id) => (delete(teams)..where((t) => t.id.equals(id))).go();
}

extension PlayerQueries on AppDb {
  Stream<List<Player>> watchPlayersByTeam(int teamId) =>
    (select(players)..where((p) => p.teamId.equals(teamId))).watch();
  Future<List<Player>> getPlayersByTeam(int teamId) =>
    (select(players)..where((p) => p.teamId.equals(teamId))).get();
  Future<Player?> getPlayer(int id) =>
    (select(players)..where((p)=>p.id.equals(id))).getSingleOrNull();
  Future<void> updatePlayer({required int id, required String firstName, required String lastName, required bool isPresent}) =>
    (update(players)..where((p)=>p.id.equals(id))).write(PlayersCompanion(
      firstName: Value(firstName), lastName: Value(lastName), isPresent: Value(isPresent),
    ));
  Future<void> deletePlayer(int id) => (delete(players)..where((p) => p.id.equals(id))).go();
}

extension GameQueries on AppDb {
  Future<int> addGame(GamesCompanion g) => into(games).insert(g);
  Stream<List<Game>> watchTeamGames(int teamId) =>
    (select(games)..where((g) => g.teamId.equals(teamId))).watch();
  Future<Game?> getGame(int id) => (select(games)..where((g) => g.id.equals(id))).getSingleOrNull();
  Future<void> updateGame({required int id, String? opponent, DateTime? startTime}) =>
    (update(games)..where((g)=>g.id.equals(id))).write(GamesCompanion(
      opponent: opponent == null ? const Value.absent() : Value(opponent),
      startTime: startTime == null ? const Value.absent() : Value(startTime),
    ));
  Future<void> deleteGame(int id) => (delete(games)..where((g) => g.id.equals(id))).go();
}

extension ShiftQueries on AppDb {
  Future<int> startShift(int gameId, int startSeconds, {String? notes}) =>
    into(shifts).insert(ShiftsCompanion.insert(gameId: gameId, startSeconds: startSeconds, notes: Value(notes)));
  Future<int> endShift(int shiftId, int endSeconds) =>
    (update(shifts)..where((s) => s.id.equals(shiftId))).write(ShiftsCompanion(endSeconds: Value(endSeconds)));
  Stream<List<Shift>> watchGameShifts(int gameId) =>
    (select(shifts)..where((s) => s.gameId.equals(gameId))).watch();
  Stream<Shift?> watchActiveShift(int gameId) =>
    (select(shifts)..where((s) => s.gameId.equals(gameId) & s.endSeconds.isNull())..orderBy([(s) => OrderingTerm.desc(s.id)])).watchSingleOrNull();
}

extension PlayerShiftQueries on AppDb {
  Future<void> setPlayerPosition({required int shiftId, required int playerId, required String position}) async {
    await (delete(playerShifts)..where((ps) => ps.shiftId.equals(shiftId) & ps.playerId.equals(playerId))).go();
    await into(playerShifts).insert(PlayerShiftsCompanion.insert(shiftId: shiftId, playerId: playerId, position: position));
  }
  Stream<List<PlayerShift>> watchAssignments(int shiftId) =>
    (select(playerShifts)..where((ps) => ps.shiftId.equals(shiftId))).watch();
}

extension PlayerMetricQueries on AppDb {
  Future<void> incrementMetric({required int gameId, required int playerId, required String metric}) async {
    final existing = await (select(playerMetrics)
      ..where((m) => m.gameId.equals(gameId) & m.playerId.equals(playerId) & m.metric.equals(metric)))
      .getSingleOrNull();
    if (existing == null) {
      await into(playerMetrics).insert(PlayerMetricsCompanion.insert(
        gameId: gameId, playerId: playerId, metric: metric, value: const Value(1)
      ));
    } else {
      await (update(playerMetrics)..where((m) => m.id.equals(existing.id))).write(
        PlayerMetricsCompanion(value: Value(existing.value + 1))
      );
    }
  }
  Stream<List<PlayerMetric>> watchMetricsForGame(int gameId) =>
    (select(playerMetrics)..where((m) => m.gameId.equals(gameId))).watch();
}

extension AttendanceQueries on AppDb {
  Future<void> setAttendance({required int gameId, required int playerId, required bool isPresent}) async {
    final existing = await (select(gamePlayers)
      ..where((gp) => gp.gameId.equals(gameId) & gp.playerId.equals(playerId))).getSingleOrNull();
    if (existing == null) {
      await into(gamePlayers).insert(GamePlayersCompanion.insert(
        gameId: gameId, playerId: playerId, isPresent: Value(isPresent),
      ));
    } else {
      await (update(gamePlayers)..where((gp) => gp.id.equals(existing.id))).write(
        GamePlayersCompanion(isPresent: Value(isPresent))
      );
    }
  }

  Stream<List<GamePlayer>> watchAttendance(int gameId) =>
    (select(gamePlayers)..where((gp) => gp.gameId.equals(gameId))).watch();

  Future<List<Player>> presentPlayersForGame(int gameId, int teamId) async {
    final attendance = await (select(gamePlayers)..where((gp) => gp.gameId.equals(gameId) & gp.isPresent.equals(true))).get();
    if (attendance.isEmpty) return [];
    final ids = attendance.map((a) => a.playerId).toList();
    return (select(players)..where((p) => p.teamId.equals(teamId) & p.id.isIn(ids))).get();
  }
}
DART

# 3) --- New Attendance screen ---
mkdir -p lib/features/games
cat > lib/features/games/attendance_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';

class AttendanceScreen extends ConsumerWidget {
  final int gameId;
  const AttendanceScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, gameSnap) {
          final game = gameSnap.data;
          if (game == null) return const Center(child: CircularProgressIndicator());
          return StreamBuilder<List<Player>>(
            stream: db.watchPlayersByTeam(game.teamId),
            builder: (context, playersSnap) {
              if (!playersSnap.hasData) return const Center(child: CircularProgressIndicator());
              final players = playersSnap.data!;
              return StreamBuilder<List<GamePlayer>>(
                stream: db.watchAttendance(gameId),
                builder: (context, attSnap) {
                  final att = { for (final a in (attSnap.data ?? <GamePlayer>[])) a.playerId: a.isPresent };
                  return ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final p = players[i];
                      final present = att[p.id] ?? false;
                      return SwitchListTile(
                        title: Text('${p.firstName} ${p.lastName}'),
                        value: present,
                        onChanged: (v) => db.setAttendance(gameId: gameId, playerId: p.id, isPresent: v),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
DART

# 4) --- Update Lineup builder to use per-game attendance ---
awk '
  /class LineupBuilderScreen/ {print; in_class=1; next}
  {print}
' lib/features/games/lineup_builder_screen.dart > /dev/null 2>&1 || true

cat > lib/features/games/lineup_builder_screen.dart <<'DART'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';

class LineupBuilderScreen extends ConsumerWidget {
  final int gameId;
  const LineupBuilderScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lineup Builder')),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, gSnap) {
          final game = gSnap.data;
          if (game == null) return const Center(child: CircularProgressIndicator());
          return FutureBuilder<List<Player>>(
            future: db.presentPlayersForGame(gameId, game.teamId),
            builder: (context, pSnap) {
              if (!pSnap.hasData) return const Center(child: CircularProgressIndicator());
              final present = pSnap.data!;
              return _Formations(
                present: present,
                onApply: (positions) async {
                  final shiftId =  await db.startShift(gameId, 0, notes: 'Lineup');
                  for (var i = 0; i < positions.length && i < present.length; i++) {
                    await db.setPlayerPosition(shiftId: shiftId, playerId: present[i].id, position: positions[i]);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Formations extends StatefulWidget {
  final List<Player> present;
  final Future<void> Function(List<String> positions) onApply;
  const _Formations({required this.present, required this.onApply});

  @override
  State<_Formations> createState() => _FormationsState();
}

class _FormationsState extends State<_Formations> {
  String _formation = '2-3-1';

  List<String> get _positions {
    switch (_formation) {
      case '3-2-1':
        return ['GOALIE','RIGHT_DEFENSE','LEFT_DEFENSE','CENTER_FORWARD','RIGHT_FORWARD','LEFT_FORWARD'];
      case '2-2-2':
        return ['GOALIE','RIGHT_DEFENSE','LEFT_DEFENSE','CENTER_FORWARD','RIGHT_FORWARD','LEFT_FORWARD'];
      case '2-3-1':
      default:
        return ['GOALIE','RIGHT_DEFENSE','LEFT_DEFENSE','CENTER_FORWARD','RIGHT_FORWARD','LEFT_FORWARD'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final positions = _positions;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Present players: ${widget.present.length}'),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: _formation,
            items: const [
              DropdownMenuItem(value: '2-3-1', child: Text('2-3-1')),
              DropdownMenuItem(value: '3-2-1', child: Text('3-2-1')),
              DropdownMenuItem(value: '2-2-2', child: Text('2-2-2')),
            ],
            onChanged: (v) => setState(() => _formation = v!),
          ),
          const SizedBox(height: 16),
          Text('Will assign first ${positions.length} present players to:'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: positions.map((p) => Chip(label: Text(p))).toList()),
          const Spacer(),
          FilledButton(onPressed: () => widget.onApply(positions), child: const Text('Apply to new shift')),
        ],
      ),
    );
  }
}
DART

# 5) --- Add Attendance button + route wiring ---
# Game screen button (Attendance)
apply_game_screen() {
  f="lib/features/games/game_screen.dart"
  if grep -q "attendance" "$f"; then return; fi
  sed -i '' 's/metrics'), icon: const Icon(Icons.leaderboard)),/&\n          IconButton(onPressed: () => context.push('"'"'/game\/$gameId\/attendance'"'"'), icon: const Icon(Icons.check_circle)),/' "$f" 2>/dev/null || \
  perl -0777 -pe "s|(metrics'), icon: const Icon\\(Icons\\.leaderboard\\)\\),|\\1),\n          IconButton(onPressed: () => context.push('/game/\$gameId/attendance'), icon: const Icon(Icons.check_circle)),|s" -i "$f"
}
apply_game_screen || true

# Router: add route
apply_router() {
  f="lib/core/router.dart"
  if ! grep -q "attendance_screen.dart" "$f"; then
    perl -0777 -pe "s|(import '../features/games/game_edit_screen.dart';)|\\1\nimport '../features/games/attendance_screen.dart';|s" -i "$f"
  fi
  if ! grep -q "/attendance" "$f"; then
    perl -0777 -pe "s|(GoRoute\\(path: '/game/:id/lineup'.*?\\),)|\\1,\n    GoRoute(path: '/game/:id/attendance', builder: (_, s) => AttendanceScreen(gameId: int.parse(s.pathParameters['id']!))),|s" -i "$f"
  fi
}
apply_router || true

echo "Patch applied ✓  — now run:
  flutter pub get
  dart run build_runner build -d
  flutter run
"
PATCH

