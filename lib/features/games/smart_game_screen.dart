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
    debugPrint('SmartGameScreen.build: START for gameId=$gameId');
    final db = ref.watch(dbProvider);
    debugPrint('SmartGameScreen.build: dbProvider obtained');

    return FutureBuilder<Game?>(
      future: db.getGame(gameId),
      builder: (context, gameSnap) {
        debugPrint('SmartGameScreen.build: FutureBuilder callback - connectionState=${gameSnap.connectionState}, hasData=${gameSnap.hasData}');
        
        if (!gameSnap.hasData) {
          debugPrint('SmartGameScreen.build: No game data yet, showing loading...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final game = gameSnap.data!;
        debugPrint('SmartGameScreen.build: Game loaded, fetching team mode for teamId=${game.teamId}');
        return FutureBuilder<String>(
          future: db.getTeamMode(game.teamId),
          builder: (context, modeSnap) {
            debugPrint('SmartGameScreen.build: TeamMode FutureBuilder - connectionState=${modeSnap.connectionState}, hasData=${modeSnap.hasData}, data=${modeSnap.data}');
            
            // Check if still loading
            if (modeSnap.connectionState == ConnectionState.waiting) {
              debugPrint('SmartGameScreen.build: Still waiting for team mode, showing loading...');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Default to 'shift' mode if null or empty
            final teamMode = modeSnap.data ?? 'shift';
            debugPrint('SmartGameScreen.build: Team mode is "$teamMode", creating inner screen...');
            final inner = teamMode == 'traditional'
                ? TraditionalGameScreen(gameId: gameId)
                : GameScreen(gameId: gameId);
            debugPrint('SmartGameScreen.build: Wrapping in TeamThemeScope');
            return TeamThemeScope(teamId: game.teamId, child: inner);
          },
        );
      },
    );
  }
}
