import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/team_theme_manager.dart';
import 'game_screen.dart';
import 'traditional_game_screen.dart';

class SmartGameScreen extends ConsumerWidget {
  final int gameId;

  const SmartGameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Game?>(
      future: db.getGame(gameId),
      builder: (context, gameSnap) {
        if (!gameSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final game = gameSnap.data!;
        return FutureBuilder<String>(
          future: db.getTeamMode(game.teamId),
          builder: (context, modeSnap) {
            if (!modeSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final teamMode = modeSnap.data!;
            final inner = teamMode == 'traditional'
                ? TraditionalGameScreen(gameId: gameId)
                : GameScreen(gameId: gameId);
            return TeamThemeScope(teamId: game.teamId, child: inner);
          },
        );
      },
    );
  }
}
