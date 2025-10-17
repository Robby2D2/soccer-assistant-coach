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
    return FutureBuilder<Game?>(
      future: db.getGame(gameId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
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
