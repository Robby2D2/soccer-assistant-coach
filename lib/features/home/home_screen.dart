import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../data/services/stopwatch_service.dart';
import '../../../widgets/team_logo_widget.dart';
import '../../widgets/team_color_picker.dart';
import '../../utils/team_theme.dart'; // For TeamColorContrast

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soccer Assistant Coach'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'debug') {
                context.push('/debug/database');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Expanded(child: Text('Database Diagnostics')),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
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
                            ).colorScheme.outline.withValues(alpha: 0.2),
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

                        return _ActiveGameGradientCard(
                          game: game,
                          team: team,
                          onTap: () => context.push('/game/${game.id}'),
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
                  Row(
                    children: [
                      Icon(
                        Icons.dashboard_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<Team>>(
                      future: db.getTeamsWithRecentGames(),
                      builder: (context, recentTeamsSnapshot) {
                        final recentTeams = recentTeamsSnapshot.data ?? [];

                        return StreamBuilder<List<Team>>(
                          stream: db.watchTeams(),
                          builder: (context, allTeamsSnapshot) {
                            final allTeams = allTeamsSnapshot.data ?? [];

                            final List<Widget> cards = [];

                            // Always show Manage Teams card first
                            cards.add(
                              _QuickActionCard(
                                icon: Icons.groups_outlined,
                                title: 'Manage Teams',
                                subtitle: '${allTeams.length} teams',
                                onTap: () => context.push('/teams'),
                              ),
                            );

                            // Add cards for teams with recent games
                            for (final team in recentTeams.take(3)) {
                              cards.add(
                                _RecentTeamCard(
                                  team: team,
                                  onTap: () => context.push('/team/${team.id}'),
                                ),
                              );
                            }

                            // If no recent teams, show first team as fallback
                            if (recentTeams.isEmpty && allTeams.isNotEmpty) {
                              cards.add(
                                _TeamBrandedCard(
                                  team: allTeams.first,
                                  onTap: () => context.push(
                                    '/team/${allTeams.first.id}',
                                  ),
                                ),
                              );
                            }

                            return GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.1,
                              children: cards,
                            );
                          },
                        );
                      },
                    ),
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
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveGameTimer extends ConsumerStatefulWidget {
  final Game game;
  final int teamId;
  final bool isShiftMode; // Derived from team.teamMode == 'shift'
  final Color?
  fallbackTextColor; // Provided by parent when overlaying on gradient

  const _LiveGameTimer({
    required this.game,
    required this.teamId,
    required this.isShiftMode,
    this.fallbackTextColor,
  });

  @override
  ConsumerState<_LiveGameTimer> createState() => _LiveGameTimerState();
}

class _LiveGameTimerState extends ConsumerState<_LiveGameTimer> {
  String _formatTimeRemaining(int gameTimeSeconds, int durationSeconds) {
    final remaining = durationSeconds - gameTimeSeconds;
    final isOvertime = remaining <= 0;

    final displaySeconds = isOvertime ? -remaining : remaining;
    final minutes = displaySeconds ~/ 60;
    final seconds = displaySeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return isOvertime ? '-$timeString' : timeString;
  }

  @override
  void initState() {
    super.initState();
    // No longer using local periodic stream; authoritative time fetched inside build via DB helper.
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);

    if (widget.isShiftMode) {
      // For shift-based games, get shift duration and watch current shift time
      return FutureBuilder<int>(
        future: db.getTeamShiftLengthSeconds(widget.teamId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '--:--',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            );
          }

          final shiftDuration = snapshot.data!;

          return Consumer(
            builder: (context, ref, child) {
              // Use the same stopwatch provider as the game screen for consistency
              final currentShiftTime = ref.watch(
                stopwatchProvider(widget.game.id),
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimeRemaining(currentShiftTime, shiftDuration),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: widget.game.isGameActive
                          ? Theme.of(context).colorScheme.error
                          : widget.fallbackTextColor,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      // For traditional games, use half duration as before
      return FutureBuilder<int>(
        future: db.getTeamHalfDurationSeconds(widget.teamId),
        builder: (context, snapshot) {
          final halfDuration = snapshot.data ?? 1200; // 20 min default
          // Recalculate current game time each second using DB helper to stay consistent with TraditionalGameScreen
          return StreamBuilder<int>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
            ).asyncMap((_) => db.calculateCurrentGameTime(widget.game.id)),
            initialData: widget.game.gameTimeSeconds,
            builder: (context, timeSnapshot) {
              final authoritativeTime =
                  timeSnapshot.data ?? widget.game.gameTimeSeconds;
              final remainingDisplay = _formatTimeRemaining(
                authoritativeTime,
                halfDuration,
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remainingDisplay,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: widget.game.isGameActive
                          ? Theme.of(context).colorScheme.error
                          : widget.fallbackTextColor,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
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
}

class _HalfOrShiftDisplay extends ConsumerWidget {
  final Game game;
  final bool isShiftMode;

  const _HalfOrShiftDisplay({required this.game, required this.isShiftMode});

  Future<int?> _getShiftNumber(AppDb db, int shiftId, int gameId) async {
    try {
      final shifts = await db.watchGameShifts(gameId).first;
      if (shifts.isEmpty) return null;
      final sorted = [...shifts]
        ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));

      for (int i = 0; i < sorted.length; i++) {
        if (sorted[i].id == shiftId) {
          return i + 1; // 1-based indexing
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    // Display depends on team mode, not presence of shifts (traditional games may still accumulate shifts for stats)
    if (isShiftMode) {
      // Show shift number for shift-based games
      return FutureBuilder<int?>(
        future: _getShiftNumber(db, game.currentShiftId!, game.id),
        builder: (context, snapshot) {
          final shiftNumber = snapshot.data;
          return Text(
            shiftNumber != null ? 'Shift #$shiftNumber' : 'Shift',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    } else {
      // Show half number for traditional games
      return Text(
        'Half ${game.currentHalf}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
  }
}

class _ActiveGameGradientCard extends StatelessWidget {
  final Game game;
  final Team team;
  final VoidCallback onTap;

  const _ActiveGameGradientCard({
    required this.game,
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use team colors if available
    final hasTeamColors = team.primaryColor1 != null;
    final teamPrimaryColor = hasTeamColors
        ? (ColorHelper.hexToColor(team.primaryColor1!) ??
              Theme.of(context).colorScheme.primary)
        : Theme.of(context).colorScheme.primary;

    final teamSecondaryColor = team.primaryColor2 != null
        ? (ColorHelper.hexToColor(team.primaryColor2!) ??
              teamPrimaryColor.withOpacity(0.7))
        : teamPrimaryColor.withOpacity(0.7);

    // Determine on-colors for gradient
    final onPrimary = TeamColorContrast.onColorFor(teamPrimaryColor);
    final onSecondary = TeamColorContrast.onColorFor(teamSecondaryColor);
    final onGradient =
        onPrimary.computeLuminance() > onSecondary.computeLuminance()
        ? onSecondary
        : onPrimary;
    final isShiftMode = team.teamMode == 'shift';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  teamPrimaryColor.withOpacity(0.9),
                  teamSecondaryColor.withOpacity(0.8),
                  teamPrimaryColor.withOpacity(0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Team logo with status indicator
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TeamLogoWidget(
                          logoPath: team.logoImagePath,
                          size: 32,
                          backgroundColor: Colors.transparent,
                          iconColor: teamPrimaryColor,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: game.isGameActive
                                ? Theme.of(context).colorScheme.error
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            game.isGameActive ? Icons.play_arrow : Icons.pause,
                            color: game.isGameActive
                                ? Colors.white
                                : teamPrimaryColor,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Game info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: onGradient,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.25),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                        ),
                        if (game.opponent?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'vs ${game.opponent}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: onGradient.withOpacity(0.85),
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: onGradient.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: onGradient.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                game.isGameActive ? 'LIVE' : 'PAUSED',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: game.isGameActive
                                          ? Theme.of(context).colorScheme.error
                                          : onGradient,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: onGradient.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: onGradient.withOpacity(0.25),
                                ),
                              ),
                              child: DefaultTextStyle(
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(color: onGradient),
                                child: _HalfOrShiftDisplay(
                                  game: game,
                                  isShiftMode: isShiftMode,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Live timer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: onGradient.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: onGradient.withOpacity(0.25)),
                    ),
                    child: _LiveGameTimer(
                      game: game,
                      teamId: team.id,
                      isShiftMode: isShiftMode,
                      fallbackTextColor: onGradient,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentTeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _RecentTeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Use team colors if available
    final hasTeamColors = team.primaryColor1 != null;
    final teamPrimaryColor = hasTeamColors
        ? (ColorHelper.hexToColor(team.primaryColor1!) ??
              Theme.of(context).colorScheme.primary)
        : Theme.of(context).colorScheme.primary;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                teamPrimaryColor.withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
                teamPrimaryColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: teamPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TeamLogoWidget(
                    logoPath: team.logoImagePath,
                    size: 24,
                    backgroundColor: Colors.transparent,
                    iconColor: teamPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: teamPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: teamPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Recent Games',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: teamPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamBrandedCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamBrandedCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Use team colors if available
    final hasTeamColors = team.primaryColor1 != null;
    final teamPrimaryColor = hasTeamColors
        ? (ColorHelper.hexToColor(team.primaryColor1!) ??
              Theme.of(context).colorScheme.primary)
        : Theme.of(context).colorScheme.primary;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                teamPrimaryColor.withOpacity(0.2),
                Theme.of(context).colorScheme.surface,
                teamPrimaryColor.withOpacity(0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: teamPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TeamLogoWidget(
                    logoPath: team.logoImagePath,
                    size: 28,
                    backgroundColor: Colors.transparent,
                    iconColor: teamPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: teamPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: teamPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Team Details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: teamPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
