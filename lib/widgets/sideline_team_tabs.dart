import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/sideline.dart';

/// The tab a team-management screen represents in the Roster / Formation /
/// Settings strip.
enum SidelineTeamTab { roster, formation, settings }

/// Roster / Formation / Settings tab strip shown directly under the branded
/// header on team-management screens. The active tab is an ink pill; the others
/// are hairline-outlined and navigate to their route on tap.
///
/// Each "tab" is a real route (`/team/:id/players`, `/formations`, `/edit`), so
/// this is a lightweight visual tab model over the existing navigation rather
/// than a restructure.
class SidelineTeamTabs extends StatelessWidget {
  final int teamId;
  final SidelineTeamTab current;

  const SidelineTeamTabs({
    super.key,
    required this.teamId,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _tab(context, 'Roster', SidelineTeamTab.roster, '/team/$teamId/players'),
          const SizedBox(width: 8),
          _tab(
            context,
            'Formation',
            SidelineTeamTab.formation,
            '/team/$teamId/formations',
          ),
          const SizedBox(width: 8),
          _tab(context, 'Settings', SidelineTeamTab.settings, '/team/$teamId/edit'),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    SidelineTeamTab tab,
    String route,
  ) {
    final active = tab == current;
    return Expanded(
      child: Material(
        color: active ? SidelineColors.ink : SidelineColors.surface,
        borderRadius: BorderRadius.circular(SidelineRadius.row),
        child: InkWell(
          onTap: active ? null : () => context.go(route),
          borderRadius: BorderRadius.circular(SidelineRadius.row),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SidelineRadius.row),
              border: active
                  ? null
                  : Border.all(color: SidelineColors.hairline),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : SidelineColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
