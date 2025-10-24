import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';

/// Standardized navigation action that can appear as both an icon and in the kebab menu
class NavigationAction {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool showAsIcon;

  const NavigationAction({
    required this.label,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.showAsIcon = false,
  });
}

/// Common navigation actions factory
class CommonNavigationActions {
  static NavigationAction home(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.home,
      icon: Icons.home,
      tooltip: loc.home,
      showAsIcon: true,
      onPressed: () => context.go('/'),
    );
  }

  static NavigationAction settings(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.settings,
      icon: Icons.settings,
      tooltip: loc.settings,
      showAsIcon: true,
      onPressed: () => context.push('/settings'),
    );
  }

  static NavigationAction edit(BuildContext context, String route) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.edit,
      icon: Icons.edit,
      tooltip: loc.edit,
      showAsIcon: true,
      onPressed: () => context.push(route),
    );
  }

  static NavigationAction delete(BuildContext context, VoidCallback onPressed) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.delete,
      icon: Icons.delete_outline,
      onPressed: onPressed,
    );
  }

  static NavigationAction archive(
    BuildContext context,
    VoidCallback onPressed, {
    bool isArchived = false,
  }) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: isArchived ? loc.restore : loc.archive,
      icon: isArchived ? Icons.unarchive : Icons.archive_outlined,
      onPressed: onPressed,
    );
  }

  static NavigationAction export(BuildContext context, VoidCallback onPressed) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.exportCsv,
      icon: Icons.file_download,
      tooltip: loc.exportCsv,
      showAsIcon: true,
      onPressed: onPressed,
    );
  }

  static NavigationAction inputMetrics(BuildContext context, int gameId) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.inputMetrics,
      icon: Icons.edit,
      tooltip: loc.inputMetrics,
      showAsIcon: true,
      onPressed: () => context.push('/game/$gameId/metrics/input'),
    );
  }

  static NavigationAction viewMetrics(BuildContext context, int gameId) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.viewMetrics,
      icon: Icons.analytics,
      onPressed: () => context.push('/game/$gameId/metrics'),
    );
  }

  static NavigationAction attendance(BuildContext context, int gameId) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.attendance,
      icon: Icons.group,
      onPressed: () => context.push('/game/$gameId/attendance'),
    );
  }

  static NavigationAction formation(BuildContext context, int gameId) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.formation,
      icon: Icons.grid_view_rounded,
      onPressed: () => context.push('/game/$gameId/formation'),
    );
  }

  static NavigationAction endGame(BuildContext context, int gameId) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.endGame,
      icon: Icons.stop,
      onPressed: () => context.push('/game/$gameId/end'),
    );
  }

  static NavigationAction reset(BuildContext context, VoidCallback onPressed) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.reset,
      icon: Icons.refresh,
      onPressed: onPressed,
    );
  }

  static NavigationAction database(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return NavigationAction(
      label: loc.databaseDiagnostics,
      icon: Icons.bug_report,
      onPressed: () => context.push('/debug/database'),
    );
  }
}

/// Widget that creates standardized AppBar actions with both icons and kebab menu
class StandardizedAppBarActions extends StatelessWidget {
  final List<NavigationAction> actions;
  final List<NavigationAction> additionalMenuItems;

  const StandardizedAppBarActions({
    super.key,
    required this.actions,
    this.additionalMenuItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final iconActions = actions.where((action) => action.showAsIcon).toList();
    final menuActions = actions.toList();
    menuActions.addAll(additionalMenuItems);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show icon buttons for actions marked as showAsIcon
        ...iconActions.map(
          (action) => IconButton(
            icon: Icon(action.icon),
            tooltip: action.tooltip ?? action.label,
            onPressed: action.onPressed,
          ),
        ),

        // Always show kebab menu with ALL actions (including those shown as icons)
        if (menuActions.isNotEmpty)
          PopupMenuButton<NavigationAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              if (action.onPressed != null) action.onPressed!();
            },
            itemBuilder: (context) => menuActions
                .map(
                  (action) => PopupMenuItem<NavigationAction>(
                    value: action,
                    child: ListTile(
                      leading: Icon(action.icon),
                      title: Text(action.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  /// Create actions list from widgets for backward compatibility
  static List<Widget> createActionsWidgets(
    List<NavigationAction> actions, {
    List<NavigationAction> additionalMenuItems = const [],
  }) {
    return [
      StandardizedAppBarActions(
        actions: actions,
        additionalMenuItems: additionalMenuItems,
      ),
    ];
  }
}
