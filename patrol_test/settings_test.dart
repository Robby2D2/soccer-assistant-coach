import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

/// Verifies the settings screen toggles persist alarm gates the right way.
/// Mirrors the production `AlarmSettingsNotifier` flow so a regression here
/// would mean the shift/halftime alarms can no longer be turned off.
///
/// The settings screen is a long `ListView` — the alarm toggles sit below the
/// "Current Configuration" summary and the notifications/permission section, so
/// each icon has to be scrolled into view before it can be found or tapped
/// (`find.byIcon` only matches widgets the lazy list has actually built).
void main() {
  patrolTest('shift and halftime alarm toggles persist across navigation', (
    PatrolIntegrationTester $,
  ) async {
    await initApp();

    // Clear alarm_settings from SharedPreferences so the test starts from the
    // default state (shiftsEnabled=true → Icons.alarm visible). If a previous
    // run crashed before reaching the restore step at the end of this test,
    // it could leave shiftsEnabled=false in prefs, in which case the screen
    // shows Icons.alarm_off and the first `expect($(Icons.alarm))` fails.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await $.pumpWidget(appUnderTest());
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    await $(find.byIcon(Icons.settings)).first.tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    // Shift alarms toggle (icon flips from `Icons.alarm` to `Icons.alarm_off`).
    await $(Icons.alarm).scrollTo();
    expect($(Icons.alarm), findsOneWidget);
    await $(Icons.alarm).tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 3));
    expect(
      $(Icons.alarm_off),
      findsOneWidget,
      reason: 'Disabling shift alarms should swap to the disabled icon',
    );

    // Halftime alarms toggle (icon flips between `Icons.timer` and
    // `Icons.timer_off`). `Icons.timer` also appears on the Duration control
    // further down the list, so target the first match — the toggle, which
    // comes before the duration row.
    await $(Icons.timer).first.scrollTo();
    await $(Icons.timer).first.tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 3));
    expect($(Icons.timer_off), findsOneWidget);

    // Navigate back home and re-enter settings — the toggles should still
    // reflect the disabled state because they're persisted.
    await $.tap(find.byTooltip('Back'));
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));
    await $(find.byIcon(Icons.settings)).first.tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    await $(Icons.alarm_off).scrollTo();
    expect($(Icons.alarm_off), findsOneWidget);
    await $(Icons.timer_off).scrollTo();
    expect($(Icons.timer_off), findsOneWidget);

    // Restore for next test run so SharedPreferences doesn't poison the suite.
    await $(Icons.alarm_off).tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 3));
    await $(Icons.timer_off).tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 3));
  });
}
