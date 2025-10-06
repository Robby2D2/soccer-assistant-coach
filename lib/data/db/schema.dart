import 'package:drift/drift.dart';

class Teams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teamId => integer().references(Teams, #id)();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  BoolColumn get isPresent => boolean().withDefault(const Constant(true))();
}

class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startTime => dateTime().nullable()();
  TextColumn get opponent => text().nullable()();
  IntColumn get currentShiftId => integer().nullable()();
  IntColumn get teamId => integer().references(Teams, #id)();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
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
}
