import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

/// Provider for the currently active season
final currentSeasonProvider = StreamProvider<Season?>((ref) {
  final db = ref.watch(dbProvider);
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
