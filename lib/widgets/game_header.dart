import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/sideline.dart';
import 'sideline_header.dart';
import 'sideline_widgets.dart';

/// The Live Game branded header band: a full-bleed team-colored band with a
/// rounded bottom, a status row (back · LIVE · actions), then the crest + team
/// name + "vs Opponent" and a score / period box. Designed to sit at the very
/// top of the game body (the band fills behind the status bar).
class SidelineGameHeader extends ConsumerWidget {
  final int gameId;

  /// Trailing actions for the status row (e.g. the game kebab menu). Rendered
  /// with an [IconTheme] tinted for the band.
  final List<Widget>? actions;

  const SidelineGameHeader({super.key, required this.gameId, this.actions});

  String _halfLabel(int half) => switch (half) {
    1 => '1ST HALF',
    2 => '2ND HALF',
    _ => 'HALF $half',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final team = teamColorsOf(context);
    final band = team.team;
    final onBand = team.onTeam;

    return FutureBuilder<Game?>(
      future: db.getGame(gameId),
      builder: (context, gameSnap) {
        final game = gameSnap.data;
        return FutureBuilder<Team?>(
          future: game == null
              ? Future<Team?>.value(null)
              : db.getTeam(game.teamId),
          builder: (context, teamSnap) {
            final teamName = teamSnap.data?.name ?? 'Team';
            final trimmed = teamName.trim();
            final initial = trimmed.isEmpty
                ? '?'
                : trimmed.substring(0, 1).toUpperCase();
            final opponentName = game?.opponent?.trim() ?? '';
            final opponent = opponentName.isEmpty
                ? 'vs Opponent'
                : 'vs $opponentName';
            final isLive = game?.gameStatus == 'in-progress';

            return SidelineHeaderBand(
              title: teamName,
              subtitle: opponent,
              crestInitial: initial,
              band: band,
              onBand: onBand,
              actions: actions,
              statusLeading: isLive ? _LivePill(color: onBand) : null,
              trailing: _ScoreBox(
                teamScore: game?.teamScore ?? 0,
                opponentScore: game?.opponentScore ?? 0,
                periodLabel: game?.gameStatus == 'completed'
                    ? 'FINAL'
                    : _halfLabel(game?.currentHalf ?? 1),
                onBand: onBand,
              ),
            );
          },
        );
      },
    );
  }
}

class _LivePill extends StatelessWidget {
  final Color color;
  const _LivePill({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDot(color: color),
        const SizedBox(width: 6),
        Text(
          'LIVE',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.35).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int teamScore;
  final int opponentScore;
  final String periodLabel;
  final Color onBand;

  const _ScoreBox({
    required this.teamScore,
    required this.opponentScore,
    required this.periodLabel,
    required this.onBand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(SidelineRadius.row),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$teamScore–$opponentScore',
            style: sidelineMono(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: onBand,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            periodLabel,
            style: sidelineMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: onBand.withOpacity(0.85),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
