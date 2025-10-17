import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/game_scaffold.dart';
import '../../core/team_theme_manager.dart';

class FormationSelectionScreen extends ConsumerWidget {
  final int gameId;
  const FormationSelectionScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return GameScaffold(
      gameId: gameId,
      appBar: TeamAppBar(title: GameCompactTitle(gameId: gameId)),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, gSnap) {
          final game = gSnap.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: _FormationContent(game: game, db: db, gameId: game.id),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormationContent extends StatelessWidget {
  final Game game;
  final AppDb db;
  final int gameId;

  const _FormationContent({
    required this.game,
    required this.db,
    required this.gameId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Formation>>(
      stream: db.watchTeamFormations(game.teamId),
      builder: (context, fSnap) {
        if (fSnap.connectionState == ConnectionState.waiting &&
            !fSnap.hasData) {
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
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final f = formations[index];
            return ListTile(
              title: Text(f.name),
              subtitle: Text('${f.playerCount} players'),
              trailing: FilledButton(
                onPressed: () async {
                  final positions = await db.getFormationPositions(f.id);

                  // Check if game is already in progress (has existing shifts)
                  final existingShifts = await db.watchGameShifts(gameId).first;
                  final gameInProgress =
                      existingShifts.isNotEmpty && game.currentShiftId != null;

                  if (gameInProgress) {
                    // Game in progress: Find and update the existing next shift
                    final currentShift = existingShifts
                        .where((s) => s.id == game.currentShiftId)
                        .firstOrNull;

                    // First, create or update the formation template shift
                    // This ensures future shifts will use the new formation
                    final formationTemplateShifts = existingShifts.where(
                      (s) => s.startSeconds > 9000,
                    );
                    if (formationTemplateShifts.isNotEmpty) {
                      // Replace existing formation template
                      final templateShift = formationTemplateShifts.first;
                      await db.createAutoShift(
                        gameId: gameId,
                        startSeconds: templateShift.startSeconds,
                        positions: positions
                            .map((p) => p.positionName)
                            .toList(),
                        activate: false,
                        forceReassign: true,
                      );
                    } else {
                      // Create new formation template shift
                      await db.createAutoShift(
                        gameId: gameId,
                        startSeconds: 10000, // Far future template
                        positions: positions
                            .map((p) => p.positionName)
                            .toList(),
                        activate: false,
                      );
                    }

                    if (currentShift != null) {
                      // Look for existing shifts that come after the current shift
                      final chronological = [...existingShifts]
                        ..sort(
                          (a, b) => a.startSeconds.compareTo(b.startSeconds),
                        );
                      final futureShifts = chronological.where(
                        (s) =>
                            s.startSeconds > currentShift.startSeconds &&
                            s.startSeconds <=
                                9000, // Only real shifts, not templates
                      );

                      if (futureShifts.isNotEmpty) {
                        // Replace the existing next shift with new formation
                        final existingShift = futureShifts.first;
                        await db.createAutoShift(
                          gameId: gameId,
                          startSeconds: existingShift.startSeconds,
                          positions: positions
                              .map((p) => p.positionName)
                              .toList(),
                          activate: false,
                          forceReassign:
                              true, // This will replace the existing shift
                        );
                      } else {
                        // No future shift exists, create one
                        final nextStartTime = currentShift.startSeconds + 300;
                        await db.createAutoShift(
                          gameId: gameId,
                          startSeconds: nextStartTime,
                          positions: positions
                              .map((p) => p.positionName)
                              .toList(),
                          activate: false,
                        );
                      }
                    } else {
                      // Fallback: create new shift
                      await db.createAutoShift(
                        gameId: gameId,
                        startSeconds: 300,
                        positions: positions
                            .map((p) => p.positionName)
                            .toList(),
                        activate: false,
                      );
                    }
                  } else {
                    // Initial setup: create as current shift using fair assignment
                    await db.createAutoShift(
                      gameId: gameId,
                      startSeconds: 0,
                      positions: positions.map((p) => p.positionName).toList(),
                      activate: true,
                    );
                  }

                  // Update the game's formation ID to remember the selection
                  await db.updateGame(id: gameId, formationId: f.id);

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
  }
}

// Compact header applied via GameCompactTitle in AppBar.
