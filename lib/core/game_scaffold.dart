import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'team_theme_manager.dart';

/// Scaffold that automatically derives teamId from gameId and applies TeamTheme.
class GameScaffold extends ConsumerWidget {
  final int gameId;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const GameScaffold({
    super.key,
    required this.gameId,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    debugPrint('GameScaffold: Building for gameId=$gameId');
    return FutureBuilder<Game?>(
      future: db.getGame(gameId),
      builder: (context, snap) {
        debugPrint('GameScaffold: FutureBuilder state=${snap.connectionState}, hasData=${snap.hasData}, hasError=${snap.hasError}');
        
        // Show error if query failed
        if (snap.hasError) {
          debugPrint('GameScaffold: Error - ${snap.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading game: ${snap.error}'),
                ],
              ),
            ),
          );
        }
        
        // Show loading while waiting
        if (snap.connectionState == ConnectionState.waiting) {
          debugPrint('GameScaffold: Waiting for data...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Show error if no game found
        if (!snap.hasData || snap.data == null) {
          return const Scaffold(
            body: Center(
              child: Text('Game not found'),
            ),
          );
        }
        
        final game = snap.data!;
        return TeamScaffold(
          teamId: game.teamId,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          backgroundColor: backgroundColor,
        );
      },
    );
  }
}
