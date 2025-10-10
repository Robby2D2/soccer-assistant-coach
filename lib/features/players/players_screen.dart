import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../utils/csv.dart';
import '../../utils/files.dart';
import 'package:go_router/go_router.dart';

class PlayersScreen extends ConsumerWidget {
  final int teamId;
  const PlayersScreen({super.key, required this.teamId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Team $teamId Players'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              final players = await db.getPlayersByTeam(teamId);
              final rows = players
                  .map(
                    (p) => {
                      'firstName': p.firstName,
                      'lastName': p.lastName,
                      'isPresent': p.isPresent ? 'true' : 'false',
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
            },
          ),
          IconButton(
            tooltip: 'Import CSV',
            icon: const Icon(Icons.file_upload),
            onPressed: () => context.push('/team/$teamId/players/import'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          db
              .into(db.players)
              .insert(
                PlayersCompanion.insert(
                  teamId: teamId,
                  firstName: 'New',
                  lastName: 'Player',
                  isPresent: const drift.Value(true),
                ),
              );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: db.watchPlayersByTeam(teamId),
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
            return const Center(
              child: Text('No players yet. Tap + to add one.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rows.length,
            itemBuilder: (_, i) => Card(
              child: ListTile(
                title: Text('${rows[i].firstName} ${rows[i].lastName}'),
                subtitle: Text(rows[i].isPresent ? 'Active' : 'Inactive'),
                leading: Switch(
                  value: rows[i].isPresent,
                  onChanged: (v) {
                    db
                        .update(db.players)
                        .replace(rows[i].copyWith(isPresent: v));
                  },
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          context.push('/player/${rows[i].id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final ok = await _confirm(
                          context,
                          'Delete ${rows[i].firstName} ${rows[i].lastName}?',
                        );
                        if (ok) await db.deletePlayer(rows[i].id);
                      },
                    ),
                  ],
                ),
              ),
            ),
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
