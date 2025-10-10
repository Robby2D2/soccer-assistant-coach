import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  bool _showArchived = false;

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
              RadioListTile<String>(
                title: const Text('Shift Mode'),
                subtitle: const Text('Timed shifts with automatic rotations'),
                value: 'shift',
                groupValue: teamMode,
                onChanged: (value) => setState(() => teamMode = value!),
                dense: true,
              ),
              RadioListTile<String>(
                title: const Text('Traditional Mode'),
                subtitle: const Text(
                  'Manual substitutions with playing time tracking',
                ),
                value: 'traditional',
                groupValue: teamMode,
                onChanged: (value) => setState(() => teamMode = value!),
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
            return const Center(child: Text('No teams yet. Tap + to add one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: visible.length,
            itemBuilder: (_, i) {
              final team = visible[i];
              final archived = team.isArchived;
              return Card(
                color: archived
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                child: ListTile(
                  title: Text(
                    team.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Team ID: ${team.id} • ${team.teamMode == 'traditional' ? 'Traditional' : 'Shift'} Mode${archived ? ' • Archived' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: Icon(archived ? Icons.unarchive : Icons.archive),
                        tooltip: archived ? 'Restore team' : 'Archive team',
                        onPressed: () async {
                          await db.setTeamArchived(
                            team.id,
                            archived: !archived,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => context.push('/team/${team.id}/edit'),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/team/${team.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
