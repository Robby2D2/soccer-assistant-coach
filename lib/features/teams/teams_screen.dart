import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../widgets/team_logo_widget.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  bool _showArchived = false;

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
              _showArchived ? 'No Archived Teams' : 'No Teams Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _showArchived
                  ? 'You don\'t have any archived teams.'
                  : 'Create your first team to start managing players, formations, and games.',
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
              label: const Text('Create Team'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, AppDb db) {
    final nameController = TextEditingController(text: 'New Club');
    final shiftMinutesController = TextEditingController(text: '5');
    final halfMinutesController = TextEditingController(text: '20');
    String teamMode = 'shift';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Team Mode Selection
              Text('Team Mode', style: Theme.of(context).textTheme.titleSmall),
              ListTile(
                leading: Radio<String>(
                  value: 'shift',
                  groupValue: teamMode,
                  onChanged: (value) => setState(() => teamMode = value!),
                ),
                title: const Text('Shift Mode'),
                subtitle: const Text('Timed shifts with automatic rotations'),
                onTap: () => setState(() => teamMode = 'shift'),
                dense: true,
              ),
              ListTile(
                leading: Radio<String>(
                  value: 'traditional',
                  groupValue: teamMode,
                  onChanged: (value) => setState(() => teamMode = value!),
                ),
                title: const Text('Traditional Mode'),
                subtitle: const Text(
                  'Manual substitutions with playing time tracking',
                ),
                onTap: () => setState(() => teamMode = 'traditional'),
                dense: true,
              ),
              const SizedBox(height: 8),

              // Mode-specific settings
              if (teamMode == 'shift')
                TextField(
                  controller: shiftMinutesController,
                  decoration: const InputDecoration(
                    labelText: 'Default shift length (minutes)',
                  ),
                  keyboardType: TextInputType.number,
                )
              else
                TextField(
                  controller: halfMinutesController,
                  decoration: const InputDecoration(
                    labelText: 'Half duration (minutes)',
                  ),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final teamId = await db.addTeam(
                  TeamsCompanion.insert(name: name),
                );
                await db.setTeamMode(teamId, teamMode);

                if (teamMode == 'shift') {
                  final mins = int.tryParse(shiftMinutesController.text.trim());
                  if (mins != null && mins > 0) {
                    await db.setTeamShiftLengthSeconds(teamId, mins * 60);
                  }
                } else {
                  final mins = int.tryParse(halfMinutesController.text.trim());
                  if (mins != null && mins > 0) {
                    await db.setTeamHalfDurationSeconds(teamId, mins * 60);
                  }
                }

                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
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
        ? db.watchTeams(includeArchived: true)
        : db.watchTeams();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context, db),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Team>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final teams = snap.data ?? const <Team>[];
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
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: archived ? 0 : 2,
                  color: archived
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/team/${team.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          TeamLogoWidget(
                            logoPath: team.logoImagePath,
                            size: 56,
                            backgroundColor: archived
                                ? Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.12)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            iconColor: archived
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: archived
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant
                                            : null,
                                      ),
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
                                        borderRadius: BorderRadius.circular(12),
                                        color: team.teamMode == 'traditional'
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondaryContainer
                                            : Theme.of(
                                                context,
                                              ).colorScheme.tertiaryContainer,
                                      ),
                                      child: Text(
                                        team.teamMode == 'traditional'
                                            ? 'Traditional'
                                            : 'Shift Mode',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color:
                                                  team.teamMode == 'traditional'
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onSecondaryContainer
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
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
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
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
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  archived ? Icons.unarchive : Icons.archive,
                                ),
                                tooltip: archived
                                    ? 'Restore team'
                                    : 'Archive team',
                                onPressed: () async {
                                  await db.setTeamArchived(
                                    team.id,
                                    archived: !archived,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit team',
                                onPressed: () =>
                                    context.push('/team/${team.id}/edit'),
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
