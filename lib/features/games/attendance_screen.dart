import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../widgets/team_logo_widget.dart';
import '../../widgets/team_color_picker.dart';

class AttendanceScreen extends ConsumerWidget {
  final int gameId;
  const AttendanceScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Game?>(
          future: db.getGame(gameId),
          builder: (context, gameSnap) {
            final game = gameSnap.data;
            if (game == null) {
              return const Text('Attendance');
            }
            final opponent = game.opponent?.isNotEmpty == true
                ? game.opponent!
                : 'Opponent';
            return Text(
              'Attendance vs $opponent',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          },
        ),
      ),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, gameSnap) {
          final game = gameSnap.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              // Compact game header
              _CompactGameHeader(game: game, subtitle: 'Attendance Tracking'),
              Expanded(
                child: StreamBuilder<List<Player>>(
                  stream: db.watchPlayersByTeam(game.teamId),
                  builder: (context, playersSnap) {
                    if (!playersSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final players = playersSnap.data!;
                    return StreamBuilder<List<GamePlayer>>(
                      stream: db.watchAttendance(gameId),
                      builder: (context, attSnap) {
                        final att = {
                          for (final a in (attSnap.data ?? <GamePlayer>[]))
                            a.playerId: a.isPresent,
                        };
                        return ListView.separated(
                          itemCount: players.length,
                          separatorBuilder: (_, __) => const Divider(height: 0),
                          itemBuilder: (_, i) {
                            final p = players[i];
                            final present = att[p.id] ?? false;
                            return SwitchListTile(
                              title: Text(
                                '${p.firstName} ${p.lastName}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              value: present,
                              onChanged: (v) => db.setAttendance(
                                gameId: gameId,
                                playerId: p.id,
                                isPresent: v,
                              ),
                            );
                          },
                        );
                      },
                    ); // end ListView.separated
                  }, // end StreamBuilder<List<GamePlayer>>
                ), // end StreamBuilder<List<Player>>
              ), // end Expanded
            ], // end Column children
          ); // end Column
        },
      ),
    );
  }
}

class _CompactGameHeader extends StatelessWidget {
  final Game game;
  final String subtitle;

  const _CompactGameHeader({required this.game, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final db = ref.watch(dbProvider);

        return FutureBuilder<Team?>(
          future: db.getTeam(game.teamId),
          builder: (context, teamSnap) {
            final team = teamSnap.data;
            if (team == null) return const SizedBox.shrink();

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

            return Container(
              margin: const EdgeInsets.all(16),
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
                boxShadow: [
                  BoxShadow(
                    color: teamPrimaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Team logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TeamLogoWidget(
                        logoPath: team.logoImagePath,
                        size: 28,
                        backgroundColor: Colors.transparent,
                        iconColor: teamPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Game info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            team.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                          ),
                          if (game.opponent?.isNotEmpty == true) ...[
                            Text(
                              'vs ${game.opponent}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: teamPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
