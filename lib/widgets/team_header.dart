import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import 'team_logo_widget.dart';
import 'team_color_picker.dart';

/// A widget that displays team logo + name for use in AppBars and headers
class TeamHeader extends ConsumerWidget {
  final int teamId;
  final String? suffix; // Optional suffix like " Games", " Players", etc.
  final double logoSize;
  final TextStyle? textStyle;
  final MainAxisAlignment alignment;
  final bool showName;
  final int maxLines;

  const TeamHeader({
    super.key,
    required this.teamId,
    this.suffix,
    this.logoSize = 32,
    this.textStyle,
    this.alignment = MainAxisAlignment.start,
    this.showName = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;

        if (!showName) {
          return TeamLogoWidget(logoPath: team?.logoImagePath, size: logoSize);
        }

        final teamName = team?.name ?? 'Team $teamId';
        final displayText = suffix != null ? '$teamName$suffix' : teamName;

        return Row(
          mainAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamLogoWidget(logoPath: team?.logoImagePath, size: logoSize),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                displayText,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: maxLines,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A compact team header for use in smaller spaces
class CompactTeamHeader extends ConsumerWidget {
  final int teamId;
  final String? suffix;

  const CompactTeamHeader({super.key, required this.teamId, this.suffix});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TeamHeader(
      teamId: teamId,
      suffix: suffix,
      logoSize: 24,
      textStyle: Theme.of(context).textTheme.titleMedium,
      maxLines: 1,
    );
  }
}

/// A team header that displays team logo + name in a card format
class TeamHeaderCard extends ConsumerWidget {
  final int teamId;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const TeamHeaderCard({
    super.key,
    required this.teamId,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final teamName = team?.name ?? 'Team $teamId';

        return Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: Row(
                children: [
                  TeamLogoWidget(logoPath: team?.logoImagePath, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A team header with team colors as background gradient
class TeamBrandedHeader extends ConsumerWidget {
  final int teamId;
  final String? title;
  final String? subtitle;
  final Widget? child;
  final EdgeInsets? padding;

  const TeamBrandedHeader({
    super.key,
    required this.teamId,
    this.title,
    this.subtitle,
    this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final teamName = team?.name ?? 'Team $teamId';
        final displayTitle = title ?? teamName;

        // Determine background based on team colors
        final hasTeamColors = team?.primaryColor1 != null;
        final decoration = hasTeamColors
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorHelper.hexToColor(team!.primaryColor1!) ??
                        Theme.of(context).colorScheme.primary,
                    team.primaryColor2 != null
                        ? (ColorHelper.hexToColor(team.primaryColor2!) ??
                              Theme.of(context).colorScheme.primary)
                        : (ColorHelper.hexToColor(team.primaryColor1!) ??
                                  Theme.of(context).colorScheme.primary)
                              .withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              )
            : BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              );

        final textColor = hasTeamColors
            ? ((ColorHelper.hexToColor(team!.primaryColor1!) ??
                              Theme.of(context).colorScheme.primary)
                          .computeLuminance() >
                      0.5
                  ? Colors.black87
                  : Colors.white)
            : Theme.of(context).colorScheme.onPrimaryContainer;

        return Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: decoration,
          child:
              child ??
              Row(
                children: [
                  TeamLogoWidget(
                    logoPath: team?.logoImagePath,
                    size: 64,
                    backgroundColor: textColor.withOpacity(0.2),
                    iconColor: textColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: textColor.withOpacity(0.8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }
}
