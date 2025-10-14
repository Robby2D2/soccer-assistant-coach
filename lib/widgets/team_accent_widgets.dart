import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import 'team_color_picker.dart';

/// A set of widgets that use team colors for consistent branding across the app

/// Team-themed FloatingActionButton
class TeamFloatingActionButton extends ConsumerWidget {
  final int teamId;
  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;

  const TeamFloatingActionButton({
    super.key,
    required this.teamId,
    required this.onPressed,
    required this.child,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final hasTeamColors = team?.primaryColor1 != null;

        if (!hasTeamColors) {
          return FloatingActionButton(
            onPressed: onPressed,
            tooltip: tooltip,
            child: child,
          );
        }

        final teamColor =
            ColorHelper.hexToColor(team!.primaryColor1!) ??
            Theme.of(context).colorScheme.primary;
        final onTeamColor = teamColor.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white;

        return FloatingActionButton(
          onPressed: onPressed,
          tooltip: tooltip,
          backgroundColor: teamColor,
          foregroundColor: onTeamColor,
          child: child,
        );
      },
    );
  }
}

/// Team-themed FilledButton
class TeamFilledButton extends ConsumerWidget {
  final int teamId;
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;

  const TeamFilledButton({
    super.key,
    required this.teamId,
    required this.onPressed,
    required this.child,
    this.icon,
  });

  const TeamFilledButton.icon({
    super.key,
    required this.teamId,
    required this.onPressed,
    required this.child,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final hasTeamColors = team?.primaryColor1 != null;

        final button = icon != null
            ? FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: child,
              )
            : FilledButton(onPressed: onPressed, child: child);

        if (!hasTeamColors) {
          return button;
        }

        final teamColor =
            ColorHelper.hexToColor(team!.primaryColor1!) ??
            Theme.of(context).colorScheme.primary;
        final onTeamColor = teamColor.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white;

        final styledButton = icon != null
            ? FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: child,
                style: FilledButton.styleFrom(
                  backgroundColor: teamColor,
                  foregroundColor: onTeamColor,
                ),
              )
            : FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: teamColor,
                  foregroundColor: onTeamColor,
                ),
                child: child,
              );

        return styledButton;
      },
    );
  }
}

/// Team-themed Card with subtle color accent
class TeamCard extends ConsumerWidget {
  final int teamId;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? elevation;

  const TeamCard({
    super.key,
    required this.teamId,
    required this.child,
    this.onTap,
    this.padding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final hasTeamColors = team?.primaryColor1 != null;

        if (!hasTeamColors) {
          return Card(
            elevation: elevation,
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: padding ?? const EdgeInsets.all(16),
                      child: child,
                    ),
                  )
                : Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
          );
        }

        final teamColor =
            ColorHelper.hexToColor(team!.primaryColor1!) ??
            Theme.of(context).colorScheme.primary;

        return Card(
          elevation: elevation,
          color: teamColor.withOpacity(0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: teamColor.withOpacity(0.2), width: 1),
          ),
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                )
              : Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
        );
      },
    );
  }
}

/// Team-themed Divider
class TeamDivider extends ConsumerWidget {
  final int teamId;
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  const TeamDivider({
    super.key,
    required this.teamId,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final hasTeamColors = team?.primaryColor1 != null;

        if (!hasTeamColors) {
          return Divider(
            height: height,
            thickness: thickness,
            indent: indent,
            endIndent: endIndent,
          );
        }

        final teamColor =
            ColorHelper.hexToColor(team!.primaryColor1!) ??
            Theme.of(context).colorScheme.primary;

        return Divider(
          height: height,
          thickness: thickness,
          indent: indent,
          endIndent: endIndent,
          color: teamColor.withOpacity(0.3),
        );
      },
    );
  }
}

/// Team-themed Container with gradient background
class TeamGradientContainer extends ConsumerWidget {
  final int teamId;
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double opacity;

  const TeamGradientContainer({
    super.key,
    required this.teamId,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final hasTeamColors = team?.primaryColor1 != null;

        if (!hasTeamColors) {
          return Container(
            padding: padding,
            margin: margin,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            child: child,
          );
        }

        final primaryColor =
            ColorHelper.hexToColor(team!.primaryColor1!) ??
            Theme.of(context).colorScheme.primary;
        final secondaryColor = team.primaryColor2 != null
            ? (ColorHelper.hexToColor(team.primaryColor2!) ??
                  Theme.of(context).colorScheme.primary)
            : primaryColor.withOpacity(0.7);

        return Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(opacity),
                secondaryColor.withOpacity(opacity),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          child: child,
        );
      },
    );
  }
}

/// Team-themed Badge/Chip
class TeamBadge extends ConsumerWidget {
  final int teamId;
  final Widget label;
  final IconData? icon;
  final VoidCallback? onTap;

  const TeamBadge({
    super.key,
    required this.teamId,
    required this.label,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return FutureBuilder<Team?>(
      future: db.getTeam(teamId),
      builder: (context, snapshot) {
        final team = snapshot.data;
        final hasTeamColors = team?.primaryColor1 != null;

        if (!hasTeamColors) {
          return ActionChip(
            avatar: icon != null ? Icon(icon, size: 16) : null,
            label: label,
            onPressed: onTap,
          );
        }

        final teamColor =
            ColorHelper.hexToColor(team!.primaryColor1!) ??
            Theme.of(context).colorScheme.primary;
        final onTeamColor = teamColor.computeLuminance() > 0.5
            ? Colors.black87
            : Colors.white;

        return ActionChip(
          avatar: icon != null
              ? Icon(icon, size: 16, color: onTeamColor)
              : null,
          label: DefaultTextStyle(
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(color: onTeamColor),
            child: label,
          ),
          backgroundColor: teamColor.withOpacity(0.9),
          onPressed: onTap,
        );
      },
    );
  }
}
