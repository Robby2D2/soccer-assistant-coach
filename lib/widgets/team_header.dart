import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import 'team_logo_widget.dart';
import 'team_color_picker.dart';

/// A team header with team colors as background gradient.
///
/// Legacy pre-Sideline widget (hand-rolled gradient/contrast, FutureBuilder
/// team fetch) — slated for replacement during the Teams/Roster Sideline
/// restyle. Don't use in new screens; see .agents/COMPONENTS.md.
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
