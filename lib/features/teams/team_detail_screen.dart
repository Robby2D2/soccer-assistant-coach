import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/team_header.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/team_color_picker.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class TeamDetailScreen extends ConsumerWidget {
  final int id;
  const TeamDetailScreen({super.key, required this.id});

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    Team? team, // Add team parameter for color theming
  }) {
    // Use team colors if available, fallback to provided colors
    final cardColor = team?.primaryColor1 != null
        ? (ColorHelper.hexToColor(team!.primaryColor1!) ??
                  Theme.of(context).colorScheme.primary)
              .withOpacity(0.15)
        : color;
    final cardIconColor = team?.primaryColor1 != null
        ? (ColorHelper.hexToColor(team!.primaryColor1!) ??
              Theme.of(context).colorScheme.primary)
        : iconColor;

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cardColor,
                ),
                child: Icon(icon, color: cardIconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final db = ref.watch(dbProvider);

    return TeamScaffold(
      teamId: id,
      appBar: TeamAppBar(
        teamId: id,
        titleText: 'Team',
        actions: StandardizedAppBarActions.createActionsWidgets([
          CommonNavigationActions.home(context),
          CommonNavigationActions.edit(context, '/team/$id/edit'),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team info header with team branding
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: TeamBrandedHeader(
                teamId: id,
                subtitle: loc.teamManagementHub,
              ),
            ),

            // Management sections
            Text(
              loc.teamManagement,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Players card
            FutureBuilder<Team?>(
              future: db.getTeam(id),
              builder: (context, snapshot) {
                final team = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildManagementCard(
                      context,
                      icon: Icons.people,
                      title: loc.players,
                      subtitle: loc.manageTeamRosterDescription,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      iconColor: Theme.of(context).colorScheme.primary,
                      team: team,
                      onTap: () => context.push('/team/$id/players'),
                    ),
                    const SizedBox(height: 12),

                    // Formations card
                    _buildManagementCard(
                      context,
                      icon: Icons.grid_view_rounded,
                      title: loc.formations,
                      subtitle: loc.setupTacticalFormationsDescription,
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      iconColor: Theme.of(context).colorScheme.secondary,
                      team: team,
                      onTap: () => context.push('/team/$id/formations'),
                    ),

                    const SizedBox(height: 32),

                    // Game management section
                    Text(
                      loc.gameManagement,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Games card
                    _buildManagementCard(
                      context,
                      icon: Icons.sports_soccer,
                      title: loc.games,
                      subtitle: loc.scheduleGamesDescription,
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      iconColor: Theme.of(context).colorScheme.tertiary,
                      team: team,
                      onTap: () => context.push('/team/$id/games'),
                    ),
                    const SizedBox(height: 12),

                    // Team Metrics card
                    _buildManagementCard(
                      context,
                      icon: Icons.analytics,
                      title: loc.teamMetrics,
                      subtitle: loc.viewPlayerStatisticsDescription,
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      iconColor: Theme.of(context).colorScheme.onSurface,
                      team: team,
                      onTap: () => context.push('/team/$id/metrics'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
