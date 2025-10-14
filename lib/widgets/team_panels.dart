import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import 'team_logo_widget.dart';
import 'team_color_picker.dart';

/// Large team panel component for team lists, cards, and main displays
class TeamPanel extends ConsumerWidget {
  final int teamId;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showMode;
  final bool showArchivedBadge;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const TeamPanel({
    super.key,
    required this.teamId,
    this.onTap,
    this.trailing,
    this.showMode = true,
    this.showArchivedBadge = true,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        if (team == null) {
          return const SizedBox(
            height: 80,
            child: Card(child: Center(child: CircularProgressIndicator())),
          );
        }

        final archived = team.isArchived;

        return Container(
          margin: margin ?? const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: archived ? 0 : 2,
            color: archived
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Team Logo
                    TeamLogoWidget(
                      logoPath: team.logoImagePath,
                      size: 56,
                      backgroundColor: archived
                          ? Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.12)
                          : Theme.of(context).colorScheme.primaryContainer,
                      iconColor: archived
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),

                    // Team Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: archived
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Team Mode Badge
                              if (showMode) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: team.teamMode == 'traditional'
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.tertiaryContainer,
                                  ),
                                  child: Text(
                                    team.teamMode == 'traditional'
                                        ? 'Traditional'
                                        : 'Shift Mode',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: team.teamMode == 'traditional'
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onTertiaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],

                              // Archived Badge
                              if (archived && showArchivedBadge) ...[
                                if (showMode) const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                  ),
                                  child: Text(
                                    'Archived',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Trailing Widget
                    if (trailing != null) ...[
                      const SizedBox(width: 16),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Branded team panel with gradient colors for home page and featured displays
class TeamBrandedPanel extends ConsumerWidget {
  final int teamId;
  final String? subtitle;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const TeamBrandedPanel({
    super.key,
    required this.teamId,
    this.subtitle,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        if (team == null) {
          return const SizedBox(
            height: 120,
            child: Card(child: Center(child: CircularProgressIndicator())),
          );
        }

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
          margin: margin,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: hasTeamColors
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            teamPrimaryColor.withOpacity(0.8),
                            teamSecondaryColor.withOpacity(0.7),
                            teamPrimaryColor.withOpacity(0.6),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
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
                          size: 32,
                          backgroundColor: Colors.transparent,
                          iconColor: teamPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: Text(
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
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (subtitle != null) ...[
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
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: teamPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small team header component for page headers and compact displays
class TeamCompactHeader extends ConsumerWidget {
  final int teamId;
  final String? suffix;
  final double logoSize;
  final TextStyle? textStyle;
  final bool showColors;

  const TeamCompactHeader({
    super.key,
    required this.teamId,
    this.suffix,
    this.logoSize = 24,
    this.textStyle,
    this.showColors = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final teamName = team?.name ?? 'Team $teamId';
        final displayText = suffix != null ? '$teamName$suffix' : teamName;

        // Apply team colors if enabled and available
        Color? textColor;
        if (showColors && team?.primaryColor1 != null) {
          textColor = ColorHelper.hexToColor(team!.primaryColor1!);
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamLogoWidget(logoPath: team?.logoImagePath, size: logoSize),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                displayText,
                style:
                    textStyle?.copyWith(color: textColor) ??
                    Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: textColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}
