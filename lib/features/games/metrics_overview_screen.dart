import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../utils/files.dart';
import '../../core/game_scaffold.dart';
import '../../core/sideline.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/sideline_widgets.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class MetricsOverviewScreen extends ConsumerWidget {
  final int gameId;
  const MetricsOverviewScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return GameScaffold(
      gameId: gameId,
      appBar: TeamAppBar(
        title: GameCompactTitle(gameId: gameId),
        actions: StandardizedAppBarActions.createActionsWidgets([
          CommonNavigationActions.inputMetrics(context, gameId),
          CommonNavigationActions.export(context, () async {
            final game = await db.getGame(gameId);
            if (game == null) return;
            final players = await db.getPlayersByTeam(game.teamId);
            final metrics = await db.watchMetricsForGame(gameId).first;
            final per = <int, Map<String, int>>{};
            for (final m in metrics) {
              final map = per.putIfAbsent(m.playerId, () => {});
              map[m.metric] = (map[m.metric] ?? 0) + m.value;
            }
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
          }),
        ]),
      ),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, snapGame) {
          final game = snapGame.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Player>>(
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final isTraditionalMode =
                                teamModeSnap.data == 'traditional';

                            return StreamBuilder<Map<int, int>>(
                              stream: isTraditionalMode
                                  ? db.watchTraditionalPlayingTimeByPlayer(
                                      gameId,
                                    )
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
                                  (sum, player) =>
                                      sum + (player['ASSIST'] ?? 0),
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
                                                  value: totalAssists
                                                      .toString(),
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

                                    // Per-player playing time bars with
                                    // goals/assists/saves alongside each bar.
                                    if (playedSeconds.isNotEmpty ||
                                        agg.isNotEmpty) ...[
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
                                                title: Text(
                                                  'Player Performance',
                                                ),
                                                subtitle: Text(
                                                  'Play time, goals, assists and saves per player',
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              _PlaytimeBarChart(
                                                playedSeconds: playedSeconds,
                                                metricsAgg: agg,
                                                playersById: playersById,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }, // end StreamBuilder<Map<int, int>>
                    ); // end FutureBuilder
                  }, // end StreamBuilder<List<PlayerMetric>>
                ), // end StreamBuilder<List<Player>>
              ), // end Expanded
            ], // end Column children
          ); // end Column
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
  const _PlaytimeBarChart({
    required this.playedSeconds,
    required this.metricsAgg,
    required this.playersById,
  });

  final Map<int, int> playedSeconds; // playerId -> seconds
  final Map<int, Map<String, int>> metricsAgg; // playerId -> metric -> count
  final Map<int, Player> playersById;

  @override
  Widget build(BuildContext context) {
    // Include every player with recorded play time OR recorded metrics, so a
    // goal scorer without tracked minutes still shows up.
    final playerIds = <int>{...playedSeconds.keys, ...metricsAgg.keys};
    if (playerIds.isEmpty) {
      return const Text('No play time or stats recorded yet.');
    }
    final entries =
        playerIds
            .map((id) => MapEntry(id, playedSeconds[id] ?? 0))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final maxSeconds = entries.first.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barMaxWidth = constraints.maxWidth;
        return Column(
          children: [
            for (final entry in entries)
              _PlaytimeBarRow(
                player: playersById[entry.key],
                seconds: entry.value,
                fraction: maxSeconds > 0 ? entry.value / maxSeconds : 0,
                barMaxWidth: barMaxWidth,
                metrics: metricsAgg[entry.key] ?? const <String, int>{},
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
    required this.metrics,
  });

  final Player? player;
  final int seconds;
  final double fraction; // 0..1
  final double barMaxWidth;
  final Map<String, int> metrics; // metric -> count

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = teamColorsOf(context).team;
    final surfaceVariant = SidelineColors.hairline;
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
              _StatCount(icon: Icons.sports_soccer, count: metrics['GOAL'] ?? 0),
              _StatCount(icon: Icons.sports, count: metrics['ASSIST'] ?? 0),
              _StatCount(
                icon: Icons.sports_handball,
                count: metrics['SAVE'] ?? 0,
              ),
              Text(
                _hhmmss(seconds),
                style: sidelineMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SidelineColors.muted,
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
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
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

/// A compact icon + count pair shown beside a player's playtime bar. Hidden
/// when the count is zero so rows stay uncluttered. The icons match the Team
/// Summary card (goal / assist / save).
class _StatCount extends StatelessWidget {
  const _StatCount({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
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

String _formatMinutes(double minutes) {
  if (minutes < 1) {
    return '${(minutes * 60).round()}s';
  }
  return '${minutes.toStringAsFixed(1)}m';
}

// Removed legacy date formatting and compact header (now using TeamBrandedHeader in scaffold body).
