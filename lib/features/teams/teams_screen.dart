import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/season_provider.dart';
import '../../l10n/app_localizations.dart';

import '../../widgets/team_panels.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
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
              _showArchived ? loc.noArchivedTeams : loc.noTeamsYet,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _showArchived
                  ? loc.noArchivedTeamsDescription
                  : loc.noTeamsYetDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () =>
                  _showCreateTeamDialog(context, ref.read(dbProvider)),
              icon: const Icon(Icons.add),
              label: Text(loc.createTeam),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, AppDb db) async {
    final loc = AppLocalizations.of(context);
    // Get current season first
    final currentSeason = await db.getActiveSeason();
    if (currentSeason == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.noActiveSeasonFound),
            action: SnackBarAction(
              label: loc.manageSeasons,
              onPressed: () => context.push('/seasons'),
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.createTeam),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.creatingTeamFor(currentSeason.name),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: loc.teamName),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await db.addTeamToSeason(seasonId: currentSeason.id, name: name);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
            child: Text(loc.create),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final currentSeasonAsync = ref.watch(currentSeasonProvider);

    final loc = AppLocalizations.of(context);
    return TeamScaffold(
      appBar: TeamAppBar(
        titleText: loc.teams,
        actions: StandardizedAppBarActions.createActionsWidgets(
          [
            // Show Home as an icon and include it in the kebab menu for
            // consistency with other screens.
            CommonNavigationActions.home(context),
          ],
          additionalMenuItems: [
            NavigationAction(
              label: _showArchived ? loc.hideArchived : loc.showArchived,
              icon: _showArchived ? Icons.inventory_2 : Icons.archive,
              onPressed: () => setState(() => _showArchived = !_showArchived),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context, db),
        child: const Icon(Icons.add),
      ),
      body: currentSeasonAsync.when(
        data: (currentSeason) {
          if (currentSeason == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 64),
                    const SizedBox(height: 16),
                    Text(loc.noActiveSeason),
                    const SizedBox(height: 8),
                    Text(loc.createSeasonToManageTeams),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/seasons'),
                      child: Text(loc.manageSeasons),
                    ),
                  ],
                ),
              ),
            );
          }

          // Use StreamBuilder like the home screen does
          return StreamBuilder<List<Team>>(
            stream: db.watchTeams(seasonId: currentSeason.id),
            builder: (context, teamsSnapshot) {
              if (teamsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (teamsSnapshot.hasError) {
                final loc = AppLocalizations.of(context);
                return Center(
                  child: Text(
                    loc.errorLoadingTeams(teamsSnapshot.error.toString()),
                  ),
                );
              }

              final teams = teamsSnapshot.data ?? [];
              final visible = _showArchived
                  ? teams
                  : teams.where((t) => !t.isArchived).toList();

              if (visible.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visible.length,
                itemBuilder: (_, i) {
                  final team = visible[i];
                  final archived = team.isArchived;
                  return TeamListPanel(
                    teamId: team.id,
                    onTap: () => context.push('/team/${team.id}'),
                    trailing: Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            archived ? Icons.unarchive : Icons.archive,
                          ),
                          tooltip: archived ? loc.restoreTeam : loc.archiveTeam,
                          onPressed: () async {
                            await db.setTeamArchived(
                              team.id,
                              archived: !archived,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: loc.editTeam,
                          onPressed: () =>
                              context.push('/team/${team.id}/edit'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final loc = AppLocalizations.of(context);
          return Center(child: Text(loc.errorLoadingSeason(error.toString())));
        },
      ),
    );
  }
}
