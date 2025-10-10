import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../utils/files.dart';

class MetricsOverviewScreen extends ConsumerWidget {
  final int gameId;
  const MetricsOverviewScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Game?>(
          future: db.getGame(gameId),
          builder: (context, gameSnap) {
            final game = gameSnap.data;
            if (game == null) {
              return const Text('Metrics Overview');
            }
            return FutureBuilder<Team?>(
              future: db.getTeam(game.teamId),
              builder: (context, teamSnap) {
                final team = teamSnap.data;
                final teamName = team?.name ?? 'Team';
                final opponent = game.opponent?.isNotEmpty == true
                    ? game.opponent!
                    : 'Opponent';
                final dateTime = game.startTime != null
                    ? _formatDateTime(game.startTime!)
                    : '';

                // Try full format first, fallback to shorter versions if needed
                final fullTitle =
                    '$teamName vs $opponent${dateTime.isNotEmpty ? ' • $dateTime' : ''}';
                return Text(
                  'Metrics: $fullTitle',
                  overflow: TextOverflow.ellipsis,
                );
              },
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Input Metrics',
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/game/$gameId/metrics/input');
            },
          ),
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

              // Get playing time based on team mode
              final teamMode = await db.getTeamMode(game.teamId);
              final playedSeconds = teamMode == 'traditional'
                  ? await db.getTraditionalPlayingTimeByPlayer(gameId)
                  : await db.playedSecondsByPlayer(gameId);
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
                  // Determine which playing time data to use based on team mode
                  return FutureBuilder<String>(
                    future: db.getTeamMode(game.teamId),
                    builder: (context, teamModeSnap) {
                      if (!teamModeSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final isTraditionalMode =
                          teamModeSnap.data == 'traditional';

                      return StreamBuilder<Map<int, int>>(
                        stream: isTraditionalMode
                            ? db.watchTraditionalPlayingTimeByPlayer(gameId)
                            : db.watchPlayedSecondsByPlayer(gameId),
                        builder: (context, playedSnap) {
                          final playedSeconds =
                              playedSnap.data ?? const <int, int>{};

                          // Calculate team totals for summary
                          final totalGoals = agg.values.fold(
                            0,
                            (sum, player) => sum + (player['GOAL'] ?? 0),
                          );
                          final totalAssists = agg.values.fold(
                            0,
                            (sum, player) => sum + (player['ASSIST'] ?? 0),
                          );
                          final totalSaves = agg.values.fold(
                            0,
                            (sum, player) => sum + (player['SAVE'] ?? 0),
                          );
                          final totalPlayTime = playedSeconds.values.fold(
                            0,
                            (sum, seconds) => sum + seconds,
                          );

                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Team Summary Card
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.analytics),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Team Summary',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _SummaryItem(
                                            icon: Icons.sports_soccer,
                                            label: 'Goals',
                                            value: totalGoals.toString(),
                                          ),
                                          _SummaryItem(
                                            icon: Icons.sports,
                                            label: 'Assists',
                                            value: totalAssists.toString(),
                                          ),
                                          _SummaryItem(
                                            icon: Icons.sports_handball,
                                            label: 'Saves',
                                            value: totalSaves.toString(),
                                          ),
                                          _SummaryItem(
                                            icon: Icons.timer,
                                            label: 'Total Play Time',
                                            value: _formatMinutes(
                                              totalPlayTime / 60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Playing Time Chart
                              if (playedSeconds.isNotEmpty) ...[
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.bar_chart),
                                          title: Text('Playing Time Analysis'),
                                          subtitle: Text(
                                            'Total time per player in this game',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _PlaytimeBarChart(
                                          entries:
                                              playedSeconds.entries.toList()
                                                ..sort(
                                                  (a, b) => b.value.compareTo(
                                                    a.value,
                                                  ),
                                                ),
                                          playersById: playersById,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Player Metrics Table
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.table_chart),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Player Statistics',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _PlayerMetricsTable(
                                        players: players,
                                        metricsAgg: agg,
                                        playedSeconds: playedSeconds,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PlaytimeBarChart extends StatelessWidget {
  const _PlaytimeBarChart({required this.entries, required this.playersById});

  final List<MapEntry<int, int>> entries; // playerId -> seconds
  final Map<int, Player> playersById;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('No play time recorded yet.');
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

class _PlayerMetricsTable extends StatelessWidget {
  const _PlayerMetricsTable({
    required this.players,
    required this.metricsAgg,
    required this.playedSeconds,
  });

  final List<Player> players;
  final Map<int, Map<String, int>> metricsAgg;
  final Map<int, int> playedSeconds;

  @override
  Widget build(BuildContext context) {
    // Sort players by total contribution (goals + assists + saves)
    final sortedPlayers = [...players]
      ..sort((a, b) {
        final aMetrics = metricsAgg[a.id] ?? <String, int>{};
        final bMetrics = metricsAgg[b.id] ?? <String, int>{};
        final aTotal =
            (aMetrics['GOAL'] ?? 0) +
            (aMetrics['ASSIST'] ?? 0) +
            (aMetrics['SAVE'] ?? 0);
        final bTotal =
            (bMetrics['GOAL'] ?? 0) +
            (bMetrics['ASSIST'] ?? 0) +
            (bMetrics['SAVE'] ?? 0);
        return bTotal.compareTo(aTotal);
      });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Player')),
          DataColumn(label: Text('Play Time')),
          DataColumn(label: Text('Goals')),
          DataColumn(label: Text('Assists')),
          DataColumn(label: Text('Saves')),
          DataColumn(label: Text('Total')),
        ],
        rows: sortedPlayers.map((player) {
          final metrics = metricsAgg[player.id] ?? <String, int>{};
          final goals = metrics['GOAL'] ?? 0;
          final assists = metrics['ASSIST'] ?? 0;
          final saves = metrics['SAVE'] ?? 0;
          final total = goals + assists + saves;
          final seconds = playedSeconds[player.id] ?? 0;
          final minutesText = _formatMinutes(seconds / 60.0);

          return DataRow(
            cells: [
              DataCell(Text('${player.firstName} ${player.lastName}')),
              DataCell(Text(minutesText)),
              DataCell(Text(goals.toString())),
              DataCell(Text(assists.toString())),
              DataCell(Text(saves.toString())),
              DataCell(
                Text(
                  total.toString(),
                  style: total > 0
                      ? TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              ),
            ],
          );
        }).toList(),
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

String _formatMinutes(double minutes) {
  if (minutes < 1) {
    return '${(minutes * 60).round()}s';
  }
  return '${minutes.toStringAsFixed(1)}m';
}

String _formatDateTime(DateTime dt) {
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$month/$day • $hour:$minute';
}
