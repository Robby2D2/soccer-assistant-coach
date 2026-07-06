/// Win/loss/draw record and goals for/against across a team's completed games.
class TeamRecord {
  final int wins;
  final int losses;
  final int draws;
  final int goalsFor;
  final int goalsAgainst;

  const TeamRecord({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get gamesPlayed => wins + losses + draws;

  /// e.g. "4-1-2" (W-L-D).
  String get recordLabel => '$wins-$losses-$draws';

  /// e.g. "18/9" (GF/GA).
  String get goalDifferenceLabel => '$goalsFor/$goalsAgainst';
}

/// Aggregated metrics for a player across all games for a team
class PlayerTeamMetrics {
  final int playerId;
  final String firstName;
  final String lastName;
  final int? jerseyNumber;
  final String? profileImagePath;
  final int totalGoals;
  final int totalAssists;
  final int totalSaves;
  final int totalPlayTimeSeconds;
  final int gamesPlayed;

  const PlayerTeamMetrics({
    required this.playerId,
    required this.firstName,
    required this.lastName,
    this.jerseyNumber,
    this.profileImagePath,
    required this.totalGoals,
    required this.totalAssists,
    required this.totalSaves,
    required this.totalPlayTimeSeconds,
    required this.gamesPlayed,
  });

  int get totalMetrics => totalGoals + totalAssists + totalSaves;

  double get averagePlayTimeMinutesPerGame =>
      gamesPlayed > 0 ? (totalPlayTimeSeconds / 60.0) / gamesPlayed : 0.0;

  double get totalPlayTimeMinutes => totalPlayTimeSeconds / 60.0;
}

/// Team-level aggregated metrics summary
class TeamMetricsSummary {
  final int teamId;
  final String teamName;
  final int totalGames;
  final int totalGoals;
  final int totalAssists;
  final int totalSaves;
  final int totalPlayTimeSeconds;
  final List<PlayerTeamMetrics> playerMetrics;

  const TeamMetricsSummary({
    required this.teamId,
    required this.teamName,
    required this.totalGames,
    required this.totalGoals,
    required this.totalAssists,
    required this.totalSaves,
    required this.totalPlayTimeSeconds,
    required this.playerMetrics,
  });

  int get totalMetrics => totalGoals + totalAssists + totalSaves;

  double get totalPlayTimeMinutes => totalPlayTimeSeconds / 60.0;

  double get averageGoalsPerGame =>
      totalGames > 0 ? totalGoals / totalGames : 0.0;
  double get averageAssistsPerGame =>
      totalGames > 0 ? totalAssists / totalGames : 0.0;
  double get averageSavesPerGame =>
      totalGames > 0 ? totalSaves / totalGames : 0.0;
}
