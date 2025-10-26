import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/team_header.dart';
import '../../utils/files.dart';
import '../../widgets/player_avatar.dart';
import '../teams/data/team_metrics_models.dart';

class TeamMetricsOverviewScreen extends ConsumerWidget {
  final int teamId;
  const TeamMetricsOverviewScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return TeamScaffold(
      teamId: teamId,
      appBar: TeamAppBar(
        teamId: teamId,
        titleText: 'Team Metrics',
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final summary = await db.getTeamMetricsSummary(teamId);
              final buffer = StringBuffer();
              buffer.writeln(
                'playerId,firstName,lastName,totalMinutesPlayed,gamesPlayed,avgMinutesPerGame,totalGoals,totalAssists,totalSaves,totalMetrics',
              );
              for (final p in summary.playerMetrics) {
                final avgMinutes = p.averagePlayTimeMinutesPerGame;
                final totalMinutes = p.totalPlayTimeMinutes;
                buffer.writeln(
                  '${p.playerId},${p.firstName},${p.lastName},${totalMinutes.toStringAsFixed(1)},${p.gamesPlayed},${avgMinutes.toStringAsFixed(1)},${p.totalGoals},${p.totalAssists},${p.totalSaves},${p.totalMetrics}',
                );
              }
              final path = await saveTextFile(
                'team_${teamId}_metrics.csv',
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
      body: FutureBuilder<(Team?, TeamMetricsSummary)>(
        future:
            Future.wait([
              db.getTeam(teamId),
              db.getTeamMetricsSummary(teamId),
            ]).then(
              (results) =>
                  (results[0] as Team?, results[1] as TeamMetricsSummary),
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading team metrics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final (team, summary) = snapshot.data!;
          if (team == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Team not found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }
          if (summary.playerMetrics.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No metrics data yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Metrics will appear here after games are played',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Sort players by total metrics (goals + assists + saves) descending
          final sortedPlayers = [...summary.playerMetrics]
            ..sort((a, b) => b.totalMetrics.compareTo(a.totalMetrics));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TeamBrandedHeader(
                    teamId: teamId,
                    subtitle: 'Season Performance Summary',
                    title: 'Team Metrics',
                  ),
                ),
                // Team Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics),
                            const SizedBox(width: 8),
                            Text(
                              'Team Overview',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.5,
                          children: [
                            _SummaryItem(
                              icon: Icons.sports_soccer,
                              label: 'Total Games',
                              value: summary.totalGames.toString(),
                            ),
                            _SummaryItem(
                              icon: Icons.timer,
                              label: 'Total Play Time',
                              value: _formatMinutes(
                                summary.totalPlayTimeMinutes,
                              ),
                            ),
                            _SummaryItem(
                              icon: Icons.sports_soccer,
                              label: 'Total Goals',
                              value: summary.totalGoals.toString(),
                            ),
                            _SummaryItem(
                              icon: Icons.sports,
                              label: 'Total Assists',
                              value: summary.totalAssists.toString(),
                            ),
                            _SummaryItem(
                              icon: Icons.sports_handball,
                              label: 'Total Saves',
                              value: summary.totalSaves.toString(),
                            ),
                            _SummaryItem(
                              icon: Icons.trending_up,
                              label: 'Avg Goals/Game',
                              value: summary.averageGoalsPerGame
                                  .toStringAsFixed(1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Playing Time Chart
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.bar_chart),
                          title: Text('Total Playing Time'),
                          subtitle: Text('Minutes played across all games'),
                        ),
                        const SizedBox(height: 8),
                        _PlaytimeBarChart(
                          entries: sortedPlayers
                              .map(
                                (p) => MapEntry(
                                  p.playerId,
                                  p.totalPlayTimeSeconds,
                                ),
                              )
                              .toList(),
                          playersById: {
                            for (final p in summary.playerMetrics)
                              p.playerId: Player(
                                id: p.playerId,
                                teamId: teamId,
                                seasonId: team.seasonId,
                                firstName: p.firstName,
                                lastName: p.lastName,
                                isPresent: true,
                                jerseyNumber: p.jerseyNumber,
                                profileImagePath: p.profileImagePath,
                              ),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Player Statistics Table
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.table_chart),
                            const SizedBox(width: 8),
                            Text(
                              'Player Statistics',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _PlayerMetricsTable(playerMetrics: sortedPlayers),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMinutes(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)} min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = (minutes % 60).round();
    return '${hours}h ${remainingMinutes}m';
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _PlaytimeBarChart extends StatelessWidget {
  const _PlaytimeBarChart({required this.entries, required this.playersById});

  final List<MapEntry<int, int>> entries;
  final Map<int, Player> playersById;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final maxSeconds = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    if (maxSeconds == 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final surfaceVariant = colorScheme.surfaceContainerHighest;

    return Column(
      children: entries.take(10).map((entry) {
        final player = playersById[entry.key];
        if (player == null) return const SizedBox.shrink();

        final seconds = entry.value;
        final minutes = seconds / 60.0;
        final percentage = seconds / maxSeconds;
        const barMaxWidth = 200.0;
        final barWidth = barMaxWidth * percentage;

        final color = colorScheme.primary;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlayerAvatar(
                    firstName: player.firstName,
                    lastName: player.lastName,
                    jerseyNumber: player.jerseyNumber,
                    profileImagePath: player.profileImagePath,
                    radius: 12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${player.firstName} ${player.lastName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${minutes.toStringAsFixed(0)} min',
                    style: Theme.of(context).textTheme.bodySmall,
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
      }).toList(),
    );
  }
}

class _PlayerMetricsTable extends StatelessWidget {
  const _PlayerMetricsTable({required this.playerMetrics});

  final List<PlayerTeamMetrics> playerMetrics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Player')),
          DataColumn(label: Text('Games')),
          DataColumn(label: Text('Total Min')),
          DataColumn(label: Text('Avg Min')),
          DataColumn(label: Text('Goals')),
          DataColumn(label: Text('Assists')),
          DataColumn(label: Text('Saves')),
          DataColumn(label: Text('Total')),
        ],
        rows: playerMetrics.map((player) {
          final totalMinutes = player.totalPlayTimeMinutes;
          final avgMinutes = player.averagePlayTimeMinutesPerGame;
          final totalMetrics = player.totalMetrics;

          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayerAvatar(
                      firstName: player.firstName,
                      lastName: player.lastName,
                      jerseyNumber: player.jerseyNumber,
                      profileImagePath: player.profileImagePath,
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${player.firstName} ${player.lastName}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(player.gamesPlayed.toString())),
              DataCell(Text('${totalMinutes.toStringAsFixed(0)} min')),
              DataCell(Text('${avgMinutes.toStringAsFixed(1)} min')),
              DataCell(Text(player.totalGoals.toString())),
              DataCell(Text(player.totalAssists.toString())),
              DataCell(Text(player.totalSaves.toString())),
              DataCell(
                Text(
                  totalMetrics.toString(),
                  style: totalMetrics > 0
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
