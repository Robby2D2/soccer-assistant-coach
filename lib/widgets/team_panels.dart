import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import 'team_logo_widget.dart';
import 'team_color_picker.dart';

/// Team list panel with vibrant gradients for the teams list page.
///
/// Legacy pre-Sideline widget (hand-rolled gradient/contrast, FutureBuilder
/// team fetch) — slated for replacement during the Teams/Roster Sideline
/// restyle. Don't use in new screens; see .agents/COMPONENTS.md.
class TeamListPanel extends ConsumerWidget {
  final int teamId;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showMode;
  final bool showArchivedBadge;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const TeamListPanel({
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

        // Use team colors if available
        final hasTeamColors = team.primaryColor1 != null && !archived;
        final teamPrimaryColor = hasTeamColors
            ? (ColorHelper.hexToColor(team.primaryColor1!) ??
                  Theme.of(context).colorScheme.primary)
            : Theme.of(context).colorScheme.primary;

        final teamSecondaryColor = hasTeamColors && team.primaryColor2 != null
            ? (ColorHelper.hexToColor(team.primaryColor2!) ??
                  teamPrimaryColor.withOpacity(0.7))
            : teamPrimaryColor.withOpacity(0.7);

        return Container(
          margin: margin ?? const EdgeInsets.only(bottom: 12),
          child: Material(
            elevation: archived ? 0 : (hasTeamColors ? 6 : 2),
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
                            archived
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.surface,
                            archived
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.surface,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Team Logo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasTeamColors
                              ? Colors.white.withOpacity(0.9)
                              : (archived
                                    ? Theme.of(context).colorScheme.outline
                                          .withValues(alpha: 0.12)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: hasTeamColors
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: TeamLogoWidget(
                          logoPath: team.logoImagePath,
                          size: 40,
                          backgroundColor: Colors.transparent,
                          iconColor: hasTeamColors
                              ? teamPrimaryColor
                              : (archived
                                    ? Theme.of(context).colorScheme.outline
                                    : Theme.of(context).colorScheme.primary),
                        ),
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
                                    fontWeight: FontWeight.bold,
                                    color: hasTeamColors
                                        ? Colors.white
                                        : (archived
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant
                                              : null),
                                    shadows: hasTeamColors
                                        ? [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                            ),
                                          ]
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
                                      color: hasTeamColors
                                          ? Colors.white.withOpacity(0.9)
                                          : (team.teamMode == 'traditional'
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .tertiaryContainer),
                                    ),
                                    child: Text(
                                      team.teamMode == 'traditional'
                                          ? 'Traditional'
                                          : 'Shift Mode',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: hasTeamColors
                                                ? teamPrimaryColor
                                                : (team.teamMode ==
                                                          'traditional'
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .onSecondaryContainer
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .onTertiaryContainer),
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
          ),
        );
      },
    );
  }
}
