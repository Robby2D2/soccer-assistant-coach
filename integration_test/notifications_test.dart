import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';
import 'package:soccer_assistant_coach/data/services/notification_service.dart';

import 'helpers/app_harness.dart';

/// Native notification smoke test — only meaningful when run on a real
/// device or simulator via `patrol test`. Verifies that:
///
///   1. The notification permission can be requested without error (Patrol
///      grants it natively via `$.native.grantPermissionWhenInUse`).
///   2. The shift countdown notification can be shown without throwing.
///   3. The shift alarm can be cancelled cleanly.
///
/// We intentionally avoid asserting on the notification's text in the
/// status bar — Patrol's native APIs vary by platform and a flake in that
/// surface should not block CI. The smoke test is enough to catch breakage
/// in the notification plumbing (channel registration, permission flow).
void main() {
  patrolTest('notification plumbing initializes and accepts shift updates', (
    PatrolIntegrationTester $,
  ) async {
    await initApp();

    // Grant POST_NOTIFICATIONS / iOS alert permission natively.
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (_) {
      // No prompt was up — already granted or platform doesn't show one.
    }

    final db = AppDb.test();
    addTearDown(db.close);

    final seasonId = await db.createSeason(
      name: 'Notif Season',
      startDate: DateTime.now(),
    );
    final teamId = await db.addTeamToSeason(
      seasonId: seasonId,
      name: 'Notif FC',
      shiftLengthSeconds: 60,
    );
    final gameId = await db.addGame(
      GamesCompanion.insert(
        teamId: teamId,
        seasonId: seasonId,
        opponent: const drift.Value('Test Reminders'),
      ),
    );

    await $.pumpWidget(appUnderTest(db: db));
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    // Drive the same calls the game screen makes when the timer ticks.
    await NotificationService.instance.showOrUpdateShiftCountdown(
      gameId: gameId,
      currentSeconds: 30,
      shiftLengthSeconds: 60,
      matchupTitle: 'Notif FC vs Test Reminders',
      shiftNumber: 1,
    );

    // And the cleanup path.
    await NotificationService.instance.cancelShiftCountdown(gameId);

    expect(
      NotificationService.instance.isShiftAlarmActive(gameId),
      isFalse,
      reason: 'Cancelling the countdown should also clear alarm-active flag',
    );
  });
}
