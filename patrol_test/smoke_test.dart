import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/features/home/home_screen.dart';

import 'helpers/app_harness.dart';

/// Boot smoke test — verifies the app launches, the home screen renders, and
/// the user can open Settings without crashing.
///
/// Run on a connected Android emulator or iOS simulator with:
///   patrol test -t integration_test/smoke_test.dart
void main() {
  patrolTest('app launches and navigates to settings', (
    PatrolIntegrationTester $,
  ) async {
    await initApp();
    await $.pumpWidget(appUnderTest());
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    expect($(HomeScreen), findsOneWidget);

    // Open the settings screen via the AppBar gear icon. The home screen's
    // first settings IconButton lives on the AppBar (a second one is hidden
    // inside the overflow menu).
    await $(find.byIcon(Icons.settings)).first.tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    // The settings screen surfaces the configuration summary card.
    expect($('Current Configuration'), findsOneWidget);
  });
}
