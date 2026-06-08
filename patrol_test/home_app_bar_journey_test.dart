import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:soccer_assistant_coach/data/db/database.dart';

import 'helpers/app_harness.dart';
import 'helpers/screenshot.dart';

/// Journey test — home screen app bar consistency fix (issue #33).
///
/// Verifies that the home screen now uses the shared [StandardizedAppBarActions]
/// pattern: a Settings icon in the toolbar plus a kebab menu that includes
/// Settings, Manage Seasons, and Database Diagnostics.
void main() {
  patrolTest(
    'home screen app bar has settings icon and full kebab menu',
    (PatrolIntegrationTester $) async {
      await initApp();

      final db = AppDb.test();
      addTearDown(db.close);

      await $.pumpWidget(appUnderTest(db: db));
      await $.pumpAndSettle(timeout: const Duration(seconds: 5));

      // Settings icon is visible in the toolbar as a dedicated icon button.
      expect(find.byTooltip('Settings'), findsOneWidget);

      // The kebab menu icon is present (more_vert).
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Capture the home screen showing the standardized app bar.
      await captureScreenshot($, 'home-app-bar');

      // Open the kebab menu.
      await $(find.byIcon(Icons.more_vert)).tap();
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));

      // All three destinations appear in the popup menu.
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Manage Seasons'), findsOneWidget);
      expect(find.text('Database Diagnostics'), findsOneWidget);

      // Capture the open kebab menu.
      await captureScreenshot($, 'home-app-bar-menu');
    },
  );
}
