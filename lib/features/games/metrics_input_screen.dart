import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../widgets/player_avatar.dart';

class MetricsInputScreen extends ConsumerStatefulWidget {
  final int gameId;
  const MetricsInputScreen({super.key, required this.gameId});

  @override
  ConsumerState<MetricsInputScreen> createState() => _MetricsInputScreenState();
}

class _MetricsInputScreenState extends ConsumerState<MetricsInputScreen> {
  String _selectedMetric = 'GOAL';
  final List<String> _availableMetrics = ['GOAL', 'ASSIST', 'SAVE'];

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Game?>(
          future: db.getGame(widget.gameId),
          builder: (context, gameSnap) {
            final game = gameSnap.data;
            if (game == null) {
              return const Text('Input Metrics');
            }
            final opponent = game.opponent?.isNotEmpty == true
                ? game.opponent!
                : 'Opponent';

            // For input screen, keep it shorter - just "Input vs Opponent"
            return Text('Input vs $opponent', overflow: TextOverflow.ellipsis);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'View Analytics',
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: FutureBuilder<Game?>(
        future: db.getGame(widget.gameId),
        builder: (context, snapGame) {
          final game = snapGame.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              // Metric Type Selection
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Metric Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _availableMetrics.map((metric) {
                          final isSelected = _selectedMetric == metric;
                          return FilterChip(
                            selected: isSelected,
                            label: Text(_getMetricDisplayName(metric)),
                            avatar: Icon(_getMetricIcon(metric), size: 18),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedMetric = metric);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Player List
              Expanded(
                child: StreamBuilder<List<Player>>(
                  stream: db.watchPlayersByTeam(game.teamId),
                  builder: (context, snapPlayers) {
                    if (!snapPlayers.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final players = snapPlayers.data!;

                    return StreamBuilder<List<PlayerMetric>>(
                      stream: db.watchMetricsForGame(widget.gameId),
                      builder: (context, snapMetrics) {
                        final metrics = (snapMetrics.data ?? <PlayerMetric>[]);
                        final Map<int, Map<String, int>> agg = {};
                        for (final m in metrics) {
                          agg.putIfAbsent(m.playerId, () => {});
                          agg[m.playerId]![m.metric] = m.value;
                        }

                        // Sort players alphabetically for consistent order
                        final sortedPlayers = [...players]
                          ..sort((a, b) {
                            final aName = '${a.firstName} ${a.lastName}';
                            final bName = '${b.firstName} ${b.lastName}';
                            return aName.compareTo(bName);
                          });

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedPlayers.length,
                          itemBuilder: (context, index) {
                            final player = sortedPlayers[index];
                            final playerMetrics =
                                agg[player.id] ?? <String, int>{};
                            final currentValue =
                                playerMetrics[_selectedMetric] ?? 0;

                            return Card(
                              child: ListTile(
                                leading: PlayerAvatar(
                                  firstName: player.firstName,
                                  lastName: player.lastName,
                                  jerseyNumber: player.jerseyNumber,
                                  profileImagePath: player.profileImagePath,
                                  radius: 20,
                                ),
                                title: Text(
                                  '${player.firstName} ${player.lastName}',
                                ),
                                subtitle: Text(
                                  'Current ${_getMetricDisplayName(_selectedMetric)}: $currentValue',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Subtract button (only show if current value > 0)
                                    if (currentValue > 0)
                                      IconButton(
                                        onPressed: () =>
                                            _decrementMetric(player.id),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        tooltip:
                                            'Remove ${_getMetricDisplayName(_selectedMetric)}',
                                        color: Colors.red,
                                      ),

                                    // Current count
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        currentValue.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),

                                    // Add button
                                    IconButton(
                                      onPressed: () =>
                                          _incrementMetric(player.id),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      tooltip:
                                          'Add ${_getMetricDisplayName(_selectedMetric)}',
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBulkInputDialog(context),
        icon: const Icon(Icons.speed),
        label: const Text('Quick Entry'),
      ),
    );
  }

  Future<void> _incrementMetric(int playerId) async {
    final db = ref.read(dbProvider);
    await db.incrementMetric(
      gameId: widget.gameId,
      playerId: playerId,
      metric: _selectedMetric,
    );

    // Show brief feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_getMetricDisplayName(_selectedMetric)}'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  Future<void> _decrementMetric(int playerId) async {
    final db = ref.read(dbProvider);

    // Get current metric value and decrement by creating a negative entry
    // This maintains the audit trail while effectively reducing the count
    final metrics = await db.watchMetricsForGame(widget.gameId).first;
    final playerMetrics = metrics
        .where((m) => m.playerId == playerId && m.metric == _selectedMetric)
        .toList();

    int currentTotal = 0;
    for (final metric in playerMetrics) {
      currentTotal += metric.value;
    }

    // Only decrement if there's something to decrement
    if (currentTotal > 0) {
      // Insert a negative metric entry to effectively subtract
      await db
          .into(db.playerMetrics)
          .insert(
            PlayerMetricsCompanion.insert(
              gameId: widget.gameId,
              playerId: playerId,
              metric: _selectedMetric,
              value: const drift.Value(-1),
            ),
          );

      // Show brief feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${_getMetricDisplayName(_selectedMetric)}'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  Future<void> _showBulkInputDialog(BuildContext context) async {
    final db = ref.read(dbProvider);
    final game = await db.getGame(widget.gameId);
    if (game == null) return;

    final players = await db.getPlayersByTeam(game.teamId);
    final Map<int, int> playerCounts = {};

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Quick ${_getMetricDisplayName(_selectedMetric)} Entry'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tap players who scored ${_getMetricDisplayName(_selectedMetric).toLowerCase()}s:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: players.map((player) {
                        final count = playerCounts[player.id] ?? 0;
                        return FilterChip(
                          selected: count > 0,
                          label: Text(
                            count > 0
                                ? '${player.firstName} ${player.lastName} ($count)'
                                : '${player.firstName} ${player.lastName}',
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                playerCounts[player.id] =
                                    (playerCounts[player.id] ?? 0) + 1;
                              } else {
                                playerCounts[player.id] = 0;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Apply all the counts
                for (final entry in playerCounts.entries) {
                  if (entry.value > 0) {
                    for (int i = 0; i < entry.value; i++) {
                      await db.incrementMetric(
                        gameId: widget.gameId,
                        playerId: entry.key,
                        metric: _selectedMetric,
                      );
                    }
                  }
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  final totalAdded = playerCounts.values.fold(
                    0,
                    (sum, count) => sum + count,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added $totalAdded ${_getMetricDisplayName(_selectedMetric).toLowerCase()}s',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMetricDisplayName(String metric) {
    switch (metric) {
      case 'GOAL':
        return 'Goal';
      case 'ASSIST':
        return 'Assist';
      case 'SAVE':
        return 'Save';
      default:
        return metric;
    }
  }

  IconData _getMetricIcon(String metric) {
    switch (metric) {
      case 'GOAL':
        return Icons.sports_soccer;
      case 'ASSIST':
        return Icons.sports;
      case 'SAVE':
        return Icons.sports_handball;
      default:
        return Icons.star;
    }
  }
}
