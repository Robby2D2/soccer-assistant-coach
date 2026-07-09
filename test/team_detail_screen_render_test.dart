// Regression test for issue #39: the game-first team landing screen
// (/team/:id) failed layout on every frame because _gameCard's
// Row(crossAxisAlignment: stretch) sat in a SingleChildScrollView (unbounded
// height), throwing "RenderBox was not laid out" per frame. That blanked the
// whole body in production and kept pumpAndSettle from ever settling, hanging
// the patrol journeys that navigate into this screen.
//
// This is the widget-tier guard the patrol gate shouldn't be needed for:
// pumping the real TeamDetailScreen here surfaces any per-frame layout
// exception immediately in `flutter test`.
//
// NB: the screen holds always-open Drift streams, so all DB work and waits go
// through tester.runAsync (real async) and frames through plain pump() — never
// pumpAndSettle, which cannot settle an open stream under FakeAsync.
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soccer_assistant_coach/core/providers.dart';
import 'package:soccer_assistant_coach/features/teams/team_detail_screen.dart';
import 'package:soccer_assistant_coach/l10n/app_localizations.dart';

Widget _testApp(AppDb db, int teamId) {
  return ProviderScope(
    overrides: [dbProvider.overrideWithValue(db)],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: TeamDetailScreen(id: teamId),
    ),
  );
}

void main() {
  testWidgets(
    'TeamDetailScreen renders both game cards without layout exceptions',
    timeout: const Timeout(Duration(minutes: 2)),
    (tester) async {
      final db = AppDb.test();

      // Seed inside runAsync: Drift's executor completes on real async.
      final teamId = await tester.runAsync(() async {
        final seasonId = await db.createSeason(
          name: 'Landing Season',
          startDate: DateTime.now(),
        );
        final teamId = await db.addTeamToSeason(
          seasonId: seasonId,
          name: 'Landing FC',
        );

        // A completed game — exercises the recent-game card (the accent-bar
        // _gameCard path that regressed).
        await db.addGame(
          GamesCompanion.insert(
            teamId: teamId,
            seasonId: seasonId,
            opponent: const drift.Value('Riverside'),
            gameStatus: const drift.Value('completed'),
            startTime: drift.Value(DateTime(2026, 5, 1)),
            teamScore: const drift.Value(3),
            opponentScore: const drift.Value(2),
          ),
        );

        // An upcoming game — exercises the next-game card variant too.
        await db.addGame(
          GamesCompanion.insert(
            teamId: teamId,
            seasonId: seasonId,
            opponent: const drift.Value('Lakeside'),
            gameStatus: const drift.Value('scheduled'),
            startTime: drift.Value(DateTime.now().add(const Duration(days: 3))),
          ),
        );
        return teamId;
      });

      await tester.pumpWidget(_testApp(db, teamId!));
      // Let the theme future and both game streams deliver on real async, then
      // pump a frame so the delivered data renders.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      await tester.pump();

      // The regression threw "RenderBox was not laid out ... !hasSize" during
      // layout on every frame; any such exception must fail this test.
      expect(tester.takeException(), isNull);

      // The game-first content actually painted (the bug blanked the body).
      expect(find.text('Most Recent Game'), findsOneWidget);
      expect(find.text('Next Game'), findsOneWidget);
      expect(find.text('3–2'), findsOneWidget);
      expect(find.text('vs Riverside'), findsOneWidget);
      expect(find.text('Create New Game'), findsOneWidget);

      // Dispose the screen (closing its stream subscriptions) before closing
      // the DB, so no Drift stream write can deadlock the close.
      await tester.pumpWidget(const SizedBox.shrink());
      // Elapse fake time: drift schedules a Timer.run when a stream loses its
      // last subscriber (stream-cache grace period), and db.close() awaits it.
      // A duration-less pump() doesn't fire zero-timers under FakeAsync, so
      // close() would deadlock without this.
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    },
  );
}
