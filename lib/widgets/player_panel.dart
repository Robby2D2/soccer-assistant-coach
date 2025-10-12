import 'package:flutter/material.dart';
import '../data/db/database.dart';
import 'player_avatar.dart';

enum PlayerPanelType {
  active, // Active players with position badges
  bench, // Bench players with SUB badges
  substitute, // Players in substitution dialogs
}

class PlayerPanel extends StatelessWidget {
  final Player player;
  final PlayerPanelType type;
  final VoidCallback? onTap;
  final String? position; // For active players
  final int? playingTime; // In seconds
  final String Function(String)? getPositionAbbreviation;
  final double? radius;
  final EdgeInsets? padding;

  const PlayerPanel({
    super.key,
    required this.player,
    required this.type,
    this.onTap,
    this.position,
    this.playingTime,
    this.getPositionAbbreviation,
    this.radius,
    this.padding,
  });

  String _formatPlayingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildBadge(BuildContext context) {
    switch (type) {
      case PlayerPanelType.active:
        if (position != null && getPositionAbbreviation != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              getPositionAbbreviation!(position!),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }
        return const SizedBox.shrink();
      case PlayerPanelType.bench:
      case PlayerPanelType.substitute:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'SUB',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        );
    }
  }

  Widget _buildPlayingTimeInfo(BuildContext context) {
    if (playingTime == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer,
          size: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 1),
        Text(
          _formatPlayingTime(playingTime!),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? 16.0;
    final effectivePadding = padding ?? const EdgeInsets.all(6);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: effectivePadding,
          child: Row(
            children: [
              // Player avatar
              PlayerAvatar(
                firstName: player.firstName,
                lastName: player.lastName,
                jerseyNumber: player.jerseyNumber,
                profileImagePath: player.profileImagePath,
                radius: effectiveRadius,
              ),
              const SizedBox(width: 8),
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildBadge(context),
                        const Spacer(),
                        _buildPlayingTimeInfo(context),
                      ],
                    ),
                    const SizedBox(height: 1),
                    // Player name
                    Flexible(
                      child: Text(
                        '${player.firstName} ${player.lastName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: type == PlayerPanelType.substitute
                              ? 10
                              : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
