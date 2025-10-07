import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../utils/files.dart';

class MetricsScreen extends ConsumerWidget {
  final int gameId;
  const MetricsScreen({super.key, required this.gameId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Metrics (Game $gameId)'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final game = await db.getGame(gameId);
              if (game == null) return;
              final players = await db.getPlayersByTeam(game.teamId);
              final metrics = await db.watchMetricsForGame(gameId).first;
              final per = <int, Map<String, int>>{};
              for (final m in metrics) {
                final map = per.putIfAbsent(m.playerId, () => {});
                map[m.metric] = (map[m.metric] ?? 0) + m.value;
              }
              final playedSeconds = await db.playedSecondsByPlayer(gameId);
              final buffer = StringBuffer();
              buffer.writeln(
                'playerId,firstName,lastName,minutesPlayed,GOAL,ASSIST,SAVE',
              );
              for (final p in players) {
                final mp = per[p.id] ?? const {};
                final minutes = (playedSeconds[p.id] ?? 0) / 60.0;
                buffer.writeln(
                  '${p.id},${p.firstName},${p.lastName},${minutes.toStringAsFixed(1)},${mp['GOAL'] ?? 0},${mp['ASSIST'] ?? 0},${mp['SAVE'] ?? 0}',
                );
              }
              final path = await saveTextFile(
                'game_${gameId}_metrics.csv',
                buffer.toString(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Saved CSV to $path')));
              }
            },
          ),
        ],
      ),
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
              final playersById = {for (final p in players) p.id: p};
              return StreamBuilder<List<PlayerMetric>>(
                stream: db.watchMetricsForGame(gameId),
                builder: (context, snapMetrics) {
                  final metrics = (snapMetrics.data ?? <PlayerMetric>[]);
                  final Map<int, Map<String, int>> agg = {};
                  for (final m in metrics) {
                    agg.putIfAbsent(m.playerId, () => {});
                    agg[m.playerId]![m.metric] = m.value;
                  }
                  return StreamBuilder<Map<int, int>>(
                    stream: db.watchPlayedSecondsByPlayer(gameId),
                    builder: (context, playedSnap) {
                      final playedSeconds =
                          playedSnap.data ?? const <int, int>{};
                      return ListView.separated(
                        itemCount: players.length + 1,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            // Chart header
                            if (playedSeconds.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No play time recorded yet.'),
                              );
                            }
                            final entries = playedSeconds.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));
                            return Padding(
                              padding: const EdgeInsets.all(12),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(Icons.bar_chart),
                                        title: Text('Play Time'),
                                        subtitle: Text(
                                          'Total time per player in this game',
                                        ),
                                      ),
                                      _PlaytimeBarChart(
                                        entries: entries,
                                        playersById: playersById,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          final p = players[i - 1];
                          final mv = agg[p.id] ?? const {};
                          final seconds = playedSeconds[p.id] ?? 0;
                          final minutesText = (seconds / 60.0).toStringAsFixed(
                            1,
                          );
                          return ListTile(
                            title: Text('${p.firstName} ${p.lastName}'),
                            subtitle: Text(
                              'Min:$minutesText  G:${mv['GOAL'] ?? 0}  A:${mv['ASSIST'] ?? 0}  S:${mv['SAVE'] ?? 0}',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () => db.incrementMetric(
                                    gameId: gameId,
                                    playerId: p.id,
                                    metric: 'GOAL',
                                  ),
                                  child: const Text('＋Goal'),
                                ),
                                OutlinedButton(
                                  onPressed: () => db.incrementMetric(
                                    gameId: gameId,
                                    playerId: p.id,
                                    metric: 'ASSIST',
                                  ),
                                  child: const Text('＋Assist'),
                                ),
                                OutlinedButton(
                                  onPressed: () => db.incrementMetric(
                                    gameId: gameId,
                                    playerId: p.id,
                                    metric: 'SAVE',
                                  ),
                                  child: const Text('＋Save'),
                                ),
                              ],
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

class _PlaytimeBarChart extends StatelessWidget {
  const _PlaytimeBarChart({required this.entries, required this.playersById});

  final List<MapEntry<int, int>> entries; // playerId -> seconds
  final Map<int, Player> playersById;

  @override
  Widget build(BuildContext context) {
    // theme variable removed (unused)
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxSeconds = entries
        .map((e) => e.value)
        .fold<int>(0, (p, c) => c > p ? c : p);
    if (maxSeconds <= 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final barMaxWidth = constraints.maxWidth;
        return Column(
          children: [
            for (final entry in entries)
              _PlaytimeBarRow(
                player: playersById[entry.key],
                seconds: entry.value,
                fraction: entry.value / maxSeconds,
                barMaxWidth: barMaxWidth,
              ),
          ],
        );
      },
    );
  }
}

class _PlaytimeBarRow extends StatelessWidget {
  const _PlaytimeBarRow({
    required this.player,
    required this.seconds,
    required this.fraction,
    required this.barMaxWidth,
  });

  final Player? player;
  final int seconds;
  final double fraction; // 0..1
  final double barMaxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final name = player == null
        ? 'Player #?'
        : '${player!.firstName} ${player!.lastName}';

    final barWidth = (barMaxWidth * fraction).clamp(0.0, barMaxWidth);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _hhmmss(seconds),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(
                  width: barMaxWidth,
                  decoration: BoxDecoration(
                    color: surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _hhmmss(int s) {
  final h = (s ~/ 3600).toString().padLeft(2, '0');
  final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return '$h:$m:$sec';
}
