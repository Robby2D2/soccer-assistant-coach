import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/game_result_card.dart';
import '../../widgets/team_accent_widgets.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/sideline_header.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class GamesScreen extends ConsumerStatefulWidget {
  final int teamId;
  const GamesScreen({super.key, required this.teamId});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _showArchived = false;

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
              _showArchived ? loc.noArchivedGames : loc.noGamesYet,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _showArchived
                  ? loc.noArchivedGamesDescription
                  : loc.noGamesYetDescriptionOnboarding,
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
              label: Text(loc.createGame),
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

    final loc = AppLocalizations.of(context);
    return TeamScaffold(
      teamId: widget.teamId,
      header: SidelineScreenHeader(
        teamId: widget.teamId,
        subtitle: loc.games,
        actions: StandardizedAppBarActions.createActionsWidgets(
          [CommonNavigationActions.home(context)],
          additionalMenuItems: [
            NavigationAction(
              label: _showArchived ? loc.hideArchived : loc.showArchived,
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
                    return GameResultCard(
                      game: game,
                      onTap: () => context.push('/game/${game.id}'),
                      trailing: PopupMenuButton<String>(
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
