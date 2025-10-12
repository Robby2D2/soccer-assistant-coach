import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class GamesScreen extends ConsumerStatefulWidget {
  final int teamId;
  const GamesScreen({super.key, required this.teamId});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _showArchived = false;

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day • $hour:$minute';
  }

  Color _getResultColor(
    BuildContext context,
    int teamScore,
    int opponentScore,
  ) {
    if (teamScore > opponentScore) {
      return Colors.green; // Win
    } else if (teamScore < opponentScore) {
      return Colors.red; // Loss
    } else {
      return Colors.orange; // Draw
    }
  }

  String _getResultText(int teamScore, int opponentScore) {
    if (teamScore > opponentScore) {
      return 'Win';
    } else if (teamScore < opponentScore) {
      return 'Loss';
    } else {
      return 'Draw';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.sports_soccer,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _showArchived ? 'No Archived Games' : 'No Games Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _showArchived
                  ? 'You don\'t have any archived games.'
                  : 'Schedule your first game to start tracking match performance and player statistics.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final db = ref.read(dbProvider);
                final gameId = await db.addGame(
                  GamesCompanion.insert(
                    teamId: widget.teamId,
                    startTime: const drift.Value.absent(),
                    opponent: const drift.Value.absent(),
                  ),
                );
                if (!context.mounted) return;
                context.push('/game/$gameId/edit');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Game'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final stream = _showArchived
        ? db.watchTeamGames(widget.teamId, includeArchived: true)
        : db.watchTeamGames(widget.teamId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Team?>(
          future: db.getTeam(widget.teamId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Text('${snapshot.data!.name} Games');
            }
            return Text('Team ${widget.teamId} Games');
          },
        ),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final gameId = await db.addGame(
            GamesCompanion.insert(
              teamId: widget.teamId,
              startTime: const drift.Value.absent(),
              opponent: const drift.Value.absent(),
            ),
          );
          if (!context.mounted) return;
          context.push('/game/$gameId/edit');
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Game>>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final games = snap.data ?? const <Game>[];
          final visible = _showArchived
              ? games
              : games.where((g) => !g.isArchived).toList();
          if (visible.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            itemBuilder: (_, i) {
              final game = visible[i];
              final archived = game.isArchived;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: archived ? 0 : 2,
                  color: archived
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/game/${game.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Game icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: archived
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.outline.withOpacity(0.12)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                            ),
                            child: Icon(
                              Icons.sports_soccer,
                              color: archived
                                  ? Theme.of(context).colorScheme.outline
                                  : Theme.of(context).colorScheme.tertiary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Game info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        game.opponent?.isNotEmpty == true
                                            ? 'vs ${game.opponent!}'
                                            : 'vs Opponent',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: archived
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                  : null,
                                            ),
                                      ),
                                    ),
                                    // Score display for completed games
                                    if (game.gameStatus == 'completed') ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: _getResultColor(
                                            context,
                                            game.teamScore,
                                            game.opponentScore,
                                          ),
                                        ),
                                        child: Text(
                                          '${game.teamScore}-${game.opponentScore}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (game.startTime != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                          ),
                                          child: Text(
                                            _formatDate(game.startTime),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      // Game status indicator
                                      if (game.gameStatus == 'completed') ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getResultText(
                                                  game.teamScore,
                                                  game.opponentScore,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else if (game.isGameActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .errorContainer
                                                .withOpacity(0.5),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 8,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'LIVE',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (archived) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.errorContainer,
                                          ),
                                          child: Text(
                                            'Archived',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onErrorContainer,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              switch (value) {
                                case 'edit':
                                  context.push('/game/${game.id}/edit');
                                  break;
                                case 'archive':
                                  await db.setGameArchived(
                                    game.id,
                                    archived: !archived,
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Edit'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: ListTile(
                                  leading: Icon(
                                    archived
                                        ? Icons.unarchive
                                        : Icons.archive_outlined,
                                  ),
                                  title: Text(archived ? 'Restore' : 'Archive'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
