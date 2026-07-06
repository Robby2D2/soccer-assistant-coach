import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/team_theme_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/sideline_header.dart';
import '../../core/positions.dart';
import '../../core/sideline.dart';
import '../../widgets/sideline_team_tabs.dart';
import '../../widgets/sideline_widgets.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class TeamFormationsScreen extends ConsumerWidget {
  final int teamId;
  const TeamFormationsScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final loc = AppLocalizations.of(context);
    return TeamScaffold(
      teamId: teamId,
      header: SidelineScreenHeader(
        teamId: teamId,
        subtitle: loc.formations,
        actions: StandardizedAppBarActions.createActionsWidgets([
          CommonNavigationActions.home(context),
        ]),
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
                onPressed: () => context.push('/team/$teamId/formations/new'),
                icon: const Icon(Icons.add),
                label: const Text('Add formation'),
                style: FilledButton.styleFrom(
                  backgroundColor: SidelineColors.ink,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SidelineTeamTabs(
            teamId: teamId,
            current: SidelineTeamTab.formation,
          ),
          Expanded(
            child: StreamBuilder<List<Formation>>(
              stream: db.watchTeamFormations(teamId),
        builder: (context, snapshot) {
          final formations = snapshot.data ?? const <Formation>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              formations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (formations.isEmpty) {
            return _buildEmptyState(context);
          }
          return _FormationPicker(
            formations: formations,
            teamId: teamId,
            db: db,
          );
        },
            ),
          ),
        ],
      ),
    );
  }

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
                Icons.grid_view_rounded,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noFormationsYet,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              loc.noFormationsYetDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () =>
                  GoRouter.of(context).push('/team/$teamId/formations/new'),
              icon: const Icon(Icons.add),
              label: Text(loc.createFormation),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formation picker + pitch preview: chips select a saved formation, and the
/// dark pitch below lays its positions out by category (GK at the top,
/// forwards at the bottom).
class _FormationPicker extends StatefulWidget {
  final List<Formation> formations;
  final int teamId;
  final AppDb db;

  const _FormationPicker({
    required this.formations,
    required this.teamId,
    required this.db,
  });

  @override
  State<_FormationPicker> createState() => _FormationPickerState();
}

class _FormationPickerState extends State<_FormationPicker> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.formations.isNotEmpty
        ? widget.formations.first.id
        : null;
  }

  @override
  void didUpdateWidget(covariant _FormationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedId == null ||
        !widget.formations.any((f) => f.id == _selectedId)) {
      _selectedId = widget.formations.isNotEmpty
          ? widget.formations.first.id
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Current setup',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: SidelineColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final f in widget.formations) _chip(f)],
        ),
        const SizedBox(height: 16),
        if (_selectedId != null)
          FutureBuilder<List<FormationPosition>>(
            future: widget.db.getFormationPositions(_selectedId!),
            builder: (context, snap) {
              return _FormationField(
                positions: snap.data ?? const <FormationPosition>[],
              );
            },
          ),
        const SizedBox(height: 12),
        if (_selectedId != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/team/${widget.teamId}/formations/$_selectedId/edit',
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _chip(Formation f) {
    final team = teamColorsOf(context);
    final active = f.id == _selectedId;
    return Material(
      color: active ? team.team : SidelineColors.surface,
      borderRadius: BorderRadius.circular(SidelineRadius.row),
      child: InkWell(
        onTap: () => setState(() => _selectedId = f.id),
        borderRadius: BorderRadius.circular(SidelineRadius.row),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SidelineRadius.row),
            border: active ? null : Border.all(color: SidelineColors.hairline),
          ),
          child: Text(
            f.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? team.onTeam : SidelineColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final id = _selectedId;
    if (id == null) return;
    final loc = AppLocalizations.of(context);
    final f = widget.formations.firstWhere((x) => x.id == id);
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(loc.deleteFormationTitle),
            content: Text(loc.deleteFormationMessage(f.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(loc.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    await widget.db.deleteFormation(id);
  }
}

/// A dark pitch showing a formation's positions as team-colored badges, laid
/// out in category rows (GK at the top, forwards at the bottom).
class _FormationField extends StatelessWidget {
  final List<FormationPosition> positions;
  const _FormationField({required this.positions});

  @override
  Widget build(BuildContext context) {
    final team = teamColorsOf(context);
    final byCat = <String, List<FormationPosition>>{};
    for (final p in positions) {
      byCat.putIfAbsent(positionCategory(p.positionName), () => []).add(p);
    }
    final rows = kPositionCategories
        .where((c) => byCat[c]?.isNotEmpty ?? false)
        .toList();

    return AspectRatio(
      aspectRatio: 0.74,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SidelineColors.ink,
          borderRadius: BorderRadius.circular(SidelineRadius.card),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
            if (rows.isEmpty)
              const Center(
                child: Text(
                  'No positions in this formation',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                child: Column(
                  children: [
                    for (final cat in rows)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final p in byCat[cat]!)
                              _PositionBadge(
                                label: p.abbreviation.isNotEmpty
                                    ? p.abbreviation
                                    : cat,
                                badgeColor: team.team,
                                textColor: team.onTeam,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final String label;
  final Color badgeColor;
  final Color textColor;
  const _PositionBadge({
    required this.label,
    required this.badgeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Subtle white pitch markings for the dark formation field.
class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const inset = 10.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      paint,
    );
    canvas.drawLine(
      Offset(inset, size.height / 2),
      Offset(size.width - inset, size.height / 2),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.13,
      paint,
    );
    final boxW = size.width * 0.46;
    final boxH = size.height * 0.13;
    canvas.drawRect(
      Rect.fromLTWH((size.width - boxW) / 2, inset, boxW, boxH),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - boxW) / 2,
        size.height - inset - boxH,
        boxW,
        boxH,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
