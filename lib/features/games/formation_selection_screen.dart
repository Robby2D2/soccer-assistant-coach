import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class FormationSelectionScreen extends ConsumerWidget {
  final int gameId;
  const FormationSelectionScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Formation')),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, gSnap) {
          final game = gSnap.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<Formation>>(
            stream: db.watchTeamFormations(game.teamId),
            builder: (context, fSnap) {
              if (fSnap.connectionState == ConnectionState.waiting && !fSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final formations = fSnap.data ?? const <Formation>[];
              if (formations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No formations found for this team.'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
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
                    trailing: FilledButton(
                      onPressed: () async {
                        final positions = await db.getFormationPositions(f.id);
                        final present = await db.presentPlayersForGame(gameId, game.teamId);
                        final count = positions.length;
                        final applyCount = present.length < count ? present.length : count;
                        final shiftId = await db.startShift(
                          gameId,
                          0,
                          notes: 'Formation: ${f.name}',
                        );
                        for (var i = 0; i < applyCount; i++) {
                          await db.setPlayerPosition(
                            shiftId: shiftId,
                            playerId: present[i].id,
                            position: positions[i].positionName,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Use'),
                    ),
                    onTap: () async {
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
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
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

