import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../widgets/team_accent_widgets.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/team_header.dart';
import '../../widgets/standardized_app_bar_actions.dart';

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

  Widget _pill(
    BuildContext context,
    String label,
    Color background,
    Color foreground, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

                // Get team's season
                final team = await db.getTeam(widget.teamId);
                if (team == null) return;

                final gameId = await db.addGame(
                  GamesCompanion.insert(
                    teamId: widget.teamId,
                    seasonId: team.seasonId,
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

    return TeamScaffold(
      teamId: widget.teamId,
      appBar: TeamAppBar(
        teamId: widget.teamId,
        titleText: 'Games',
        actions: StandardizedAppBarActions.createActionsWidgets(
          [CommonNavigationActions.home(context)],
          additionalMenuItems: [
            NavigationAction(
              label: _showArchived ? 'Hide Archived' : 'Show Archived',
              icon: _showArchived ? Icons.inventory_2 : Icons.archive,
              onPressed: () => setState(() => _showArchived = !_showArchived),
            ),
          ],
        ),
      ),
      floatingActionButton: TeamFloatingActionButton(
        teamId: widget.teamId,
        onPressed: () async {
          // Get team's season
          final team = await db.getTeam(widget.teamId);
          if (team == null) return;

          final gameId = await db.addGame(
            GamesCompanion.insert(
              teamId: widget.teamId,
              seasonId: team.seasonId,
              startTime: const drift.Value.absent(),
              opponent: const drift.Value.absent(),
            ),
          );
          if (!context.mounted) return;
          context.push('/game/$gameId/edit');
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TeamBrandedHeader(
              teamId: widget.teamId,
              title: 'Games',
              subtitle: 'Game History & Management',
              padding: const EdgeInsets.all(20),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Game>>(
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
                if (visible.isEmpty) return _buildEmptyState(context);
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final game = visible[i];
                    final archived = game.isArchived;
                    return Card(
                      elevation: archived ? 0 : 2,
                      color: archived
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : null,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/game/${game.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: archived
                                      ? Theme.of(context).colorScheme.outline
                                            .withValues(alpha: 0.12)
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
                                        if (game.gameStatus == 'completed')
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (game.startTime != null)
                                          _pill(
                                            context,
                                            _formatDate(game.startTime),
                                            Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                        if (game.gameStatus == 'completed')
                                          _pill(
                                            context,
                                            _getResultText(
                                              game.teamScore,
                                              game.opponentScore,
                                            ),
                                            Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                            icon: Icons.check_circle_outline,
                                          )
                                        else if (game.isGameActive)
                                          _pill(
                                            context,
                                            'LIVE',
                                            Theme.of(context)
                                                .colorScheme
                                                .errorContainer
                                                .withValues(alpha: 0.6),
                                            Theme.of(context).colorScheme.error,
                                            icon: Icons.circle,
                                          ),
                                        if (archived)
                                          _pill(
                                            context,
                                            'Archived',
                                            Theme.of(
                                              context,
                                            ).colorScheme.errorContainer,
                                            Theme.of(
                                              context,
                                            ).colorScheme.onErrorContainer,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
                                      title: Text(
                                        archived ? 'Restore' : 'Archive',
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
