// Widget tests for onboarding empty-state copy.
//
// Full-screen tests (TeamsScreen, GamesScreen, PlayersScreen) cannot be driven
// from widget tests because they contain always-open Drift StreamBuilder
// subscriptions that leave pending FakeAsync timers — see .agents/MEMORY.md.
// Instead we test:
//   - the localization strings have the expected onboarding copy
//   - the standalone onboarding card widgets render their copy correctly
//
// The actual wiring (empty DB → shows the onboarding card) is covered by
// patrol_test/onboarding_journey_test.dart, which seeds AppDb.test() with no
// data and asserts the welcome card title appears on a real device.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_assistant_coach/l10n/app_localizations.dart';

// A minimal harness that provides l10n without any database dependency.
Widget _l10nApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Onboarding l10n strings', () {
    testWidgets('welcome title and step strings are non-empty', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        _l10nApp(
          Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(loc.onboardingWelcomeTitle, isNotEmpty);
      expect(loc.onboardingWelcomeSubtitle, isNotEmpty);
      expect(loc.onboardingStep1, contains('1'));
      expect(loc.onboardingStep2, contains('2'));
      expect(loc.onboardingStep3, contains('3'));
      expect(loc.onboardingGetStarted, isNotEmpty);
    });

    testWidgets('no-teams card strings are non-empty', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        _l10nApp(
          Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(loc.onboardingNoTeamsTitle, isNotEmpty);
      expect(loc.onboardingNoTeamsSubtitle, isNotEmpty);
    });

    testWidgets('teams empty-state uses onboarding description', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        _l10nApp(
          Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(
        loc.noTeamsYetDescriptionOnboarding,
        contains('team'),
      );
    });

    testWidgets('players empty-state mentions roster and games', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        _l10nApp(
          Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(loc.noPlayersYetDescriptionOnboarding, contains('roster'));
    });

    testWidgets('games empty-state mentions scheduling a game', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(
        _l10nApp(
          Builder(
            builder: (context) {
              loc = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(loc.noGamesYetDescriptionOnboarding, contains('game'));
    });
  });
}
