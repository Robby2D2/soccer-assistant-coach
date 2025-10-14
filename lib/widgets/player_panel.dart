import 'dart:io';
import 'package:flutter/material.dart';
import '../data/db/database.dart';
import 'player_avatar.dart';

enum PlayerPanelType {
  active, // Active players with position badges
  bench, // Bench players with SUB badges
  substitute, // Players in substitution dialogs
  current, // Current player being substituted (highlighted)
  shift, // Players in shift-based mode with position badges
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
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  bool _hasProfileImage() {
    if (player.profileImagePath == null || player.profileImagePath!.isEmpty) {
      return false;
    }
    // Check if the image file actually exists
    try {
      final imageFile = File(player.profileImagePath!);
      return imageFile.existsSync();
    } catch (e) {
      return false;
    }
  }

  String _getPlayerDisplayName() {
    final hasImage = _hasProfileImage();
    final hasJerseyNumber = player.jerseyNumber != null;

    // If player has both image and jersey number, show number before name
    if (hasImage && hasJerseyNumber) {
      return '#${player.jerseyNumber} ${player.firstName} ${player.lastName}';
    }

    // Otherwise just show the name
    return '${player.firstName} ${player.lastName}';
  }

  Widget _buildBadge(BuildContext context) {
    switch (type) {
      case PlayerPanelType.active:
      case PlayerPanelType.current:
      case PlayerPanelType.shift:
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
        Flexible(
          child: Text(
            _formatPlayingTime(playingTime!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 9,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        radius ?? (type == PlayerPanelType.current ? 18.0 : 16.0);
    final effectivePadding =
        padding ??
        (type == PlayerPanelType.current
            ? const EdgeInsets.all(12)
            : const EdgeInsets.all(6));

    Widget cardContent = InkWell(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(flex: 2, child: _buildBadge(context)),
                        const SizedBox(width: 4),
                        Flexible(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildPlayingTimeInfo(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Player name (with jersey number if both image and number exist)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _getPlayerDisplayName(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: type == PlayerPanelType.substitute
                              ? 10
                              : (type == PlayerPanelType.current ? 12 : 11),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

    // Special styling for current player being substituted
    if (type == PlayerPanelType.current) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: cardContent,
      );
    }

    return Card(margin: EdgeInsets.zero, child: cardContent);
  }
}
