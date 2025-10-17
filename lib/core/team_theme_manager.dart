import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/team_theme.dart';
import 'providers.dart';

/// Provides a TeamTheme for a given team id (or null for fallback app theme colors)
final teamThemeProvider = FutureProvider.family<TeamTheme?, int?>((
  ref,
  teamId,
) async {
  if (teamId == null) return null;
  final db = ref.watch(dbProvider);
  final team = await db.getTeam(teamId);
  if (team == null) return null;
  return TeamTheme.fromTeam(team);
});

/// A widget that optionally applies a TeamTheme (if teamId provided) to descendants.
class TeamThemeScope extends ConsumerWidget {
  final int? teamId;
  final Widget child;
  const TeamThemeScope({super.key, required this.child, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamThemeAsync = ref.watch(teamThemeProvider(teamId));
    return teamThemeAsync.maybeWhen(
      data: (t) => t == null ? child : Theme(data: t.themeData, child: child),
      orElse: () => child,
    );
  }
}

/// Unified AppBar that adapts to a team's colors and provides consistent styling.
class TeamAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int? teamId;
  final String? titleText;
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;

  const TeamAppBar({
    super.key,
    this.teamId,
    this.titleText,
    this.title,
    this.actions,
    this.centerTitle = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamThemeAsync = ref.watch(teamThemeProvider(teamId));
    final scheme = Theme.of(context).colorScheme;

    return teamThemeAsync.when(
      data: (t) {
        if (t == null) {
          return _baseAppBar(context, scheme, actions);
        }
        final onPrimary = t.colorScheme.onPrimaryContainer;
        final bg = t.colorScheme.primaryContainer;
        return AppBar(
          title:
              title ??
              _TitleRow(text: titleText, color: onPrimary, teamId: teamId),
          actions: actions,
          centerTitle: centerTitle,
          elevation: elevation,
          backgroundColor: bg,
          foregroundColor: onPrimary,
        );
      },
      loading: () => _baseAppBar(context, scheme, actions, loading: true),
      error: (error, stackTrace) => _baseAppBar(context, scheme, actions),
    );
  }

  AppBar _baseAppBar(
    BuildContext context,
    ColorScheme scheme,
    List<Widget>? actions, {
    bool loading = false,
  }) {
    return AppBar(
      title: loading
          ? Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text('Loading...'),
              ],
            )
          : (title ??
                _TitleRow(
                  text: titleText,
                  color: scheme.onSurface,
                  teamId: null,
                )),
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TitleRow extends ConsumerWidget {
  final String? text;
  final Color color;
  final int? teamId;
  const _TitleRow({this.text, required this.color, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveText = text ?? '';
    if (teamId == null) {
      return Text(
        effectiveText,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final db = ref.watch(dbProvider);
    return FutureBuilder<Team?>(
      future: db.getTeam(teamId!),
      builder: (context, snapshot) {
        final teamName = snapshot.data?.name ?? effectiveText;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team logo
            if (snapshot.data?.logoImagePath != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.15),
                  child: snapshot.data?.logoImagePath == null
                      ? Icon(Icons.sports_soccer, color: color)
                      : Image.asset(
                          snapshot.data!.logoImagePath!,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.sports_soccer, color: color),
                          height: 28,
                          width: 28,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            Flexible(
              child: Text(
                teamName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact game-aware title widget: shows team logo (small), opponent and start time/date.
/// Intended to be used as the `title` of a `TeamAppBar` within a `GameScaffold`.
class GameCompactTitle extends ConsumerWidget {
  final int gameId;
  const GameCompactTitle({super.key, required this.gameId});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final nowYear = DateTime.now().year;
    final yearPart = dt.year == nowYear ? '' : '${dt.year}-';
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$yearPart$mm-$dd $hh:$min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<Game?>(
      future: db.getGame(gameId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading game...',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          );
        }
        final game = snap.data!;
        return FutureBuilder<Team?>(
          future: db.getTeam(game.teamId),
          builder: (context, teamSnap) {
            final team = teamSnap.data;
            final opponent = (game.opponent?.isNotEmpty == true)
                ? 'vs ${game.opponent}'
                : 'vs Opponent';
            final dateStr = _formatDate(game.startTime);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (team?.logoImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                      child: Image.asset(
                        team!.logoImagePath!,
                        errorBuilder: (c, e, st) => Icon(
                          Icons.sports_soccer,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opponent,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.85),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A standardized scaffold that applies TeamTheme when teamId is provided.
class TeamScaffold extends StatelessWidget {
  final int? teamId;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const TeamScaffold({
    super.key,
    this.teamId,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
    );
    if (teamId == null) return scaffold;
    return TeamThemeScope(teamId: teamId, child: scaffold);
  }
}
