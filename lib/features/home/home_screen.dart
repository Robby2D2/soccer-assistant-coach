import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soccer Assistant Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Manage Teams',
            onPressed: () => context.push('/teams'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Games Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Games',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<GameWithTeam>>(
                  stream: db.watchActiveGames(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final activeGames = snapshot.data ?? [];

                    if (activeGames.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sports_soccer,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Active Games',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    'Start a game to see it here for quick access',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: activeGames.map((gameWithTeam) {
                        final game = gameWithTeam.game;
                        final team = gameWithTeam.team;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            elevation: 4,
                            child: InkWell(
                              onTap: () => context.push('/game/${game.id}'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: game.isGameActive
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.errorContainer
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        game.isGameActive
                                            ? Icons.timer
                                            : Icons.pause_circle_filled,
                                        color: game.isGameActive
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            team.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          if (game.opponent?.isNotEmpty == true)
                                            Text(
                                              'vs ${game.opponent}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: game.isGameActive
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .errorContainer
                                                            .withOpacity(0.5)
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer
                                                            .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  game.isGameActive
                                                      ? 'LIVE'
                                                      : 'PAUSED',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: game.isGameActive
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .error
                                                            : Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Half ${game.currentHalf}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Live updating time display for active games
                                    _LiveGameTimer(game: game, teamId: team.id),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Quick Actions Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Team>>(
                    stream: db.watchTeams(),
                    builder: (context, snapshot) {
                      final teams = snapshot.data ?? [];

                      return Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            // Manage Teams Card
                            _QuickActionCard(
                              icon: Icons.group,
                              title: 'Manage Teams',
                              subtitle:
                                  '${teams.length} team${teams.length != 1 ? 's' : ''}',
                              onTap: () => context.push('/teams'),
                            ),

                            // Recent Team Card (if teams exist)
                            if (teams.isNotEmpty)
                              _QuickActionCard(
                                icon: Icons.recent_actors,
                                title: teams.first.name,
                                subtitle: 'View team details',
                                onTap: () =>
                                    context.push('/team/${teams.first.id}'),
                              )
                            else
                              _QuickActionCard(
                                icon: Icons.add,
                                title: 'Create Team',
                                subtitle: 'Get started',
                                onTap: () => context.push('/teams'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveGameTimer extends ConsumerStatefulWidget {
  final Game game;
  final int teamId;

  const _LiveGameTimer({required this.game, required this.teamId});

  @override
  ConsumerState<_LiveGameTimer> createState() => _LiveGameTimerState();
}

class _LiveGameTimerState extends ConsumerState<_LiveGameTimer> {
  late Stream<int> _timerStream;

  String _formatTimeRemaining(int gameTimeSeconds, int halfDurationSeconds) {
    final remaining = halfDurationSeconds - gameTimeSeconds;
    final isOvertime = remaining <= 0;

    final displaySeconds = isOvertime ? -remaining : remaining;
    final minutes = displaySeconds ~/ 60;
    final seconds = displaySeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return isOvertime ? '+$timeString' : timeString;
  }

  @override
  void initState() {
    super.initState();
    // Create a stream that emits current game time every second for active games
    _timerStream = Stream.periodic(const Duration(seconds: 1), (_) {
      if (widget.game.isGameActive && widget.game.timerStartTime != null) {
        // Calculate current elapsed time for active games
        return widget.game.gameTimeSeconds +
            DateTime.now().difference(widget.game.timerStartTime!).inSeconds;
      } else {
        // For paused games, just return the stored game time
        return widget.game.gameTimeSeconds;
      }
    }).distinct(); // Only emit when the time actually changes
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<int>(
      future: db.getTeamHalfDurationSeconds(widget.teamId),
      builder: (context, snapshot) {
        final halfDuration = snapshot.data ?? 1200; // 20 min default

        return StreamBuilder<int>(
          stream: _timerStream,
          initialData: widget.game.gameTimeSeconds,
          builder: (context, timeSnapshot) {
            final currentGameTime =
                timeSnapshot.data ?? widget.game.gameTimeSeconds;

            return Column(
              children: [
                Text(
                  _formatTimeRemaining(currentGameTime, halfDuration),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: widget.game.isGameActive
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
