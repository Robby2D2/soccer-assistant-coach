import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';

/// End-to-end onboarding journey.
///
/// Verifies that a brand-new install with zero data shows the contextual
/// empty-state guidance rather than a blank screen.
///
/// Because [season_provider.dart] auto-creates an active season on first
/// launch via [_ensureActiveSeason] (a microtask fired from
/// [currentSeasonProvider]), the home screen reliably settles in the
/// "has season but no teams" state when the DB is empty — showing the
/// [_OnboardingNoTeamsCard].
void main() {
  patrolTest(
    'empty DB shows onboarding no-teams card on home screen',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      // No seed data — DB is completely empty.

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // After settling, _ensureActiveSeason has auto-created a season but no
      // teams exist, so the home screen shows _OnboardingNoTeamsCard.
      expect(
        $("You're almost ready!"),
        findsOneWidget,
        reason:
            'Home screen should show the onboarding no-teams card when DB has no teams',
      );

      // DB-side confirmation: no teams were created (only the auto-season).
      final teams = await db.getAllTeams();
      expect(
        teams,
        isEmpty,
        reason: 'DB should have zero teams for this onboarding state to show',
      );
    },
  );
}
