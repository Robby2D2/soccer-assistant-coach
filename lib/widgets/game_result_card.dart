import 'package:flutter/material.dart';

import '../core/providers.dart';
import '../l10n/app_localizations.dart';

/// The shared game summary tile: soccer icon, "vs Opponent", a date pill and —
/// for completed games — a win/loss/draw colored score badge plus result pill.
/// Single source of truth for how a game is summarized across the games list,
/// the team landing "Most Recent Game" card, and the game screen's completed
/// panel.
class GameResultCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g. the games list kebab menu).
  final Widget? trailing;

  const GameResultCard({
    super.key,
    required this.game,
    this.onTap,
    this.trailing,
  });

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day • $hour:$minute';
  }

  Color _resultColor() {
    if (game.teamScore > game.opponentScore) {
      return Colors.green; // Win
    } else if (game.teamScore < game.opponentScore) {
      return Colors.red; // Loss
    } else {
      return Colors.orange; // Draw
    }
  }

  String _resultText(AppLocalizations loc) {
    if (game.teamScore > game.opponentScore) {
      return loc.win;
    } else if (game.teamScore < game.opponentScore) {
      return loc.loss;
    } else {
      return loc.draw;
    }
  }

  Widget _pill(
    BuildContext context,
    String label,
    Color background,
    Color foreground, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final archived = game.isArchived;
    final completed = game.gameStatus == 'completed';

    return Card(
      elevation: archived ? 0 : 2,
      color: archived
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: archived
                      ? Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.tertiaryContainer,
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: archived
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            game.opponent?.isNotEmpty == true
                                ? 'vs ${game.opponent!}'
                                : 'vs Opponent',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: archived
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : null,
                                ),
                          ),
                        ),
                        if (completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: _resultColor(),
                            ),
                            child: Text(
                              '${game.teamScore}–${game.opponentScore}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (game.startTime != null)
                          _pill(
                            context,
                            _formatDate(game.startTime!),
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        if (completed)
                          _pill(
                            context,
                            _resultText(loc),
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.onPrimaryContainer,
                            icon: Icons.check_circle_outline,
                          )
                        else if (game.isGameActive)
                          _pill(
                            context,
                            'LIVE',
                            Theme.of(
                              context,
                            ).colorScheme.errorContainer.withValues(alpha: 0.6),
                            Theme.of(context).colorScheme.error,
                            icon: Icons.circle,
                          ),
                        if (archived)
                          _pill(
                            context,
                            'Archived',
                            Theme.of(context).colorScheme.errorContainer,
                            Theme.of(context).colorScheme.onErrorContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
