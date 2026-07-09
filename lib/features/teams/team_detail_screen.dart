import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/sideline.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/sideline_header.dart';
import '../../widgets/sideline_widgets.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/standardized_app_bar_actions.dart';

/// Game-first team landing screen (`/team/:id`). Surfaces the most recent game
/// result and the next scheduled game with a one-tap "Create new game" action.
/// Team management (players, formations, settings) lives under Settings.
class TeamDetailScreen extends ConsumerWidget {
  final int id;
  const TeamDetailScreen({super.key, required this.id});

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _createGame(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final team = await db.getTeam(id);
    if (team == null) return;
    final gameId = await db.addGame(
      GamesCompanion.insert(
        teamId: id,
        seasonId: team.seasonId,
        startTime: const drift.Value.absent(),
        opponent: const drift.Value.absent(),
      ),
    );
    if (!context.mounted) return;
    context.push('/game/$gameId/edit');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TEMP DIAGNOSTIC (issue #39): remove before merge.
    debugPrint('[DIAG39] TeamDetailScreen.build id=$id at ${DateTime.now()}');
    final loc = AppLocalizations.of(context);
    final db = ref.watch(dbProvider);

    return TeamScaffold(
      teamId: id,
      header: SidelineScreenHeader(
        teamId: id,
        subtitle: loc.games,
        actions: StandardizedAppBarActions.createActionsWidgets([
          CommonNavigationActions.home(context),
          NavigationAction(
            label: loc.games,
            icon: Icons.sports_soccer,
            onPressed: () => context.push('/team/$id/games'),
          ),
          NavigationAction(
            label: loc.settings,
            icon: Icons.settings,
            onPressed: () => context.push('/team/$id/edit'),
          ),
          NavigationAction(
            label: loc.metrics,
            icon: Icons.analytics,
            onPressed: () => context.push('/team/$id/metrics'),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.mostRecentGame,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            StreamBuilder<Game?>(
              stream: db.watchMostRecentCompletedGame(id),
              builder: (context, snap) {
                // TEMP DIAGNOSTIC (issue #39): remove before merge.
                debugPrint(
                  '[DIAG39] mostRecentGame builder state=${snap.connectionState} '
                  'hasData=${snap.hasData} at ${DateTime.now()}',
                );
                return _recentGameCard(context, snap.data, loc);
              },
            ),
            const SizedBox(height: 24),
            Text(
              loc.nextGame,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            StreamBuilder<Game?>(
              stream: db.watchNextUpcomingGame(id),
              builder: (context, snap) {
                // TEMP DIAGNOSTIC (issue #39): remove before merge.
                debugPrint(
                  '[DIAG39] nextUpcomingGame builder state=${snap.connectionState} '
                  'hasData=${snap.hasData} at ${DateTime.now()}',
                );
                return _nextGameCard(context, snap.data, loc);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _createGame(context, ref),
                icon: const Icon(Icons.add),
                label: Text(loc.createNewGame),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/team/$id/edit'),
                    icon: const Icon(Icons.settings),
                    label: Text(loc.settings),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/team/$id/metrics'),
                    icon: const Icon(Icons.analytics),
                    label: Text(loc.viewMetrics),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentGameCard(
    BuildContext context,
    Game? game,
    AppLocalizations loc,
  ) {
    if (game == null) {
      return _emptyGameCard(context, Icons.history, loc.noRecentGamesYet);
    }
    final team = teamColorsOf(context);
    final opponent = game.opponent?.isNotEmpty == true
        ? game.opponent!
        : 'Opponent';
    return _gameCard(
      context,
      accent: team.team,
      onTap: () => context.push('/game/${game.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs $opponent',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (game.startTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    loc.playedOn(_formatDate(game.startTime!)),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${game.teamScore}–${game.opponentScore}',
            style: sidelineMono(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: team.strong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextGameCard(
    BuildContext context,
    Game? game,
    AppLocalizations loc,
  ) {
    if (game == null || game.startTime == null) {
      return _emptyGameCard(context, Icons.event, loc.noUpcomingGames);
    }
    final team = teamColorsOf(context);
    final opponent = game.opponent?.isNotEmpty == true
        ? game.opponent!
        : 'Opponent';
    return _gameCard(
      context,
      accent: team.team,
      onTap: () => context.push('/game/${game.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'vs $opponent',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(game.startTime!)} • ${_formatTime(game.startTime!)}',
                style: sidelineMono(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyGameCard(BuildContext context, IconData icon, String label) {
    return _gameCard(
      context,
      accent: Theme.of(context).colorScheme.outlineVariant,
      onTap: null,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameCard(
    BuildContext context, {
    required Color accent,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(SidelineRadius.card),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
