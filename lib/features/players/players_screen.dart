import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

import '../../utils/csv.dart';
import '../../utils/files.dart';
import '../../widgets/player_avatar.dart';
import '../../core/team_theme_manager.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class PlayersScreen extends ConsumerWidget {
  final int teamId;
  const PlayersScreen({super.key, required this.teamId});

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
                Icons.people,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noPlayersYet,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              loc.addPlayersDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final db = ProviderScope.containerOf(
                      context,
                    ).read(dbProvider);

                    // Get team's season
                    final team = await db.getTeam(teamId);
                    if (team == null) return;

                    await db
                        .into(db.players)
                        .insert(
                          PlayersCompanion.insert(
                            teamId: teamId,
                            seasonId: team.seasonId,
                            firstName: loc.newPlayer,
                            lastName: loc.player,
                            isPresent: const drift.Value(true),
                          ),
                        );
                  },
                  icon: const Icon(Icons.person_add),
                  label: Text(loc.addPlayer),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      GoRouter.of(context).push('/team/$teamId/players/import'),
                  icon: const Icon(Icons.file_upload),
                  label: Text(loc.importCsv),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final db = ref.watch(dbProvider);
    return TeamScaffold(
      teamId: teamId,
      appBar: TeamAppBar(
        teamId: teamId,
        titleText: loc.players,
        actions: StandardizedAppBarActions.createActionsWidgets(
          [
            CommonNavigationActions.export(context, () async {
              final players = await db.getPlayersByTeam(teamId);
              final rows = players
                  .map(
                    (p) => {
                      'firstName': p.firstName,
                      'lastName': p.lastName,
                      'jerseyNumber': p.jerseyNumber?.toString() ?? '',
                    },
                  )
                  .toList();
              final csv = playersToCsv(rows);
              final path = await saveTextFile('team_${teamId}_roster.csv', csv);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Saved CSV to $path')));
              }
            }),
          ],
          additionalMenuItems: [
            NavigationAction(
              label: loc.importCsv,
              icon: Icons.file_upload,
              onPressed: () => context.push('/team/$teamId/players/import'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Get team's season
          final team = await db.getTeam(teamId);
          if (team == null) return;

          await db
              .into(db.players)
              .insert(
                PlayersCompanion.insert(
                  teamId: teamId,
                  seasonId: team.seasonId,
                  firstName: 'New',
                  lastName: 'Player',
                  isPresent: const drift.Value(true),
                ),
              );
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<Team?>(
        future: db.getTeam(teamId),
        builder: (context, teamSnapshot) {
          final team = teamSnapshot.data;
          if (team == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Player>>(
            stream: db.watchPlayersByTeam(teamId, seasonId: team.seasonId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final rows = snap.data as List<Player>;
              if (rows.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final player = rows[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Player avatar with profile picture, jersey number, or initials
                            PlayerAvatar(
                              firstName: player.firstName,
                              lastName: player.lastName,
                              jerseyNumber: player.jerseyNumber,
                              profileImagePath: player.profileImagePath,
                              radius: 24,
                              backgroundColor: player.isPresent
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              textColor: player.isPresent
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 16),

                            // Player info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${player.firstName} ${player.lastName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: player.isPresent
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer,
                                        ),
                                        child: Text(
                                          player.isPresent
                                              ? 'Active'
                                              : 'Inactive',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: player.isPresent
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onErrorContainer,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      if (player.jerseyNumber != null) ...[
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
                                            ).colorScheme.secondaryContainer,
                                          ),
                                          child: Text(
                                            '#${player.jerseyNumber}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSecondaryContainer,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Toggle switch
                            Switch(
                              value: player.isPresent,
                              onChanged: (v) {
                                db
                                    .update(db.players)
                                    .replace(player.copyWith(isPresent: v));
                              },
                            ),
                            const SizedBox(width: 8),

                            // Action buttons
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                switch (value) {
                                  case 'edit':
                                    context.push('/player/${player.id}/edit');
                                    break;
                                  case 'delete':
                                    final ok = await _confirm(
                                      context,
                                      'Delete ${player.firstName} ${player.lastName}?',
                                    );
                                    if (ok) await db.deletePlayer(player.id);
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
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Delete'),
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
          );
        },
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String msg) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}
