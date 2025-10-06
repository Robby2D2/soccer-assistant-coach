import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

const kPositions = <String>[
  'GOALIE',
  'RIGHT_DEFENSE',
  'LEFT_DEFENSE',
  'CENTER_FORWARD',
  'RIGHT_FORWARD',
  'LEFT_FORWARD',
];

class AssignPlayersScreen extends ConsumerWidget {
  final int gameId;
  final int shiftId;
  const AssignPlayersScreen({
    super.key,
    required this.gameId,
    required this.shiftId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Assign Players (Shift $shiftId)')),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, snapGame) {
          final game = snapGame.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Player>>(
            stream: db.watchPlayersByTeam(game.teamId),
            builder: (context, snapPlayers) {
              if (!snapPlayers.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final players = snapPlayers.data!;
              return StreamBuilder<List<GamePlayer>>(
                stream: db.watchAttendance(gameId),
                builder: (context, attendanceSnap) {
                  if (attendanceSnap.connectionState == ConnectionState.waiting && !attendanceSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final attendance = attendanceSnap.data ?? const <GamePlayer>[];
                  final filteredPlayers = <Player>[];
                  for (final p in players) {
                    GamePlayer? entry;
                    for (final a in attendance) {
                      if (a.playerId == p.id) {
                        entry = a;
                        break;
                      }
                    }
                    final isPresent = (entry?.isPresent) ?? p.isPresent;
                    if (isPresent) filteredPlayers.add(p);
                  }

                  if (filteredPlayers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No present players available for this game.'),
                      ),
                    );
                  }

                  return StreamBuilder<List<PlayerShift>>(
                    stream: db.watchAssignments(shiftId),
                    builder: (context, snapAssign) {
                      final assigns = (snapAssign.data ?? <PlayerShift>[]);
                      final map = {for (final a in assigns) a.playerId: a.position};
                      return ListView.separated(
                        itemCount: filteredPlayers.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (_, i) {
                          final p = filteredPlayers[i];
                          final current = map[p.id];
                          return ListTile(
                            title: Text('${p.firstName} ${p.lastName}'),
                            subtitle: Text('Player ID: ${p.id}'),
                            trailing: DropdownButton<String>(
                              value: current,
                              hint: const Text('Position'),
                              items: kPositions
                                  .map(
                                    (pos) => DropdownMenuItem(
                                      value: pos,
                                      child: Text(pos),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) async {
                                if (value != null) {
                                  await db.setPlayerPosition(
                                    shiftId: shiftId,
                                    playerId: p.id,
                                    position: value,
                                  );
                                }
                              },
                            ),
                          );
                        },
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
