import 'package:drift/drift.dart';

class Teams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get teamMode =>
      text().withDefault(const Constant('shift'))(); // 'shift' or 'traditional'
  IntColumn get halfDurationSeconds =>
      integer().withDefault(const Constant(1200))(); // 20 minutes default
  IntColumn get shiftLengthSeconds => integer().withDefault(
    const Constant(300),
  )(); // 5 minutes default for shifts
  TextColumn get logoImagePath =>
      text().nullable()(); // Path to team logo image
  TextColumn get primaryColor1 =>
      text().nullable()(); // First primary color (hex)
  TextColumn get primaryColor2 =>
      text().nullable()(); // Second primary color (hex)
  TextColumn get primaryColor3 =>
      text().nullable()(); // Third primary color (hex)
}

class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teamId => integer().references(Teams, #id)();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  BoolColumn get isPresent => boolean().withDefault(const Constant(true))();
  IntColumn get jerseyNumber => integer().nullable()();
  TextColumn get profileImagePath => text().nullable()();
}

class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startTime => dateTime().nullable()();
  TextColumn get opponent => text().nullable()();
  IntColumn get currentShiftId => integer().nullable()();
  IntColumn get teamId => integer().references(Teams, #id)();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get currentHalf =>
      integer().withDefault(const Constant(1))(); // 1 or 2
  IntColumn get gameTimeSeconds => integer().withDefault(
    const Constant(0),
  )(); // Total game time for traditional mode
  BoolColumn get isGameActive =>
      boolean().withDefault(const Constant(false))(); // Is game timer running
  DateTimeColumn get timerStartTime => dateTime()
      .nullable()(); // When timer was started for background persistence
  IntColumn get formationId => integer().nullable().references(
    Formations,
    #id,
  )(); // Selected formation for the game

  // Game completion and scoring
  TextColumn get gameStatus => text().withDefault(
    const Constant('in-progress'),
  )(); // 'in-progress', 'completed', 'cancelled'
  DateTimeColumn get endTime =>
      dateTime().nullable()(); // When game was completed
  IntColumn get teamScore => integer().withDefault(const Constant(0))();
  IntColumn get opponentScore => integer().withDefault(const Constant(0))();
}

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId => integer().references(Games, #id)();
  IntColumn get startSeconds => integer()();
  IntColumn get endSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get actualSeconds => integer().withDefault(const Constant(0))();
}

class PlayerShifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shiftId => integer().references(Shifts, #id)();
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get position => text()();
}

class PlayerMetrics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer().references(Players, #id)();
  IntColumn get gameId => integer().references(Games, #id)();
  TextColumn get metric => text()();
  IntColumn get value => integer().withDefault(const Constant(0))();
}

class PlayerPositionTotals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get position => text()();
  IntColumn get totalSeconds => integer().withDefault(const Constant(0))();
}

/// NEW: per-game attendance
class GamePlayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId => integer().references(Games, #id)();
  IntColumn get playerId => integer().references(Players, #id)();
  BoolColumn get isPresent => boolean().withDefault(const Constant(true))();
}

/// Formations are team-level templates describing positions by name.
class Formations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teamId => integer().references(Teams, #id)();
  TextColumn get name => text()();
  IntColumn get playerCount => integer()();
}

/// Positions for a formation, ordered by `index`.
class FormationPositions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get formationId => integer().references(Formations, #id)();
  IntColumn get index => integer()();
  TextColumn get positionName => text()();
  TextColumn get abbreviation => text().withDefault(const Constant(''))();
}

/// Traditional game lineups (separate from shifts-based lineups)
class TraditionalLineups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId => integer().references(Games, #id)();
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get position => text()();
}
