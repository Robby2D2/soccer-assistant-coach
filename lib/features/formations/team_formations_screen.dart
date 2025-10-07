import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class TeamFormationsScreen extends ConsumerWidget {
  final int teamId;
  const TeamFormationsScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Formations')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create formation',
        onPressed: () => context.push('/team/$teamId/formations/new'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Formation>>(
        stream: db.watchTeamFormations(teamId),
        builder: (context, snapshot) {
          final formations = snapshot.data ?? const <Formation>[];
          if (snapshot.connectionState == ConnectionState.waiting && formations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (formations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No formations yet.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push('/team/$teamId/formations/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create formation'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: formations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final f = formations[index];
              return ListTile(
                title: Text(f.name),
                subtitle: Text('${f.playerCount} players'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit),
                      onPressed: () => context.push('/team/$teamId/formations/${f.id}/edit'),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete formation?'),
                                content: Text('Delete "${f.name}"?'),
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
                        if (!confirm) return;
                        await db.deleteFormation(f.id);
                      },
                    ),
                  ],
                ),
                onTap: () async {
                  // Simple preview dialog
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
                              .map(
                                (p) => Chip(label: Text(p.positionName)),
                              )
                              .toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/team/$teamId/formations/${f.id}/edit');
                          },
                          child: const Text('Edit'),
                        ),
                      ],
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
