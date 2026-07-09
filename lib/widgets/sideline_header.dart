import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/sideline.dart';
import '../utils/team_theme.dart';
import 'sideline_widgets.dart';

/// The shared full-bleed branded header band: a team-colored band with a rounded
/// bottom, a status row (back · optional status · actions), then the crest +
/// title + subtitle and an optional trailing box. This is the single source of
/// truth for the look used by both the Live Game header ([SidelineGameHeader])
/// and team-scoped management screens ([SidelineScreenHeader]). The band paints
/// behind the status bar, so it is meant to sit at the very top of a screen body
/// (no AppBar above it).
class SidelineHeaderBand extends StatelessWidget {
  /// Big bold title, e.g. the team name.
  final String title;

  /// Caption under the title, e.g. "vs Opponent" or a section label.
  final String? subtitle;

  /// Single character shown in the white crest (typically the team initial).
  final String crestInitial;

  /// Band background color (the team color).
  final Color band;

  /// Foreground color readable on [band].
  final Color onBand;

  /// Trailing actions for the status row (e.g. a kebab menu). Rendered with an
  /// [IconTheme] tinted for the band.
  final List<Widget>? actions;

  /// Optional leading widget in the status row (e.g. the LIVE pill).
  final Widget? statusLeading;

  /// Optional trailing widget beside the title (e.g. the score box).
  final Widget? trailing;

  const SidelineHeaderBand({
    super.key,
    required this.title,
    required this.crestInitial,
    required this.band,
    required this.onBand,
    this.subtitle,
    this.actions,
    this.statusLeading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // The band paints behind the status bar, so match the status-bar icon
    // brightness to the band: light icons on a dark team color, dark icons on a
    // light one.
    final bandIsDark =
        ThemeData.estimateBrightnessForColor(band) == Brightness.dark;
    final overlay =
        (bandIsDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: band,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(SidelineRadius.headerBottom),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                        color: onBand,
                        tooltip: 'Back',
                      )
                    else
                      const SizedBox(width: 12),
                    if (statusLeading != null) statusLeading!,
                    const Spacer(),
                    if (actions != null && actions!.isNotEmpty)
                      IconTheme.merge(
                        data: IconThemeData(color: onBand),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      SidelineCrest(initial: crestInitial, teamColor: band),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: onBand,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: onBand.withOpacity(0.85),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 10),
                        trailing!,
                      ],
                    ],
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

/// The white rounded-square crest holding the team initial, as used in the
/// branded header band.
class SidelineCrest extends StatelessWidget {
  final String initial;
  final Color teamColor;
  const SidelineCrest({
    super.key,
    required this.initial,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    // Draw the initial in the darkened "strong" shade so it stays legible on
    // the white crest even when the team color itself is light.
    final initialColor = TeamColors.fromSeed(teamColor).strong;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: initialColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The branded header band for team-scoped management screens (roster,
/// formations, team metrics, edit screens, …). Shows the team name as the title
/// with a section [subtitle], matching the Live Game header's look. Must sit
/// inside a `TeamThemeScope` (e.g. via `TeamScaffold(teamId: …)`) so it picks up
/// the team color.
class SidelineScreenHeader extends ConsumerWidget {
  final int teamId;

  /// Big title. Defaults to the team name when null.
  final String? title;

  /// Section label shown under the title, e.g. "Players" or "Team Metrics".
  final String? subtitle;

  /// Trailing actions for the status row (e.g. home / edit / kebab).
  final List<Widget>? actions;

  /// Optional trailing widget beside the title.
  final Widget? trailing;

  const SidelineScreenHeader({
    super.key,
    required this.teamId,
    this.title,
    this.subtitle,
    this.actions,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final team = teamColorsOf(context);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snap) {
        final teamName = snap.data?.name ?? 'Team';
        final trimmed = teamName.trim();
        final initial = trimmed.isEmpty
            ? '?'
            : trimmed.substring(0, 1).toUpperCase();
        return SidelineHeaderBand(
          title: title ?? teamName,
          subtitle: subtitle,
          actions: actions,
          trailing: trailing,
          crestInitial: initial,
          band: team.team,
          onBand: team.onTeam,
        );
      },
    );
  }
}
