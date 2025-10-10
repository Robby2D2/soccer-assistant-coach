import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final stream = _showArchived
        ? db.watchTeamGames(widget.teamId, includeArchived: true)
        : db.watchTeamGames(widget.teamId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Team?>(
          future: db.getTeam(widget.teamId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Text('${snapshot.data!.name} Games');
            }
            return Text('Team ${widget.teamId} Games');
          },
        ),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final gameId = await db.addGame(
            GamesCompanion.insert(
              teamId: widget.teamId,
              startTime: const drift.Value.absent(),
              opponent: const drift.Value.absent(),
            ),
          );
          if (!context.mounted) return;
          context.push('/game/$gameId/edit');
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Game>>(
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
          if (visible.isEmpty) {
            return const Center(child: Text('No games. Tap + to add one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: visible.length,
            itemBuilder: (_, i) {
              final game = visible[i];
              final archived = game.isArchived;
              return Card(
                color: archived
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
                child: ListTile(
                  title: Text(
                    game.opponent?.isNotEmpty == true
                        ? game.opponent!
                        : 'Opponent',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'ID: ${game.id} • ${_formatDate(game.startTime)}${archived ? ' • Archived' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: Icon(archived ? Icons.unarchive : Icons.archive),
                        tooltip: archived ? 'Restore game' : 'Archive game',
                        onPressed: () async {
                          await db.setGameArchived(
                            game.id,
                            archived: !archived,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => context.push('/game/${game.id}/edit'),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/game/${game.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
