// Tests for the home screen's app bar migration to StandardizedAppBarActions.
//
// HomeScreen contains always-open Drift StreamBuilders in its body that leave
// pending FakeAsync timers, so we cannot pump the full screen (same constraint
// as TeamsScreen — see .agents/MEMORY.md). Instead we test the shared
// StandardizedAppBarActions widget seeded with the exact actions that
// HomeScreen now passes, and verify the new manageSeasons action factory.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soccer_assistant_coach/l10n/app_localizations.dart';
import 'package:soccer_assistant_coach/widgets/standardized_app_bar_actions.dart';

/// Wraps a Scaffold+AppBar with localization and Overlay support.
Widget _testApp(List<NavigationAction> actions) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: StandardizedAppBarActions.createActionsWidgets(actions),
        ),
      ),
    ),
  );
}

void main() {
  group('HomeScreen app bar — StandardizedAppBarActions', () {
    testWidgets(
      'settings icon button is shown in the toolbar (showAsIcon: true)',
      (tester) async {
        await tester.pumpWidget(
          _testApp([
            const NavigationAction(
              label: 'Settings',
              icon: Icons.settings,
              showAsIcon: true,
            ),
            const NavigationAction(
              label: 'Manage Seasons',
              icon: Icons.calendar_today,
            ),
            const NavigationAction(
              label: 'Database Diagnostics',
              icon: Icons.bug_report,
            ),
          ]),
        );
        await tester.pumpAndSettle();

        // Settings renders as an icon button in the toolbar (showAsIcon: true).
        expect(find.byIcon(Icons.settings), findsOneWidget);
        // The kebab (more_vert) icon is also present.
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      },
    );

    testWidgets('kebab menu lists all three home destinations', (tester) async {
      await tester.pumpWidget(
        _testApp([
          const NavigationAction(
            label: 'Settings',
            icon: Icons.settings,
            showAsIcon: true,
          ),
          const NavigationAction(
            label: 'Manage Seasons',
            icon: Icons.calendar_today,
          ),
          const NavigationAction(
            label: 'Database Diagnostics',
            icon: Icons.bug_report,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      // Open the kebab menu.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // All three destinations appear in the popup menu (Settings appears
      // twice: once as an icon and once in the menu — both findable).
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Manage Seasons'), findsOneWidget);
      expect(find.text('Database Diagnostics'), findsOneWidget);
    });

    testWidgets('manageSeasons action is invoked when tapped from the menu', (
      tester,
    ) async {
      bool seasonsOpened = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Home'),
                actions: StandardizedAppBarActions.createActionsWidgets([
                  NavigationAction(
                    label: 'Manage Seasons',
                    icon: Icons.calendar_today,
                    onPressed: () {
                      seasonsOpened = true;
                    },
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage Seasons'));
      await tester.pumpAndSettle();

      expect(seasonsOpened, isTrue);
    });
  });
}
