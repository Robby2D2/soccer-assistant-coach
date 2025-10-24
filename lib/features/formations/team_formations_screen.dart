import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/team_header.dart';
import '../../widgets/team_accent_widgets.dart';

class TeamFormationsScreen extends ConsumerWidget {
  final int teamId;
  const TeamFormationsScreen({super.key, required this.teamId});

  void _showFormationDetails(
    BuildContext context,
    Formation f,
    AppDb db,
  ) async {
    final loc = AppLocalizations.of(context);
    final positions = await db.getFormationPositions(f.id);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(f.name),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: positions
                .map((p) => Chip(label: Text(p.positionName)))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.close),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              GoRouter.of(
                context,
              ).push('/team/$teamId/formations/${f.id}/edit');
            },
            child: Text(loc.edit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TeamHeader(
          teamId: teamId,
          suffix: ' ${loc.formations}',
          logoSize: 28,
        ),
      ),
      floatingActionButton: TeamFloatingActionButton(
        teamId: teamId,
        tooltip: loc.createFormationTooltip,
        onPressed: () => context.push('/team/$teamId/formations/new'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Formation>>(
        stream: db.watchTeamFormations(teamId),
        builder: (context, snapshot) {
          final formations = snapshot.data ?? const <Formation>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              formations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (formations.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: formations.length,
            itemBuilder: (context, index) {
              final f = formations[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _showFormationDetails(context, f, db);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Formation icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Formation info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiaryContainer,
                                  ),
                                  child: Text(
                                    loc.playersCount(f.playerCount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onTertiaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                  context.push(
                                    '/team/$teamId/formations/${f.id}/edit',
                                  );
                                  break;
                                case 'delete':
                                  final confirm =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(loc.deleteFormationTitle),
                                          content: Text(
                                            loc.deleteFormationMessage(f.name),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(loc.cancel),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(loc.delete),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (!confirm) return;
                                  await db.deleteFormation(f.id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: Text(loc.editFormation),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: const Icon(Icons.delete_outline),
                                  title: Text(loc.deleteFormation),
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
                Icons.grid_view_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noFormationsYet,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              loc.noFormationsYetDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () =>
                  GoRouter.of(context).push('/team/$teamId/formations/new'),
              icon: const Icon(Icons.add),
              label: Text(loc.createFormation),
            ),
          ],
        ),
      ),
    );
  }
}
