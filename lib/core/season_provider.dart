import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

/// Determine season name (Winter, Spring, Summer, Fall) for a given date
String _seasonNameForDate(DateTime d) {
  final m = d.month;
  if (m == 12 || m == 1 || m == 2) return 'Winter';
  if (m >= 3 && m <= 5) return 'Spring';
  if (m >= 6 && m <= 8) return 'Summer';
  return 'Fall';
}

/// Ensures an active season exists; if not, creates one named like "Fall 2025".
Future<void> _ensureActiveSeason(AppDb db) async {
  try {
    final active = await db.getActiveSeason();
    if (active == null) {
      final now = DateTime.now();
      final seasonName = '${_seasonNameForDate(now)} ${now.year}';
      // Use the first day of the current month as a reasonable start date
      final startDate = DateTime(now.year, now.month, 1);
      await db.createSeason(name: seasonName, startDate: startDate, isActive: true);
    }
  } catch (e) {
    // Fail silently - provider consumers will handle a null season if creation fails
    // but log for debugging
    // ignore: avoid_print
    print('Warning: could not ensure active season: $e');
  }
}

/// Provider for the currently active season
final currentSeasonProvider = StreamProvider<Season?>((ref) {
  final db = ref.watch(dbProvider);

  // Kick off an async ensure in the background so that if no season exists
  // we create one (first launch case). We intentionally don't await it here
  // to avoid delaying the provider stream subscription.
  // Launch ensure in the background without awaiting to avoid blocking
  Future.microtask(() => _ensureActiveSeason(db));

  return db.watchActiveSeason();
});

/// Provider that returns the current season ID, or null if no active season
final currentSeasonIdProvider = StreamProvider<int?>((ref) async* {
  final db = ref.watch(dbProvider);
  await for (final season in db.watchActiveSeason()) {
    yield season?.id;
  }
});

/// Provider for all seasons (excluding archived by default)
final seasonsProvider = StreamProvider.family<List<Season>, bool>((
  ref,
  includeArchived,
) {
  final db = ref.watch(dbProvider);
  return db.watchSeasons(includeArchived: includeArchived);
});

/// Season-aware teams provider
final seasonTeamsProvider = StreamProvider.family<List<Team>, int?>((
  ref,
  seasonId,
) {
  final db = ref.watch(dbProvider);
  return db.watchTeams(seasonId: seasonId);
});

// Note: For teams list, we'll use currentSeasonProvider directly in the widget
// with StreamBuilder like the home screen does, since chaining StreamProviders
// is complex. The teams screen will watch currentSeasonProvider and use
// db.watchTeams(seasonId: season.id) directly.
