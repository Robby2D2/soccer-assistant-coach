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
        onPressed: () => db.addTeam(TeamsCompanion.insert(name: 'New Club')),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Team>>(
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
                color: archived ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
                child: ListTile(
                  title: Text(
                    team.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Team ID: ${team.id}${archived ? ' • Archived' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: Icon(archived ? Icons.unarchive : Icons.archive),
                        tooltip: archived ? 'Restore team' : 'Archive team',
                        onPressed: () async {
                          await db.setTeamArchived(team.id, archived: !archived);
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
