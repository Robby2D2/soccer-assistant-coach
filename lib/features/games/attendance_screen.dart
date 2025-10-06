import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

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
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Player>>(
            stream: db.watchPlayersByTeam(game.teamId),
            builder: (context, playersSnap) {
              if (!playersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final players = playersSnap.data!;
              return StreamBuilder<List<GamePlayer>>(
                stream: db.watchAttendance(gameId),
                builder: (context, attSnap) {
                  final att = {
                    for (final a in (attSnap.data ?? <GamePlayer>[]))
                      a.playerId: a.isPresent,
                  };
                  return ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) {
                      final p = players[i];
                      final present = att[p.id] ?? false;
                      return SwitchListTile(
                        title: Text('${p.firstName} ${p.lastName}'),
                        value: present,
                        onChanged: (v) => db.setAttendance(
                          gameId: gameId,
                          playerId: p.id,
                          isPresent: v,
                        ),
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
