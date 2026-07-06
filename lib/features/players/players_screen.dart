import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

import '../../utils/csv.dart';
import '../../utils/files.dart';
import '../../core/positions.dart';
import '../../core/sideline.dart';
import '../../widgets/sideline_widgets.dart';
import '../../core/team_theme_manager.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/sideline_header.dart';
import '../../widgets/sideline_team_tabs.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class PlayersScreen extends ConsumerWidget {
  final int teamId;
  const PlayersScreen({super.key, required this.teamId});

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.people,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noPlayersYet,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              loc.noPlayersYetDescriptionOnboarding,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final db = ProviderScope.containerOf(
                      context,
                    ).read(dbProvider);

                    // Get team's season
                    final team = await db.getTeam(teamId);
                    if (team == null) return;

                    await db
                        .into(db.players)
                        .insert(
                          PlayersCompanion.insert(
                            teamId: teamId,
                            seasonId: team.seasonId,
                            firstName: loc.newPlayer,
                            lastName: loc.player,
                            isPresent: const drift.Value(true),
                          ),
                        );
                  },
                  icon: const Icon(Icons.person_add),
                  label: Text(loc.addPlayer),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      GoRouter.of(context).push('/team/$teamId/players/import'),
                  icon: const Icon(Icons.file_upload),
                  label: Text(loc.importCsv),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final db = ref.watch(dbProvider);
    return TeamScaffold(
      teamId: teamId,
      header: SidelineScreenHeader(
        teamId: teamId,
        subtitle: loc.players,
        actions: StandardizedAppBarActions.createActionsWidgets(
          [
            CommonNavigationActions.export(context, () async {
              final players = await db.getPlayersByTeam(teamId);
              final rows = players
                  .map(
                    (p) => {
                      'firstName': p.firstName,
                      'lastName': p.lastName,
                      'jerseyNumber': p.jerseyNumber?.toString() ?? '',
                    },
                  )
                  .toList();
              final csv = playersToCsv(rows);
              final path = await saveTextFile('team_${teamId}_roster.csv', csv);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Saved CSV to $path')));
              }
            }),
          ],
          additionalMenuItems: [
            NavigationAction(
              label: loc.importCsv,
              icon: Icons.file_upload,
              onPressed: () => context.push('/team/$teamId/players/import'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: SidelineColors.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () async {
                  final team = await db.getTeam(teamId);
                  if (team == null) return;
                  await db
                      .into(db.players)
                      .insert(
                        PlayersCompanion.insert(
                          teamId: teamId,
                          seasonId: team.seasonId,
                          firstName: 'New',
                          lastName: 'Player',
                          isPresent: const drift.Value(true),
                        ),
                      );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add player'),
                style: FilledButton.styleFrom(
                  backgroundColor: SidelineColors.ink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Team?>(
        future: db.getTeam(teamId),
        builder: (context, teamSnapshot) {
          final team = teamSnapshot.data;
          if (team == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Player>>(
            stream: db.watchPlayersByTeam(teamId, seasonId: team.seasonId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final rows = snap.data as List<Player>;
              final activeCount = rows.where((p) => p.isPresent).length;
              // PM spec: the count bar must be visible even on an empty roster
              // (shows "0 players · 0 active"). The empty-state widget is shown
              // *below* the summary, not in place of it.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SidelineTeamTabs(
                    teamId: teamId,
                    current: SidelineTeamTab.roster,
                  ),
                  _RosterCountSummary(total: rows.length, active: activeCount),
                  Expanded(
                    child: rows.isEmpty
                        ? _buildEmptyState(context)
                        : _RosterList(teamId: teamId, players: rows, db: db),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _RosterCountSummary extends StatelessWidget {
  final int total;
  final int active;

  const _RosterCountSummary({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        loc.rosterCountSummary(total, active),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String msg) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

/// Sideline roster: position filter chips + clean player rows (number badge,
/// name, appearances, primary-position chip). Primary position + appearances
/// are loaded once from the DB.
class _RosterList extends StatefulWidget {
  final int teamId;
  final List<Player> players;
  final AppDb db;

  const _RosterList({
    required this.teamId,
    required this.players,
    required this.db,
  });

  @override
  State<_RosterList> createState() => _RosterListState();
}

class _RosterListState extends State<_RosterList> {
  String _filter = 'All';
  late Future<(Map<int, String>, Map<int, int>)> _meta;

  @override
  void initState() {
    super.initState();
    _meta = _loadMeta();
  }

  Future<(Map<int, String>, Map<int, int>)> _loadMeta() async {
    final positions = await widget.db.primaryPositionByPlayer(widget.teamId);
    final appearances = await widget.db.appearancesByPlayer(widget.teamId);
    return (positions, appearances);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Map<int, String>, Map<int, int>)>(
      future: _meta,
      builder: (context, snap) {
        final positions = snap.data?.$1 ?? const <int, String>{};
        final appearances = snap.data?.$2 ?? const <int, int>{};
        String? catOf(Player p) {
          final pos = positions[p.id];
          return pos == null ? null : positionCategory(pos);
        }

        final filtered = _filter == 'All'
            ? widget.players
            : widget.players.where((p) => catOf(p) == _filter).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _filterChips(catOf),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return _PlayerRow(
                    player: p,
                    category: catOf(p),
                    appearances: appearances[p.id] ?? 0,
                    db: widget.db,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChips(String? Function(Player) catOf) {
    final team = teamColorsOf(context);
    final cats = ['All', ...kPositionCategories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final active = _filter == cat;
          final count = cat == 'All'
              ? widget.players.length
              : widget.players.where((p) => catOf(p) == cat).length;
          final label = cat == 'All' ? 'All · $count' : cat;
          return Center(
            child: Material(
              color: active ? team.team : SidelineColors.surface,
              borderRadius: BorderRadius.circular(SidelineRadius.pill),
              child: InkWell(
                onTap: () => setState(() => _filter = cat),
                borderRadius: BorderRadius.circular(SidelineRadius.pill),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SidelineRadius.pill),
                    border: active
                        ? null
                        : Border.all(color: SidelineColors.hairline),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? team.onTeam : SidelineColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  final String? category;
  final int appearances;
  final AppDb db;

  const _PlayerRow({
    required this.player,
    required this.category,
    required this.appearances,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final team = teamColorsOf(context);
    final present = player.isPresent;
    final badge =
        player.jerseyNumber?.toString() ??
        (player.firstName.isNotEmpty
            ? player.firstName[0].toUpperCase()
            : '?');

    return Opacity(
      opacity: present ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: SidelineColors.surface,
          borderRadius: BorderRadius.circular(SidelineRadius.row),
          child: InkWell(
            onTap: () => context.push('/player/${player.id}/edit'),
            borderRadius: BorderRadius.circular(SidelineRadius.row),
            child: Container(
              padding: const EdgeInsets.fromLTRB(11, 11, 4, 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SidelineRadius.row),
                border: Border.all(color: SidelineColors.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: present ? team.team : SidelineColors.hairline,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style: sidelineMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: present ? team.onTeam : SidelineColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${player.firstName} ${player.lastName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: SidelineColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          present ? '$appearances appearances' : 'Inactive',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SidelineColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (category != null) ...[
                    const SizedBox(width: 8),
                    SidelinePositionChip(
                      label: category!,
                      isGoalkeeper: category == 'GK',
                    ),
                  ],
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: SidelineColors.muted,
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          context.push('/player/${player.id}/edit');
                          break;
                        case 'present':
                          await db
                              .update(db.players)
                              .replace(player.copyWith(isPresent: !present));
                          break;
                        case 'delete':
                          final ok = await _confirm(
                            context,
                            'Delete ${player.firstName} ${player.lastName}?',
                          );
                          if (ok) await db.deletePlayer(player.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'present',
                        child: Text(present ? 'Mark inactive' : 'Mark active'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
