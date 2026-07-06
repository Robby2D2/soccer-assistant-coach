import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/sideline.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/sideline_header.dart';
import '../../widgets/sideline_widgets.dart';
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
      header: SidelineScreenHeader(
        teamId: teamId,
        subtitle: 'Season stats',
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
      body: FutureBuilder<(Team?, TeamMetricsSummary, TeamRecord)>(
        future:
            Future.wait([
              db.getTeam(teamId),
              db.getTeamMetricsSummary(teamId),
              db.getTeamRecord(teamId),
            ]).then(
              (results) => (
                results[0] as Team?,
                results[1] as TeamMetricsSummary,
                results[2] as TeamRecord,
              ),
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

          final (team, summary, record) = snapshot.data!;
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
                // Headline: record + goals for / against.
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'RECORD',
                        value: record.recordLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        label: 'GF/GA',
                        value: record.goalDifferenceLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Top scorers.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Top scorers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: SidelineColors.ink,
                      ),
                    ),
                    const Text(
                      'this season',
                      style: TextStyle(
                        fontSize: 13,
                        color: SidelineColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TopScorers(players: summary.playerMetrics),
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

}

/// A headline stat card: uppercase mono label over a big mono value.
class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: SidelineColors.surface,
        borderRadius: BorderRadius.circular(SidelineRadius.row),
        border: Border.all(color: SidelineColors.hairline),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: sidelineMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SidelineColors.muted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: sidelineMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: SidelineColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Top scorers list — players with goals, most first, as clean Sideline rows.
class _TopScorers extends StatelessWidget {
  const _TopScorers({required this.players});

  final List<PlayerTeamMetrics> players;

  @override
  Widget build(BuildContext context) {
    final scorers = [...players.where((p) => p.totalGoals > 0)]
      ..sort((a, b) => b.totalGoals.compareTo(a.totalGoals));
    if (scorers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SidelineColors.surface,
          borderRadius: BorderRadius.circular(SidelineRadius.row),
          border: Border.all(color: SidelineColors.hairline),
        ),
        child: const Text(
          'No goals recorded yet.',
          style: TextStyle(color: SidelineColors.muted),
        ),
      );
    }
    final team = teamColorsOf(context);
    return Column(
      children: [
        for (final p in scorers.take(8))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: SidelineColors.surface,
              borderRadius: BorderRadius.circular(SidelineRadius.row),
              border: Border.all(color: SidelineColors.hairline),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: team.team,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    p.jerseyNumber?.toString() ?? '–',
                    style: sidelineMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: team.onTeam,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${p.firstName} ${p.lastName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SidelineColors.ink,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${p.totalGoals}',
                      style: sidelineMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SidelineColors.ink,
                      ),
                    ),
                    const Text(
                      'goals',
                      style: TextStyle(
                        fontSize: 11,
                        color: SidelineColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
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
