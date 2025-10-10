// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TeamsTable extends Teams with TableInfo<$TeamsTable, Team> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _teamModeMeta = const VerificationMeta(
    'teamMode',
  );
  @override
  late final GeneratedColumn<String> teamMode = GeneratedColumn<String>(
    'team_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('shift'),
  );
  static const VerificationMeta _halfDurationSecondsMeta =
      const VerificationMeta('halfDurationSeconds');
  @override
  late final GeneratedColumn<int> halfDurationSeconds = GeneratedColumn<int>(
    'half_duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1200),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isArchived,
    teamMode,
    halfDurationSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<Team> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('team_mode')) {
      context.handle(
        _teamModeMeta,
        teamMode.isAcceptableOrUnknown(data['team_mode']!, _teamModeMeta),
      );
    }
    if (data.containsKey('half_duration_seconds')) {
      context.handle(
        _halfDurationSecondsMeta,
        halfDurationSeconds.isAcceptableOrUnknown(
          data['half_duration_seconds']!,
          _halfDurationSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Team map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Team(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      teamMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_mode'],
      )!,
      halfDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}half_duration_seconds'],
      )!,
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class Team extends DataClass implements Insertable<Team> {
  final int id;
  final String name;
  final bool isArchived;
  final String teamMode;
  final int halfDurationSeconds;
  const Team({
    required this.id,
    required this.name,
    required this.isArchived,
    required this.teamMode,
    required this.halfDurationSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_archived'] = Variable<bool>(isArchived);
    map['team_mode'] = Variable<String>(teamMode);
    map['half_duration_seconds'] = Variable<int>(halfDurationSeconds);
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      name: Value(name),
      isArchived: Value(isArchived),
      teamMode: Value(teamMode),
      halfDurationSeconds: Value(halfDurationSeconds),
    );
  }

  factory Team.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Team(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      teamMode: serializer.fromJson<String>(json['teamMode']),
      halfDurationSeconds: serializer.fromJson<int>(
        json['halfDurationSeconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isArchived': serializer.toJson<bool>(isArchived),
      'teamMode': serializer.toJson<String>(teamMode),
      'halfDurationSeconds': serializer.toJson<int>(halfDurationSeconds),
    };
  }

  Team copyWith({
    int? id,
    String? name,
    bool? isArchived,
    String? teamMode,
    int? halfDurationSeconds,
  }) => Team(
    id: id ?? this.id,
    name: name ?? this.name,
    isArchived: isArchived ?? this.isArchived,
    teamMode: teamMode ?? this.teamMode,
    halfDurationSeconds: halfDurationSeconds ?? this.halfDurationSeconds,
  );
  Team copyWithCompanion(TeamsCompanion data) {
    return Team(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      teamMode: data.teamMode.present ? data.teamMode.value : this.teamMode,
      halfDurationSeconds: data.halfDurationSeconds.present
          ? data.halfDurationSeconds.value
          : this.halfDurationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Team(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('teamMode: $teamMode, ')
          ..write('halfDurationSeconds: $halfDurationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, isArchived, teamMode, halfDurationSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Team &&
          other.id == this.id &&
          other.name == this.name &&
          other.isArchived == this.isArchived &&
          other.teamMode == this.teamMode &&
          other.halfDurationSeconds == this.halfDurationSeconds);
}

class TeamsCompanion extends UpdateCompanion<Team> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isArchived;
  final Value<String> teamMode;
  final Value<int> halfDurationSeconds;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.teamMode = const Value.absent(),
    this.halfDurationSeconds = const Value.absent(),
  });
  TeamsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isArchived = const Value.absent(),
    this.teamMode = const Value.absent(),
    this.halfDurationSeconds = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Team> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isArchived,
    Expression<String>? teamMode,
    Expression<int>? halfDurationSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isArchived != null) 'is_archived': isArchived,
      if (teamMode != null) 'team_mode': teamMode,
      if (halfDurationSeconds != null)
        'half_duration_seconds': halfDurationSeconds,
    });
  }

  TeamsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isArchived,
    Value<String>? teamMode,
    Value<int>? halfDurationSeconds,
  }) {
    return TeamsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      teamMode: teamMode ?? this.teamMode,
      halfDurationSeconds: halfDurationSeconds ?? this.halfDurationSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (teamMode.present) {
      map['team_mode'] = Variable<String>(teamMode.value);
    }
    if (halfDurationSeconds.present) {
      map['half_duration_seconds'] = Variable<int>(halfDurationSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isArchived: $isArchived, ')
          ..write('teamMode: $teamMode, ')
          ..write('halfDurationSeconds: $halfDurationSeconds')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id)',
    ),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPresentMeta = const VerificationMeta(
    'isPresent',
  );
  @override
  late final GeneratedColumn<bool> isPresent = GeneratedColumn<bool>(
    'is_present',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_present" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    firstName,
    lastName,
    isPresent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('is_present')) {
      context.handle(
        _isPresentMeta,
        isPresent.isAcceptableOrUnknown(data['is_present']!, _isPresentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      isPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_present'],
      )!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final int id;
  final int teamId;
  final String firstName;
  final String lastName;
  final bool isPresent;
  const Player({
    required this.id,
    required this.teamId,
    required this.firstName,
    required this.lastName,
    required this.isPresent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['team_id'] = Variable<int>(teamId);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['is_present'] = Variable<bool>(isPresent);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      teamId: Value(teamId),
      firstName: Value(firstName),
      lastName: Value(lastName),
      isPresent: Value(isPresent),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<int>(json['id']),
      teamId: serializer.fromJson<int>(json['teamId']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      isPresent: serializer.fromJson<bool>(json['isPresent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'teamId': serializer.toJson<int>(teamId),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'isPresent': serializer.toJson<bool>(isPresent),
    };
  }

  Player copyWith({
    int? id,
    int? teamId,
    String? firstName,
    String? lastName,
    bool? isPresent,
  }) => Player(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    isPresent: isPresent ?? this.isPresent,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      isPresent: data.isPresent.present ? data.isPresent.value : this.isPresent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('isPresent: $isPresent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, teamId, firstName, lastName, isPresent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.isPresent == this.isPresent);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<int> id;
  final Value<int> teamId;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<bool> isPresent;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.isPresent = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required int teamId,
    required String firstName,
    required String lastName,
    this.isPresent = const Value.absent(),
  }) : teamId = Value(teamId),
       firstName = Value(firstName),
       lastName = Value(lastName);
  static Insertable<Player> custom({
    Expression<int>? id,
    Expression<int>? teamId,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<bool>? isPresent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (isPresent != null) 'is_present': isPresent,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<int>? teamId,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<bool>? isPresent,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isPresent: isPresent ?? this.isPresent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (isPresent.present) {
      map['is_present'] = Variable<bool>(isPresent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('isPresent: $isPresent')
          ..write(')'))
        .toString();
  }
}

class $FormationsTable extends Formations
    with TableInfo<$FormationsTable, Formation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerCountMeta = const VerificationMeta(
    'playerCount',
  );
  @override
  late final GeneratedColumn<int> playerCount = GeneratedColumn<int>(
    'player_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, teamId, name, playerCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'formations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Formation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('player_count')) {
      context.handle(
        _playerCountMeta,
        playerCount.isAcceptableOrUnknown(
          data['player_count']!,
          _playerCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Formation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Formation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      playerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_count'],
      )!,
    );
  }

  @override
  $FormationsTable createAlias(String alias) {
    return $FormationsTable(attachedDatabase, alias);
  }
}

class Formation extends DataClass implements Insertable<Formation> {
  final int id;
  final int teamId;
  final String name;
  final int playerCount;
  const Formation({
    required this.id,
    required this.teamId,
    required this.name,
    required this.playerCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['team_id'] = Variable<int>(teamId);
    map['name'] = Variable<String>(name);
    map['player_count'] = Variable<int>(playerCount);
    return map;
  }

  FormationsCompanion toCompanion(bool nullToAbsent) {
    return FormationsCompanion(
      id: Value(id),
      teamId: Value(teamId),
      name: Value(name),
      playerCount: Value(playerCount),
    );
  }

  factory Formation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Formation(
      id: serializer.fromJson<int>(json['id']),
      teamId: serializer.fromJson<int>(json['teamId']),
      name: serializer.fromJson<String>(json['name']),
      playerCount: serializer.fromJson<int>(json['playerCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'teamId': serializer.toJson<int>(teamId),
      'name': serializer.toJson<String>(name),
      'playerCount': serializer.toJson<int>(playerCount),
    };
  }

  Formation copyWith({int? id, int? teamId, String? name, int? playerCount}) =>
      Formation(
        id: id ?? this.id,
        teamId: teamId ?? this.teamId,
        name: name ?? this.name,
        playerCount: playerCount ?? this.playerCount,
      );
  Formation copyWithCompanion(FormationsCompanion data) {
    return Formation(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      name: data.name.present ? data.name.value : this.name,
      playerCount: data.playerCount.present
          ? data.playerCount.value
          : this.playerCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Formation(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('playerCount: $playerCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, teamId, name, playerCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Formation &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.name == this.name &&
          other.playerCount == this.playerCount);
}

class FormationsCompanion extends UpdateCompanion<Formation> {
  final Value<int> id;
  final Value<int> teamId;
  final Value<String> name;
  final Value<int> playerCount;
  const FormationsCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.name = const Value.absent(),
    this.playerCount = const Value.absent(),
  });
  FormationsCompanion.insert({
    this.id = const Value.absent(),
    required int teamId,
    required String name,
    required int playerCount,
  }) : teamId = Value(teamId),
       name = Value(name),
       playerCount = Value(playerCount);
  static Insertable<Formation> custom({
    Expression<int>? id,
    Expression<int>? teamId,
    Expression<String>? name,
    Expression<int>? playerCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (name != null) 'name': name,
      if (playerCount != null) 'player_count': playerCount,
    });
  }

  FormationsCompanion copyWith({
    Value<int>? id,
    Value<int>? teamId,
    Value<String>? name,
    Value<int>? playerCount,
  }) {
    return FormationsCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      playerCount: playerCount ?? this.playerCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (playerCount.present) {
      map['player_count'] = Variable<int>(playerCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormationsCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('playerCount: $playerCount')
          ..write(')'))
        .toString();
  }
}

class $GamesTable extends Games with TableInfo<$GamesTable, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opponentMeta = const VerificationMeta(
    'opponent',
  );
  @override
  late final GeneratedColumn<String> opponent = GeneratedColumn<String>(
    'opponent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentShiftIdMeta = const VerificationMeta(
    'currentShiftId',
  );
  @override
  late final GeneratedColumn<int> currentShiftId = GeneratedColumn<int>(
    'current_shift_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id)',
    ),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currentHalfMeta = const VerificationMeta(
    'currentHalf',
  );
  @override
  late final GeneratedColumn<int> currentHalf = GeneratedColumn<int>(
    'current_half',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _gameTimeSecondsMeta = const VerificationMeta(
    'gameTimeSeconds',
  );
  @override
  late final GeneratedColumn<int> gameTimeSeconds = GeneratedColumn<int>(
    'game_time_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isGameActiveMeta = const VerificationMeta(
    'isGameActive',
  );
  @override
  late final GeneratedColumn<bool> isGameActive = GeneratedColumn<bool>(
    'is_game_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_game_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _formationIdMeta = const VerificationMeta(
    'formationId',
  );
  @override
  late final GeneratedColumn<int> formationId = GeneratedColumn<int>(
    'formation_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES formations (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startTime,
    opponent,
    currentShiftId,
    teamId,
    isArchived,
    currentHalf,
    gameTimeSeconds,
    isGameActive,
    formationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<Game> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('opponent')) {
      context.handle(
        _opponentMeta,
        opponent.isAcceptableOrUnknown(data['opponent']!, _opponentMeta),
      );
    }
    if (data.containsKey('current_shift_id')) {
      context.handle(
        _currentShiftIdMeta,
        currentShiftId.isAcceptableOrUnknown(
          data['current_shift_id']!,
          _currentShiftIdMeta,
        ),
      );
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('current_half')) {
      context.handle(
        _currentHalfMeta,
        currentHalf.isAcceptableOrUnknown(
          data['current_half']!,
          _currentHalfMeta,
        ),
      );
    }
    if (data.containsKey('game_time_seconds')) {
      context.handle(
        _gameTimeSecondsMeta,
        gameTimeSeconds.isAcceptableOrUnknown(
          data['game_time_seconds']!,
          _gameTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_game_active')) {
      context.handle(
        _isGameActiveMeta,
        isGameActive.isAcceptableOrUnknown(
          data['is_game_active']!,
          _isGameActiveMeta,
        ),
      );
    }
    if (data.containsKey('formation_id')) {
      context.handle(
        _formationIdMeta,
        formationId.isAcceptableOrUnknown(
          data['formation_id']!,
          _formationIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      ),
      opponent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opponent'],
      ),
      currentShiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_shift_id'],
      ),
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      currentHalf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_half'],
      )!,
      gameTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_time_seconds'],
      )!,
      isGameActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_game_active'],
      )!,
      formationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}formation_id'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class Game extends DataClass implements Insertable<Game> {
  final int id;
  final DateTime? startTime;
  final String? opponent;
  final int? currentShiftId;
  final int teamId;
  final bool isArchived;
  final int currentHalf;
  final int gameTimeSeconds;
  final bool isGameActive;
  final int? formationId;
  const Game({
    required this.id,
    this.startTime,
    this.opponent,
    this.currentShiftId,
    required this.teamId,
    required this.isArchived,
    required this.currentHalf,
    required this.gameTimeSeconds,
    required this.isGameActive,
    this.formationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<DateTime>(startTime);
    }
    if (!nullToAbsent || opponent != null) {
      map['opponent'] = Variable<String>(opponent);
    }
    if (!nullToAbsent || currentShiftId != null) {
      map['current_shift_id'] = Variable<int>(currentShiftId);
    }
    map['team_id'] = Variable<int>(teamId);
    map['is_archived'] = Variable<bool>(isArchived);
    map['current_half'] = Variable<int>(currentHalf);
    map['game_time_seconds'] = Variable<int>(gameTimeSeconds);
    map['is_game_active'] = Variable<bool>(isGameActive);
    if (!nullToAbsent || formationId != null) {
      map['formation_id'] = Variable<int>(formationId);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      opponent: opponent == null && nullToAbsent
          ? const Value.absent()
          : Value(opponent),
      currentShiftId: currentShiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentShiftId),
      teamId: Value(teamId),
      isArchived: Value(isArchived),
      currentHalf: Value(currentHalf),
      gameTimeSeconds: Value(gameTimeSeconds),
      isGameActive: Value(isGameActive),
      formationId: formationId == null && nullToAbsent
          ? const Value.absent()
          : Value(formationId),
    );
  }

  factory Game.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      id: serializer.fromJson<int>(json['id']),
      startTime: serializer.fromJson<DateTime?>(json['startTime']),
      opponent: serializer.fromJson<String?>(json['opponent']),
      currentShiftId: serializer.fromJson<int?>(json['currentShiftId']),
      teamId: serializer.fromJson<int>(json['teamId']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      currentHalf: serializer.fromJson<int>(json['currentHalf']),
      gameTimeSeconds: serializer.fromJson<int>(json['gameTimeSeconds']),
      isGameActive: serializer.fromJson<bool>(json['isGameActive']),
      formationId: serializer.fromJson<int?>(json['formationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startTime': serializer.toJson<DateTime?>(startTime),
      'opponent': serializer.toJson<String?>(opponent),
      'currentShiftId': serializer.toJson<int?>(currentShiftId),
      'teamId': serializer.toJson<int>(teamId),
      'isArchived': serializer.toJson<bool>(isArchived),
      'currentHalf': serializer.toJson<int>(currentHalf),
      'gameTimeSeconds': serializer.toJson<int>(gameTimeSeconds),
      'isGameActive': serializer.toJson<bool>(isGameActive),
      'formationId': serializer.toJson<int?>(formationId),
    };
  }

  Game copyWith({
    int? id,
    Value<DateTime?> startTime = const Value.absent(),
    Value<String?> opponent = const Value.absent(),
    Value<int?> currentShiftId = const Value.absent(),
    int? teamId,
    bool? isArchived,
    int? currentHalf,
    int? gameTimeSeconds,
    bool? isGameActive,
    Value<int?> formationId = const Value.absent(),
  }) => Game(
    id: id ?? this.id,
    startTime: startTime.present ? startTime.value : this.startTime,
    opponent: opponent.present ? opponent.value : this.opponent,
    currentShiftId: currentShiftId.present
        ? currentShiftId.value
        : this.currentShiftId,
    teamId: teamId ?? this.teamId,
    isArchived: isArchived ?? this.isArchived,
    currentHalf: currentHalf ?? this.currentHalf,
    gameTimeSeconds: gameTimeSeconds ?? this.gameTimeSeconds,
    isGameActive: isGameActive ?? this.isGameActive,
    formationId: formationId.present ? formationId.value : this.formationId,
  );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      opponent: data.opponent.present ? data.opponent.value : this.opponent,
      currentShiftId: data.currentShiftId.present
          ? data.currentShiftId.value
          : this.currentShiftId,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      currentHalf: data.currentHalf.present
          ? data.currentHalf.value
          : this.currentHalf,
      gameTimeSeconds: data.gameTimeSeconds.present
          ? data.gameTimeSeconds.value
          : this.gameTimeSeconds,
      isGameActive: data.isGameActive.present
          ? data.isGameActive.value
          : this.isGameActive,
      formationId: data.formationId.present
          ? data.formationId.value
          : this.formationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('opponent: $opponent, ')
          ..write('currentShiftId: $currentShiftId, ')
          ..write('teamId: $teamId, ')
          ..write('isArchived: $isArchived, ')
          ..write('currentHalf: $currentHalf, ')
          ..write('gameTimeSeconds: $gameTimeSeconds, ')
          ..write('isGameActive: $isGameActive, ')
          ..write('formationId: $formationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startTime,
    opponent,
    currentShiftId,
    teamId,
    isArchived,
    currentHalf,
    gameTimeSeconds,
    isGameActive,
    formationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.opponent == this.opponent &&
          other.currentShiftId == this.currentShiftId &&
          other.teamId == this.teamId &&
          other.isArchived == this.isArchived &&
          other.currentHalf == this.currentHalf &&
          other.gameTimeSeconds == this.gameTimeSeconds &&
          other.isGameActive == this.isGameActive &&
          other.formationId == this.formationId);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<int> id;
  final Value<DateTime?> startTime;
  final Value<String?> opponent;
  final Value<int?> currentShiftId;
  final Value<int> teamId;
  final Value<bool> isArchived;
  final Value<int> currentHalf;
  final Value<int> gameTimeSeconds;
  final Value<bool> isGameActive;
  final Value<int?> formationId;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.opponent = const Value.absent(),
    this.currentShiftId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.currentHalf = const Value.absent(),
    this.gameTimeSeconds = const Value.absent(),
    this.isGameActive = const Value.absent(),
    this.formationId = const Value.absent(),
  });
  GamesCompanion.insert({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.opponent = const Value.absent(),
    this.currentShiftId = const Value.absent(),
    required int teamId,
    this.isArchived = const Value.absent(),
    this.currentHalf = const Value.absent(),
    this.gameTimeSeconds = const Value.absent(),
    this.isGameActive = const Value.absent(),
    this.formationId = const Value.absent(),
  }) : teamId = Value(teamId);
  static Insertable<Game> custom({
    Expression<int>? id,
    Expression<DateTime>? startTime,
    Expression<String>? opponent,
    Expression<int>? currentShiftId,
    Expression<int>? teamId,
    Expression<bool>? isArchived,
    Expression<int>? currentHalf,
    Expression<int>? gameTimeSeconds,
    Expression<bool>? isGameActive,
    Expression<int>? formationId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (opponent != null) 'opponent': opponent,
      if (currentShiftId != null) 'current_shift_id': currentShiftId,
      if (teamId != null) 'team_id': teamId,
      if (isArchived != null) 'is_archived': isArchived,
      if (currentHalf != null) 'current_half': currentHalf,
      if (gameTimeSeconds != null) 'game_time_seconds': gameTimeSeconds,
      if (isGameActive != null) 'is_game_active': isGameActive,
      if (formationId != null) 'formation_id': formationId,
    });
  }

  GamesCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? startTime,
    Value<String?>? opponent,
    Value<int?>? currentShiftId,
    Value<int>? teamId,
    Value<bool>? isArchived,
    Value<int>? currentHalf,
    Value<int>? gameTimeSeconds,
    Value<bool>? isGameActive,
    Value<int?>? formationId,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      opponent: opponent ?? this.opponent,
      currentShiftId: currentShiftId ?? this.currentShiftId,
      teamId: teamId ?? this.teamId,
      isArchived: isArchived ?? this.isArchived,
      currentHalf: currentHalf ?? this.currentHalf,
      gameTimeSeconds: gameTimeSeconds ?? this.gameTimeSeconds,
      isGameActive: isGameActive ?? this.isGameActive,
      formationId: formationId ?? this.formationId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (opponent.present) {
      map['opponent'] = Variable<String>(opponent.value);
    }
    if (currentShiftId.present) {
      map['current_shift_id'] = Variable<int>(currentShiftId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (currentHalf.present) {
      map['current_half'] = Variable<int>(currentHalf.value);
    }
    if (gameTimeSeconds.present) {
      map['game_time_seconds'] = Variable<int>(gameTimeSeconds.value);
    }
    if (isGameActive.present) {
      map['is_game_active'] = Variable<bool>(isGameActive.value);
    }
    if (formationId.present) {
      map['formation_id'] = Variable<int>(formationId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('opponent: $opponent, ')
          ..write('currentShiftId: $currentShiftId, ')
          ..write('teamId: $teamId, ')
          ..write('isArchived: $isArchived, ')
          ..write('currentHalf: $currentHalf, ')
          ..write('gameTimeSeconds: $gameTimeSeconds, ')
          ..write('isGameActive: $isGameActive, ')
          ..write('formationId: $formationId')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, Shift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id)',
    ),
  );
  static const VerificationMeta _startSecondsMeta = const VerificationMeta(
    'startSeconds',
  );
  @override
  late final GeneratedColumn<int> startSeconds = GeneratedColumn<int>(
    'start_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endSecondsMeta = const VerificationMeta(
    'endSeconds',
  );
  @override
  late final GeneratedColumn<int> endSeconds = GeneratedColumn<int>(
    'end_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualSecondsMeta = const VerificationMeta(
    'actualSeconds',
  );
  @override
  late final GeneratedColumn<int> actualSeconds = GeneratedColumn<int>(
    'actual_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    startSeconds,
    endSeconds,
    notes,
    actualSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shift> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('start_seconds')) {
      context.handle(
        _startSecondsMeta,
        startSeconds.isAcceptableOrUnknown(
          data['start_seconds']!,
          _startSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startSecondsMeta);
    }
    if (data.containsKey('end_seconds')) {
      context.handle(
        _endSecondsMeta,
        endSeconds.isAcceptableOrUnknown(data['end_seconds']!, _endSecondsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('actual_seconds')) {
      context.handle(
        _actualSecondsMeta,
        actualSeconds.isAcceptableOrUnknown(
          data['actual_seconds']!,
          _actualSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shift(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      startSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_seconds'],
      )!,
      endSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_seconds'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      actualSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_seconds'],
      )!,
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class Shift extends DataClass implements Insertable<Shift> {
  final int id;
  final int gameId;
  final int startSeconds;
  final int? endSeconds;
  final String? notes;
  final int actualSeconds;
  const Shift({
    required this.id,
    required this.gameId,
    required this.startSeconds,
    this.endSeconds,
    this.notes,
    required this.actualSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['start_seconds'] = Variable<int>(startSeconds);
    if (!nullToAbsent || endSeconds != null) {
      map['end_seconds'] = Variable<int>(endSeconds);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['actual_seconds'] = Variable<int>(actualSeconds);
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      startSeconds: Value(startSeconds),
      endSeconds: endSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(endSeconds),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      actualSeconds: Value(actualSeconds),
    );
  }

  factory Shift.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shift(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      startSeconds: serializer.fromJson<int>(json['startSeconds']),
      endSeconds: serializer.fromJson<int?>(json['endSeconds']),
      notes: serializer.fromJson<String?>(json['notes']),
      actualSeconds: serializer.fromJson<int>(json['actualSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'startSeconds': serializer.toJson<int>(startSeconds),
      'endSeconds': serializer.toJson<int?>(endSeconds),
      'notes': serializer.toJson<String?>(notes),
      'actualSeconds': serializer.toJson<int>(actualSeconds),
    };
  }

  Shift copyWith({
    int? id,
    int? gameId,
    int? startSeconds,
    Value<int?> endSeconds = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? actualSeconds,
  }) => Shift(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    startSeconds: startSeconds ?? this.startSeconds,
    endSeconds: endSeconds.present ? endSeconds.value : this.endSeconds,
    notes: notes.present ? notes.value : this.notes,
    actualSeconds: actualSeconds ?? this.actualSeconds,
  );
  Shift copyWithCompanion(ShiftsCompanion data) {
    return Shift(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      startSeconds: data.startSeconds.present
          ? data.startSeconds.value
          : this.startSeconds,
      endSeconds: data.endSeconds.present
          ? data.endSeconds.value
          : this.endSeconds,
      notes: data.notes.present ? data.notes.value : this.notes,
      actualSeconds: data.actualSeconds.present
          ? data.actualSeconds.value
          : this.actualSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shift(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('startSeconds: $startSeconds, ')
          ..write('endSeconds: $endSeconds, ')
          ..write('notes: $notes, ')
          ..write('actualSeconds: $actualSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, startSeconds, endSeconds, notes, actualSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shift &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.startSeconds == this.startSeconds &&
          other.endSeconds == this.endSeconds &&
          other.notes == this.notes &&
          other.actualSeconds == this.actualSeconds);
}

class ShiftsCompanion extends UpdateCompanion<Shift> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> startSeconds;
  final Value<int?> endSeconds;
  final Value<String?> notes;
  final Value<int> actualSeconds;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.startSeconds = const Value.absent(),
    this.endSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.actualSeconds = const Value.absent(),
  });
  ShiftsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int startSeconds,
    this.endSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.actualSeconds = const Value.absent(),
  }) : gameId = Value(gameId),
       startSeconds = Value(startSeconds);
  static Insertable<Shift> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? startSeconds,
    Expression<int>? endSeconds,
    Expression<String>? notes,
    Expression<int>? actualSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (startSeconds != null) 'start_seconds': startSeconds,
      if (endSeconds != null) 'end_seconds': endSeconds,
      if (notes != null) 'notes': notes,
      if (actualSeconds != null) 'actual_seconds': actualSeconds,
    });
  }

  ShiftsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? startSeconds,
    Value<int?>? endSeconds,
    Value<String?>? notes,
    Value<int>? actualSeconds,
  }) {
    return ShiftsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      startSeconds: startSeconds ?? this.startSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
      notes: notes ?? this.notes,
      actualSeconds: actualSeconds ?? this.actualSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (startSeconds.present) {
      map['start_seconds'] = Variable<int>(startSeconds.value);
    }
    if (endSeconds.present) {
      map['end_seconds'] = Variable<int>(endSeconds.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (actualSeconds.present) {
      map['actual_seconds'] = Variable<int>(actualSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('startSeconds: $startSeconds, ')
          ..write('endSeconds: $endSeconds, ')
          ..write('notes: $notes, ')
          ..write('actualSeconds: $actualSeconds')
          ..write(')'))
        .toString();
  }
}

class $PlayerShiftsTable extends PlayerShifts
    with TableInfo<$PlayerShiftsTable, PlayerShift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shifts (id)',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, shiftId, playerId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerShift> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerShift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerShift(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shift_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PlayerShiftsTable createAlias(String alias) {
    return $PlayerShiftsTable(attachedDatabase, alias);
  }
}

class PlayerShift extends DataClass implements Insertable<PlayerShift> {
  final int id;
  final int shiftId;
  final int playerId;
  final String position;
  const PlayerShift({
    required this.id,
    required this.shiftId,
    required this.playerId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shift_id'] = Variable<int>(shiftId);
    map['player_id'] = Variable<int>(playerId);
    map['position'] = Variable<String>(position);
    return map;
  }

  PlayerShiftsCompanion toCompanion(bool nullToAbsent) {
    return PlayerShiftsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      playerId: Value(playerId),
      position: Value(position),
    );
  }

  factory PlayerShift.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerShift(
      id: serializer.fromJson<int>(json['id']),
      shiftId: serializer.fromJson<int>(json['shiftId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      position: serializer.fromJson<String>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shiftId': serializer.toJson<int>(shiftId),
      'playerId': serializer.toJson<int>(playerId),
      'position': serializer.toJson<String>(position),
    };
  }

  PlayerShift copyWith({
    int? id,
    int? shiftId,
    int? playerId,
    String? position,
  }) => PlayerShift(
    id: id ?? this.id,
    shiftId: shiftId ?? this.shiftId,
    playerId: playerId ?? this.playerId,
    position: position ?? this.position,
  );
  PlayerShift copyWithCompanion(PlayerShiftsCompanion data) {
    return PlayerShift(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerShift(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('playerId: $playerId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shiftId, playerId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerShift &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.playerId == this.playerId &&
          other.position == this.position);
}

class PlayerShiftsCompanion extends UpdateCompanion<PlayerShift> {
  final Value<int> id;
  final Value<int> shiftId;
  final Value<int> playerId;
  final Value<String> position;
  const PlayerShiftsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.position = const Value.absent(),
  });
  PlayerShiftsCompanion.insert({
    this.id = const Value.absent(),
    required int shiftId,
    required int playerId,
    required String position,
  }) : shiftId = Value(shiftId),
       playerId = Value(playerId),
       position = Value(position);
  static Insertable<PlayerShift> custom({
    Expression<int>? id,
    Expression<int>? shiftId,
    Expression<int>? playerId,
    Expression<String>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (playerId != null) 'player_id': playerId,
      if (position != null) 'position': position,
    });
  }

  PlayerShiftsCompanion copyWith({
    Value<int>? id,
    Value<int>? shiftId,
    Value<int>? playerId,
    Value<String>? position,
  }) {
    return PlayerShiftsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      playerId: playerId ?? this.playerId,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerShiftsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('playerId: $playerId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $PlayerMetricsTable extends PlayerMetrics
    with TableInfo<$PlayerMetricsTable, PlayerMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id)',
    ),
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, playerId, gameId, metric, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerMetric> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerMetric(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PlayerMetricsTable createAlias(String alias) {
    return $PlayerMetricsTable(attachedDatabase, alias);
  }
}

class PlayerMetric extends DataClass implements Insertable<PlayerMetric> {
  final int id;
  final int playerId;
  final int gameId;
  final String metric;
  final int value;
  const PlayerMetric({
    required this.id,
    required this.playerId,
    required this.gameId,
    required this.metric,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['game_id'] = Variable<int>(gameId);
    map['metric'] = Variable<String>(metric);
    map['value'] = Variable<int>(value);
    return map;
  }

  PlayerMetricsCompanion toCompanion(bool nullToAbsent) {
    return PlayerMetricsCompanion(
      id: Value(id),
      playerId: Value(playerId),
      gameId: Value(gameId),
      metric: Value(metric),
      value: Value(value),
    );
  }

  factory PlayerMetric.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerMetric(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      gameId: serializer.fromJson<int>(json['gameId']),
      metric: serializer.fromJson<String>(json['metric']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'gameId': serializer.toJson<int>(gameId),
      'metric': serializer.toJson<String>(metric),
      'value': serializer.toJson<int>(value),
    };
  }

  PlayerMetric copyWith({
    int? id,
    int? playerId,
    int? gameId,
    String? metric,
    int? value,
  }) => PlayerMetric(
    id: id ?? this.id,
    playerId: playerId ?? this.playerId,
    gameId: gameId ?? this.gameId,
    metric: metric ?? this.metric,
    value: value ?? this.value,
  );
  PlayerMetric copyWithCompanion(PlayerMetricsCompanion data) {
    return PlayerMetric(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerMetric(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('gameId: $gameId, ')
          ..write('metric: $metric, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playerId, gameId, metric, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerMetric &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.gameId == this.gameId &&
          other.metric == this.metric &&
          other.value == this.value);
}

class PlayerMetricsCompanion extends UpdateCompanion<PlayerMetric> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<int> gameId;
  final Value<String> metric;
  final Value<int> value;
  const PlayerMetricsCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
  });
  PlayerMetricsCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required int gameId,
    required String metric,
    this.value = const Value.absent(),
  }) : playerId = Value(playerId),
       gameId = Value(gameId),
       metric = Value(metric);
  static Insertable<PlayerMetric> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<int>? gameId,
    Expression<String>? metric,
    Expression<int>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (gameId != null) 'game_id': gameId,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
    });
  }

  PlayerMetricsCompanion copyWith({
    Value<int>? id,
    Value<int>? playerId,
    Value<int>? gameId,
    Value<String>? metric,
    Value<int>? value,
  }) {
    return PlayerMetricsCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      gameId: gameId ?? this.gameId,
      metric: metric ?? this.metric,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerMetricsCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('gameId: $gameId, ')
          ..write('metric: $metric, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $GamePlayersTable extends GamePlayers
    with TableInfo<$GamePlayersTable, GamePlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamePlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id)',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _isPresentMeta = const VerificationMeta(
    'isPresent',
  );
  @override
  late final GeneratedColumn<bool> isPresent = GeneratedColumn<bool>(
    'is_present',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_present" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, gameId, playerId, isPresent];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_players';
  @override
  VerificationContext validateIntegrity(
    Insertable<GamePlayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('is_present')) {
      context.handle(
        _isPresentMeta,
        isPresent.isAcceptableOrUnknown(data['is_present']!, _isPresentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GamePlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GamePlayer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      isPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_present'],
      )!,
    );
  }

  @override
  $GamePlayersTable createAlias(String alias) {
    return $GamePlayersTable(attachedDatabase, alias);
  }
}

class GamePlayer extends DataClass implements Insertable<GamePlayer> {
  final int id;
  final int gameId;
  final int playerId;
  final bool isPresent;
  const GamePlayer({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.isPresent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['player_id'] = Variable<int>(playerId);
    map['is_present'] = Variable<bool>(isPresent);
    return map;
  }

  GamePlayersCompanion toCompanion(bool nullToAbsent) {
    return GamePlayersCompanion(
      id: Value(id),
      gameId: Value(gameId),
      playerId: Value(playerId),
      isPresent: Value(isPresent),
    );
  }

  factory GamePlayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GamePlayer(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      isPresent: serializer.fromJson<bool>(json['isPresent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'playerId': serializer.toJson<int>(playerId),
      'isPresent': serializer.toJson<bool>(isPresent),
    };
  }

  GamePlayer copyWith({int? id, int? gameId, int? playerId, bool? isPresent}) =>
      GamePlayer(
        id: id ?? this.id,
        gameId: gameId ?? this.gameId,
        playerId: playerId ?? this.playerId,
        isPresent: isPresent ?? this.isPresent,
      );
  GamePlayer copyWithCompanion(GamePlayersCompanion data) {
    return GamePlayer(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      isPresent: data.isPresent.present ? data.isPresent.value : this.isPresent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GamePlayer(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('isPresent: $isPresent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gameId, playerId, isPresent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GamePlayer &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.playerId == this.playerId &&
          other.isPresent == this.isPresent);
}

class GamePlayersCompanion extends UpdateCompanion<GamePlayer> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> playerId;
  final Value<bool> isPresent;
  const GamePlayersCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.isPresent = const Value.absent(),
  });
  GamePlayersCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int playerId,
    this.isPresent = const Value.absent(),
  }) : gameId = Value(gameId),
       playerId = Value(playerId);
  static Insertable<GamePlayer> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? playerId,
    Expression<bool>? isPresent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (playerId != null) 'player_id': playerId,
      if (isPresent != null) 'is_present': isPresent,
    });
  }

  GamePlayersCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? playerId,
    Value<bool>? isPresent,
  }) {
    return GamePlayersCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      isPresent: isPresent ?? this.isPresent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (isPresent.present) {
      map['is_present'] = Variable<bool>(isPresent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamePlayersCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('isPresent: $isPresent')
          ..write(')'))
        .toString();
  }
}

class $PlayerPositionTotalsTable extends PlayerPositionTotals
    with TableInfo<$PlayerPositionTotalsTable, PlayerPositionTotal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerPositionTotalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSecondsMeta = const VerificationMeta(
    'totalSeconds',
  );
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
    'total_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, playerId, position, totalSeconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_position_totals';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerPositionTotal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
        _totalSecondsMeta,
        totalSeconds.isAcceptableOrUnknown(
          data['total_seconds']!,
          _totalSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerPositionTotal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerPositionTotal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
      totalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seconds'],
      )!,
    );
  }

  @override
  $PlayerPositionTotalsTable createAlias(String alias) {
    return $PlayerPositionTotalsTable(attachedDatabase, alias);
  }
}

class PlayerPositionTotal extends DataClass
    implements Insertable<PlayerPositionTotal> {
  final int id;
  final int playerId;
  final String position;
  final int totalSeconds;
  const PlayerPositionTotal({
    required this.id,
    required this.playerId,
    required this.position,
    required this.totalSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['position'] = Variable<String>(position);
    map['total_seconds'] = Variable<int>(totalSeconds);
    return map;
  }

  PlayerPositionTotalsCompanion toCompanion(bool nullToAbsent) {
    return PlayerPositionTotalsCompanion(
      id: Value(id),
      playerId: Value(playerId),
      position: Value(position),
      totalSeconds: Value(totalSeconds),
    );
  }

  factory PlayerPositionTotal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerPositionTotal(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      position: serializer.fromJson<String>(json['position']),
      totalSeconds: serializer.fromJson<int>(json['totalSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'position': serializer.toJson<String>(position),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
    };
  }

  PlayerPositionTotal copyWith({
    int? id,
    int? playerId,
    String? position,
    int? totalSeconds,
  }) => PlayerPositionTotal(
    id: id ?? this.id,
    playerId: playerId ?? this.playerId,
    position: position ?? this.position,
    totalSeconds: totalSeconds ?? this.totalSeconds,
  );
  PlayerPositionTotal copyWithCompanion(PlayerPositionTotalsCompanion data) {
    return PlayerPositionTotal(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      position: data.position.present ? data.position.value : this.position,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerPositionTotal(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('position: $position, ')
          ..write('totalSeconds: $totalSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playerId, position, totalSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerPositionTotal &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.position == this.position &&
          other.totalSeconds == this.totalSeconds);
}

class PlayerPositionTotalsCompanion
    extends UpdateCompanion<PlayerPositionTotal> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> position;
  final Value<int> totalSeconds;
  const PlayerPositionTotalsCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.position = const Value.absent(),
    this.totalSeconds = const Value.absent(),
  });
  PlayerPositionTotalsCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String position,
    this.totalSeconds = const Value.absent(),
  }) : playerId = Value(playerId),
       position = Value(position);
  static Insertable<PlayerPositionTotal> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? position,
    Expression<int>? totalSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (position != null) 'position': position,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
    });
  }

  PlayerPositionTotalsCompanion copyWith({
    Value<int>? id,
    Value<int>? playerId,
    Value<String>? position,
    Value<int>? totalSeconds,
  }) {
    return PlayerPositionTotalsCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      position: position ?? this.position,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerPositionTotalsCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('position: $position, ')
          ..write('totalSeconds: $totalSeconds')
          ..write(')'))
        .toString();
  }
}

class $FormationPositionsTable extends FormationPositions
    with TableInfo<$FormationPositionsTable, FormationPosition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormationPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _formationIdMeta = const VerificationMeta(
    'formationId',
  );
  @override
  late final GeneratedColumn<int> formationId = GeneratedColumn<int>(
    'formation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES formations (id)',
    ),
  );
  static const VerificationMeta _indexMeta = const VerificationMeta('index');
  @override
  late final GeneratedColumn<int> index = GeneratedColumn<int>(
    'index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionNameMeta = const VerificationMeta(
    'positionName',
  );
  @override
  late final GeneratedColumn<String> positionName = GeneratedColumn<String>(
    'position_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, formationId, index, positionName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'formation_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FormationPosition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('formation_id')) {
      context.handle(
        _formationIdMeta,
        formationId.isAcceptableOrUnknown(
          data['formation_id']!,
          _formationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formationIdMeta);
    }
    if (data.containsKey('index')) {
      context.handle(
        _indexMeta,
        index.isAcceptableOrUnknown(data['index']!, _indexMeta),
      );
    } else if (isInserting) {
      context.missing(_indexMeta);
    }
    if (data.containsKey('position_name')) {
      context.handle(
        _positionNameMeta,
        positionName.isAcceptableOrUnknown(
          data['position_name']!,
          _positionNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FormationPosition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FormationPosition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      formationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}formation_id'],
      )!,
      index: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}index'],
      )!,
      positionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position_name'],
      )!,
    );
  }

  @override
  $FormationPositionsTable createAlias(String alias) {
    return $FormationPositionsTable(attachedDatabase, alias);
  }
}

class FormationPosition extends DataClass
    implements Insertable<FormationPosition> {
  final int id;
  final int formationId;
  final int index;
  final String positionName;
  const FormationPosition({
    required this.id,
    required this.formationId,
    required this.index,
    required this.positionName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['formation_id'] = Variable<int>(formationId);
    map['index'] = Variable<int>(index);
    map['position_name'] = Variable<String>(positionName);
    return map;
  }

  FormationPositionsCompanion toCompanion(bool nullToAbsent) {
    return FormationPositionsCompanion(
      id: Value(id),
      formationId: Value(formationId),
      index: Value(index),
      positionName: Value(positionName),
    );
  }

  factory FormationPosition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FormationPosition(
      id: serializer.fromJson<int>(json['id']),
      formationId: serializer.fromJson<int>(json['formationId']),
      index: serializer.fromJson<int>(json['index']),
      positionName: serializer.fromJson<String>(json['positionName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'formationId': serializer.toJson<int>(formationId),
      'index': serializer.toJson<int>(index),
      'positionName': serializer.toJson<String>(positionName),
    };
  }

  FormationPosition copyWith({
    int? id,
    int? formationId,
    int? index,
    String? positionName,
  }) => FormationPosition(
    id: id ?? this.id,
    formationId: formationId ?? this.formationId,
    index: index ?? this.index,
    positionName: positionName ?? this.positionName,
  );
  FormationPosition copyWithCompanion(FormationPositionsCompanion data) {
    return FormationPosition(
      id: data.id.present ? data.id.value : this.id,
      formationId: data.formationId.present
          ? data.formationId.value
          : this.formationId,
      index: data.index.present ? data.index.value : this.index,
      positionName: data.positionName.present
          ? data.positionName.value
          : this.positionName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FormationPosition(')
          ..write('id: $id, ')
          ..write('formationId: $formationId, ')
          ..write('index: $index, ')
          ..write('positionName: $positionName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, formationId, index, positionName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FormationPosition &&
          other.id == this.id &&
          other.formationId == this.formationId &&
          other.index == this.index &&
          other.positionName == this.positionName);
}

class FormationPositionsCompanion extends UpdateCompanion<FormationPosition> {
  final Value<int> id;
  final Value<int> formationId;
  final Value<int> index;
  final Value<String> positionName;
  const FormationPositionsCompanion({
    this.id = const Value.absent(),
    this.formationId = const Value.absent(),
    this.index = const Value.absent(),
    this.positionName = const Value.absent(),
  });
  FormationPositionsCompanion.insert({
    this.id = const Value.absent(),
    required int formationId,
    required int index,
    required String positionName,
  }) : formationId = Value(formationId),
       index = Value(index),
       positionName = Value(positionName);
  static Insertable<FormationPosition> custom({
    Expression<int>? id,
    Expression<int>? formationId,
    Expression<int>? index,
    Expression<String>? positionName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (formationId != null) 'formation_id': formationId,
      if (index != null) 'index': index,
      if (positionName != null) 'position_name': positionName,
    });
  }

  FormationPositionsCompanion copyWith({
    Value<int>? id,
    Value<int>? formationId,
    Value<int>? index,
    Value<String>? positionName,
  }) {
    return FormationPositionsCompanion(
      id: id ?? this.id,
      formationId: formationId ?? this.formationId,
      index: index ?? this.index,
      positionName: positionName ?? this.positionName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (formationId.present) {
      map['formation_id'] = Variable<int>(formationId.value);
    }
    if (index.present) {
      map['index'] = Variable<int>(index.value);
    }
    if (positionName.present) {
      map['position_name'] = Variable<String>(positionName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormationPositionsCompanion(')
          ..write('id: $id, ')
          ..write('formationId: $formationId, ')
          ..write('index: $index, ')
          ..write('positionName: $positionName')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $FormationsTable formations = $FormationsTable(this);
  late final $GamesTable games = $GamesTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $PlayerShiftsTable playerShifts = $PlayerShiftsTable(this);
  late final $PlayerMetricsTable playerMetrics = $PlayerMetricsTable(this);
  late final $GamePlayersTable gamePlayers = $GamePlayersTable(this);
  late final $PlayerPositionTotalsTable playerPositionTotals =
      $PlayerPositionTotalsTable(this);
  late final $FormationPositionsTable formationPositions =
      $FormationPositionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    teams,
    players,
    formations,
    games,
    shifts,
    playerShifts,
    playerMetrics,
    gamePlayers,
    playerPositionTotals,
    formationPositions,
  ];
}

typedef $$TeamsTableCreateCompanionBuilder =
    TeamsCompanion Function({
      Value<int> id,
      required String name,
      Value<bool> isArchived,
      Value<String> teamMode,
      Value<int> halfDurationSeconds,
    });
typedef $$TeamsTableUpdateCompanionBuilder =
    TeamsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<bool> isArchived,
      Value<String> teamMode,
      Value<int> halfDurationSeconds,
    });

final class $$TeamsTableReferences
    extends BaseReferences<_$AppDb, $TeamsTable, Team> {
  $$TeamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlayersTable, List<Player>> _playersRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.players,
    aliasName: $_aliasNameGenerator(db.teams.id, db.players.teamId),
  );

  $$PlayersTableProcessedTableManager get playersRefs {
    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FormationsTable, List<Formation>>
  _formationsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.formations,
    aliasName: $_aliasNameGenerator(db.teams.id, db.formations.teamId),
  );

  $$FormationsTableProcessedTableManager get formationsRefs {
    final manager = $$FormationsTableTableManager(
      $_db,
      $_db.formations,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_formationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GamesTable, List<Game>> _gamesRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.games,
    aliasName: $_aliasNameGenerator(db.teams.id, db.games.teamId),
  );

  $$GamesTableProcessedTableManager get gamesRefs {
    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gamesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeamsTableFilterComposer extends Composer<_$AppDb, $TeamsTable> {
  $$TeamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamMode => $composableBuilder(
    column: $table.teamMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get halfDurationSeconds => $composableBuilder(
    column: $table.halfDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playersRefs(
    Expression<bool> Function($$PlayersTableFilterComposer f) f,
  ) {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> formationsRefs(
    Expression<bool> Function($$FormationsTableFilterComposer f) f,
  ) {
    final $$FormationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableFilterComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gamesRefs(
    Expression<bool> Function($$GamesTableFilterComposer f) f,
  ) {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableOrderingComposer extends Composer<_$AppDb, $TeamsTable> {
  $$TeamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamMode => $composableBuilder(
    column: $table.teamMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get halfDurationSeconds => $composableBuilder(
    column: $table.halfDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamsTableAnnotationComposer extends Composer<_$AppDb, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamMode =>
      $composableBuilder(column: $table.teamMode, builder: (column) => column);

  GeneratedColumn<int> get halfDurationSeconds => $composableBuilder(
    column: $table.halfDurationSeconds,
    builder: (column) => column,
  );

  Expression<T> playersRefs<T extends Object>(
    Expression<T> Function($$PlayersTableAnnotationComposer a) f,
  ) {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> formationsRefs<T extends Object>(
    Expression<T> Function($$FormationsTableAnnotationComposer a) f,
  ) {
    final $$FormationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableAnnotationComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gamesRefs<T extends Object>(
    Expression<T> Function($$GamesTableAnnotationComposer a) f,
  ) {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $TeamsTable,
          Team,
          $$TeamsTableFilterComposer,
          $$TeamsTableOrderingComposer,
          $$TeamsTableAnnotationComposer,
          $$TeamsTableCreateCompanionBuilder,
          $$TeamsTableUpdateCompanionBuilder,
          (Team, $$TeamsTableReferences),
          Team,
          PrefetchHooks Function({
            bool playersRefs,
            bool formationsRefs,
            bool gamesRefs,
          })
        > {
  $$TeamsTableTableManager(_$AppDb db, $TeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> teamMode = const Value.absent(),
                Value<int> halfDurationSeconds = const Value.absent(),
              }) => TeamsCompanion(
                id: id,
                name: name,
                isArchived: isArchived,
                teamMode: teamMode,
                halfDurationSeconds: halfDurationSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isArchived = const Value.absent(),
                Value<String> teamMode = const Value.absent(),
                Value<int> halfDurationSeconds = const Value.absent(),
              }) => TeamsCompanion.insert(
                id: id,
                name: name,
                isArchived: isArchived,
                teamMode: teamMode,
                halfDurationSeconds: halfDurationSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TeamsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                playersRefs = false,
                formationsRefs = false,
                gamesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playersRefs) db.players,
                    if (formationsRefs) db.formations,
                    if (gamesRefs) db.games,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playersRefs)
                        await $_getPrefetchedData<Team, $TeamsTable, Player>(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._playersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(db, table, p0).playersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (formationsRefs)
                        await $_getPrefetchedData<Team, $TeamsTable, Formation>(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._formationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(
                                db,
                                table,
                                p0,
                              ).formationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gamesRefs)
                        await $_getPrefetchedData<Team, $TeamsTable, Game>(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._gamesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(db, table, p0).gamesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $TeamsTable,
      Team,
      $$TeamsTableFilterComposer,
      $$TeamsTableOrderingComposer,
      $$TeamsTableAnnotationComposer,
      $$TeamsTableCreateCompanionBuilder,
      $$TeamsTableUpdateCompanionBuilder,
      (Team, $$TeamsTableReferences),
      Team,
      PrefetchHooks Function({
        bool playersRefs,
        bool formationsRefs,
        bool gamesRefs,
      })
    >;
typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      required int teamId,
      required String firstName,
      required String lastName,
      Value<bool> isPresent,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      Value<int> teamId,
      Value<String> firstName,
      Value<String> lastName,
      Value<bool> isPresent,
    });

final class $$PlayersTableReferences
    extends BaseReferences<_$AppDb, $PlayersTable, Player> {
  $$PlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDb db) => db.teams.createAlias(
    $_aliasNameGenerator(db.players.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<int>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlayerShiftsTable, List<PlayerShift>>
  _playerShiftsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.playerShifts,
    aliasName: $_aliasNameGenerator(db.players.id, db.playerShifts.playerId),
  );

  $$PlayerShiftsTableProcessedTableManager get playerShiftsRefs {
    final manager = $$PlayerShiftsTableTableManager(
      $_db,
      $_db.playerShifts,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playerShiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlayerMetricsTable, List<PlayerMetric>>
  _playerMetricsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.playerMetrics,
    aliasName: $_aliasNameGenerator(db.players.id, db.playerMetrics.playerId),
  );

  $$PlayerMetricsTableProcessedTableManager get playerMetricsRefs {
    final manager = $$PlayerMetricsTableTableManager(
      $_db,
      $_db.playerMetrics,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playerMetricsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GamePlayersTable, List<GamePlayer>>
  _gamePlayersRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.gamePlayers,
    aliasName: $_aliasNameGenerator(db.players.id, db.gamePlayers.playerId),
  );

  $$GamePlayersTableProcessedTableManager get gamePlayersRefs {
    final manager = $$GamePlayersTableTableManager(
      $_db,
      $_db.gamePlayers,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gamePlayersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PlayerPositionTotalsTable,
    List<PlayerPositionTotal>
  >
  _playerPositionTotalsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.playerPositionTotals,
    aliasName: $_aliasNameGenerator(
      db.players.id,
      db.playerPositionTotals.playerId,
    ),
  );

  $$PlayerPositionTotalsTableProcessedTableManager
  get playerPositionTotalsRefs {
    final manager = $$PlayerPositionTotalsTableTableManager(
      $_db,
      $_db.playerPositionTotals,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playerPositionTotalsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlayersTableFilterComposer extends Composer<_$AppDb, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPresent => $composableBuilder(
    column: $table.isPresent,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playerShiftsRefs(
    Expression<bool> Function($$PlayerShiftsTableFilterComposer f) f,
  ) {
    final $$PlayerShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerShifts,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerShiftsTableFilterComposer(
            $db: $db,
            $table: $db.playerShifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playerMetricsRefs(
    Expression<bool> Function($$PlayerMetricsTableFilterComposer f) f,
  ) {
    final $$PlayerMetricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerMetrics,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerMetricsTableFilterComposer(
            $db: $db,
            $table: $db.playerMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gamePlayersRefs(
    Expression<bool> Function($$GamePlayersTableFilterComposer f) f,
  ) {
    final $$GamePlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gamePlayers,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamePlayersTableFilterComposer(
            $db: $db,
            $table: $db.gamePlayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playerPositionTotalsRefs(
    Expression<bool> Function($$PlayerPositionTotalsTableFilterComposer f) f,
  ) {
    final $$PlayerPositionTotalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerPositionTotals,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerPositionTotalsTableFilterComposer(
            $db: $db,
            $table: $db.playerPositionTotals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableOrderingComposer extends Composer<_$AppDb, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPresent => $composableBuilder(
    column: $table.isPresent,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDb, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<bool> get isPresent =>
      $composableBuilder(column: $table.isPresent, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playerShiftsRefs<T extends Object>(
    Expression<T> Function($$PlayerShiftsTableAnnotationComposer a) f,
  ) {
    final $$PlayerShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerShifts,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.playerShifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playerMetricsRefs<T extends Object>(
    Expression<T> Function($$PlayerMetricsTableAnnotationComposer a) f,
  ) {
    final $$PlayerMetricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerMetrics,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerMetricsTableAnnotationComposer(
            $db: $db,
            $table: $db.playerMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gamePlayersRefs<T extends Object>(
    Expression<T> Function($$GamePlayersTableAnnotationComposer a) f,
  ) {
    final $$GamePlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gamePlayers,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamePlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.gamePlayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playerPositionTotalsRefs<T extends Object>(
    Expression<T> Function($$PlayerPositionTotalsTableAnnotationComposer a) f,
  ) {
    final $$PlayerPositionTotalsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playerPositionTotals,
          getReferencedColumn: (t) => t.playerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlayerPositionTotalsTableAnnotationComposer(
                $db: $db,
                $table: $db.playerPositionTotals,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, $$PlayersTableReferences),
          Player,
          PrefetchHooks Function({
            bool teamId,
            bool playerShiftsRefs,
            bool playerMetricsRefs,
            bool gamePlayersRefs,
            bool playerPositionTotalsRefs,
          })
        > {
  $$PlayersTableTableManager(_$AppDb db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<bool> isPresent = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                teamId: teamId,
                firstName: firstName,
                lastName: lastName,
                isPresent: isPresent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int teamId,
                required String firstName,
                required String lastName,
                Value<bool> isPresent = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                teamId: teamId,
                firstName: firstName,
                lastName: lastName,
                isPresent: isPresent,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                teamId = false,
                playerShiftsRefs = false,
                playerMetricsRefs = false,
                gamePlayersRefs = false,
                playerPositionTotalsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playerShiftsRefs) db.playerShifts,
                    if (playerMetricsRefs) db.playerMetrics,
                    if (gamePlayersRefs) db.gamePlayers,
                    if (playerPositionTotalsRefs) db.playerPositionTotals,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (teamId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.teamId,
                                    referencedTable: $$PlayersTableReferences
                                        ._teamIdTable(db),
                                    referencedColumn: $$PlayersTableReferences
                                        ._teamIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playerShiftsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          PlayerShift
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._playerShiftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).playerShiftsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playerMetricsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          PlayerMetric
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._playerMetricsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).playerMetricsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gamePlayersRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          GamePlayer
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._gamePlayersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).gamePlayersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playerPositionTotalsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          PlayerPositionTotal
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._playerPositionTotalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).playerPositionTotalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, $$PlayersTableReferences),
      Player,
      PrefetchHooks Function({
        bool teamId,
        bool playerShiftsRefs,
        bool playerMetricsRefs,
        bool gamePlayersRefs,
        bool playerPositionTotalsRefs,
      })
    >;
typedef $$FormationsTableCreateCompanionBuilder =
    FormationsCompanion Function({
      Value<int> id,
      required int teamId,
      required String name,
      required int playerCount,
    });
typedef $$FormationsTableUpdateCompanionBuilder =
    FormationsCompanion Function({
      Value<int> id,
      Value<int> teamId,
      Value<String> name,
      Value<int> playerCount,
    });

final class $$FormationsTableReferences
    extends BaseReferences<_$AppDb, $FormationsTable, Formation> {
  $$FormationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDb db) => db.teams.createAlias(
    $_aliasNameGenerator(db.formations.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<int>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GamesTable, List<Game>> _gamesRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.games,
    aliasName: $_aliasNameGenerator(db.formations.id, db.games.formationId),
  );

  $$GamesTableProcessedTableManager get gamesRefs {
    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.formationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gamesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FormationPositionsTable, List<FormationPosition>>
  _formationPositionsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.formationPositions,
    aliasName: $_aliasNameGenerator(
      db.formations.id,
      db.formationPositions.formationId,
    ),
  );

  $$FormationPositionsTableProcessedTableManager get formationPositionsRefs {
    final manager = $$FormationPositionsTableTableManager(
      $_db,
      $_db.formationPositions,
    ).filter((f) => f.formationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _formationPositionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FormationsTableFilterComposer
    extends Composer<_$AppDb, $FormationsTable> {
  $$FormationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> gamesRefs(
    Expression<bool> Function($$GamesTableFilterComposer f) f,
  ) {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.formationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> formationPositionsRefs(
    Expression<bool> Function($$FormationPositionsTableFilterComposer f) f,
  ) {
    final $$FormationPositionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.formationPositions,
      getReferencedColumn: (t) => t.formationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationPositionsTableFilterComposer(
            $db: $db,
            $table: $db.formationPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FormationsTableOrderingComposer
    extends Composer<_$AppDb, $FormationsTable> {
  $$FormationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormationsTableAnnotationComposer
    extends Composer<_$AppDb, $FormationsTable> {
  $$FormationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => column,
  );

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> gamesRefs<T extends Object>(
    Expression<T> Function($$GamesTableAnnotationComposer a) f,
  ) {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.formationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> formationPositionsRefs<T extends Object>(
    Expression<T> Function($$FormationPositionsTableAnnotationComposer a) f,
  ) {
    final $$FormationPositionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.formationPositions,
          getReferencedColumn: (t) => t.formationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FormationPositionsTableAnnotationComposer(
                $db: $db,
                $table: $db.formationPositions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FormationsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $FormationsTable,
          Formation,
          $$FormationsTableFilterComposer,
          $$FormationsTableOrderingComposer,
          $$FormationsTableAnnotationComposer,
          $$FormationsTableCreateCompanionBuilder,
          $$FormationsTableUpdateCompanionBuilder,
          (Formation, $$FormationsTableReferences),
          Formation,
          PrefetchHooks Function({
            bool teamId,
            bool gamesRefs,
            bool formationPositionsRefs,
          })
        > {
  $$FormationsTableTableManager(_$AppDb db, $FormationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> playerCount = const Value.absent(),
              }) => FormationsCompanion(
                id: id,
                teamId: teamId,
                name: name,
                playerCount: playerCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int teamId,
                required String name,
                required int playerCount,
              }) => FormationsCompanion.insert(
                id: id,
                teamId: teamId,
                name: name,
                playerCount: playerCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FormationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                teamId = false,
                gamesRefs = false,
                formationPositionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (gamesRefs) db.games,
                    if (formationPositionsRefs) db.formationPositions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (teamId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.teamId,
                                    referencedTable: $$FormationsTableReferences
                                        ._teamIdTable(db),
                                    referencedColumn:
                                        $$FormationsTableReferences
                                            ._teamIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (gamesRefs)
                        await $_getPrefetchedData<
                          Formation,
                          $FormationsTable,
                          Game
                        >(
                          currentTable: table,
                          referencedTable: $$FormationsTableReferences
                              ._gamesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FormationsTableReferences(
                                db,
                                table,
                                p0,
                              ).gamesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.formationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (formationPositionsRefs)
                        await $_getPrefetchedData<
                          Formation,
                          $FormationsTable,
                          FormationPosition
                        >(
                          currentTable: table,
                          referencedTable: $$FormationsTableReferences
                              ._formationPositionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FormationsTableReferences(
                                db,
                                table,
                                p0,
                              ).formationPositionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.formationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FormationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $FormationsTable,
      Formation,
      $$FormationsTableFilterComposer,
      $$FormationsTableOrderingComposer,
      $$FormationsTableAnnotationComposer,
      $$FormationsTableCreateCompanionBuilder,
      $$FormationsTableUpdateCompanionBuilder,
      (Formation, $$FormationsTableReferences),
      Formation,
      PrefetchHooks Function({
        bool teamId,
        bool gamesRefs,
        bool formationPositionsRefs,
      })
    >;
typedef $$GamesTableCreateCompanionBuilder =
    GamesCompanion Function({
      Value<int> id,
      Value<DateTime?> startTime,
      Value<String?> opponent,
      Value<int?> currentShiftId,
      required int teamId,
      Value<bool> isArchived,
      Value<int> currentHalf,
      Value<int> gameTimeSeconds,
      Value<bool> isGameActive,
      Value<int?> formationId,
    });
typedef $$GamesTableUpdateCompanionBuilder =
    GamesCompanion Function({
      Value<int> id,
      Value<DateTime?> startTime,
      Value<String?> opponent,
      Value<int?> currentShiftId,
      Value<int> teamId,
      Value<bool> isArchived,
      Value<int> currentHalf,
      Value<int> gameTimeSeconds,
      Value<bool> isGameActive,
      Value<int?> formationId,
    });

final class $$GamesTableReferences
    extends BaseReferences<_$AppDb, $GamesTable, Game> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDb db) =>
      db.teams.createAlias($_aliasNameGenerator(db.games.teamId, db.teams.id));

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<int>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FormationsTable _formationIdTable(_$AppDb db) =>
      db.formations.createAlias(
        $_aliasNameGenerator(db.games.formationId, db.formations.id),
      );

  $$FormationsTableProcessedTableManager? get formationId {
    final $_column = $_itemColumn<int>('formation_id');
    if ($_column == null) return null;
    final manager = $$FormationsTableTableManager(
      $_db,
      $_db.formations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_formationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShiftsTable, List<Shift>> _shiftsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.shifts,
    aliasName: $_aliasNameGenerator(db.games.id, db.shifts.gameId),
  );

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlayerMetricsTable, List<PlayerMetric>>
  _playerMetricsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.playerMetrics,
    aliasName: $_aliasNameGenerator(db.games.id, db.playerMetrics.gameId),
  );

  $$PlayerMetricsTableProcessedTableManager get playerMetricsRefs {
    final manager = $$PlayerMetricsTableTableManager(
      $_db,
      $_db.playerMetrics,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playerMetricsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GamePlayersTable, List<GamePlayer>>
  _gamePlayersRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.gamePlayers,
    aliasName: $_aliasNameGenerator(db.games.id, db.gamePlayers.gameId),
  );

  $$GamePlayersTableProcessedTableManager get gamePlayersRefs {
    final manager = $$GamePlayersTableTableManager(
      $_db,
      $_db.gamePlayers,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gamePlayersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDb, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opponent => $composableBuilder(
    column: $table.opponent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentShiftId => $composableBuilder(
    column: $table.currentShiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentHalf => $composableBuilder(
    column: $table.currentHalf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gameTimeSeconds => $composableBuilder(
    column: $table.gameTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGameActive => $composableBuilder(
    column: $table.isGameActive,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FormationsTableFilterComposer get formationId {
    final $$FormationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formationId,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableFilterComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shiftsRefs(
    Expression<bool> Function($$ShiftsTableFilterComposer f) f,
  ) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playerMetricsRefs(
    Expression<bool> Function($$PlayerMetricsTableFilterComposer f) f,
  ) {
    final $$PlayerMetricsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerMetrics,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerMetricsTableFilterComposer(
            $db: $db,
            $table: $db.playerMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> gamePlayersRefs(
    Expression<bool> Function($$GamePlayersTableFilterComposer f) f,
  ) {
    final $$GamePlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gamePlayers,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamePlayersTableFilterComposer(
            $db: $db,
            $table: $db.gamePlayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableOrderingComposer extends Composer<_$AppDb, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opponent => $composableBuilder(
    column: $table.opponent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentShiftId => $composableBuilder(
    column: $table.currentShiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentHalf => $composableBuilder(
    column: $table.currentHalf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gameTimeSeconds => $composableBuilder(
    column: $table.gameTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGameActive => $composableBuilder(
    column: $table.isGameActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FormationsTableOrderingComposer get formationId {
    final $$FormationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formationId,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableOrderingComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GamesTableAnnotationComposer extends Composer<_$AppDb, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get opponent =>
      $composableBuilder(column: $table.opponent, builder: (column) => column);

  GeneratedColumn<int> get currentShiftId => $composableBuilder(
    column: $table.currentShiftId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentHalf => $composableBuilder(
    column: $table.currentHalf,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gameTimeSeconds => $composableBuilder(
    column: $table.gameTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGameActive => $composableBuilder(
    column: $table.isGameActive,
    builder: (column) => column,
  );

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FormationsTableAnnotationComposer get formationId {
    final $$FormationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formationId,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableAnnotationComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shiftsRefs<T extends Object>(
    Expression<T> Function($$ShiftsTableAnnotationComposer a) f,
  ) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playerMetricsRefs<T extends Object>(
    Expression<T> Function($$PlayerMetricsTableAnnotationComposer a) f,
  ) {
    final $$PlayerMetricsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerMetrics,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerMetricsTableAnnotationComposer(
            $db: $db,
            $table: $db.playerMetrics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> gamePlayersRefs<T extends Object>(
    Expression<T> Function($$GamePlayersTableAnnotationComposer a) f,
  ) {
    final $$GamePlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.gamePlayers,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamePlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.gamePlayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $GamesTable,
          Game,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (Game, $$GamesTableReferences),
          Game,
          PrefetchHooks Function({
            bool teamId,
            bool formationId,
            bool shiftsRefs,
            bool playerMetricsRefs,
            bool gamePlayersRefs,
          })
        > {
  $$GamesTableTableManager(_$AppDb db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<String?> opponent = const Value.absent(),
                Value<int?> currentShiftId = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> currentHalf = const Value.absent(),
                Value<int> gameTimeSeconds = const Value.absent(),
                Value<bool> isGameActive = const Value.absent(),
                Value<int?> formationId = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                startTime: startTime,
                opponent: opponent,
                currentShiftId: currentShiftId,
                teamId: teamId,
                isArchived: isArchived,
                currentHalf: currentHalf,
                gameTimeSeconds: gameTimeSeconds,
                isGameActive: isGameActive,
                formationId: formationId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> startTime = const Value.absent(),
                Value<String?> opponent = const Value.absent(),
                Value<int?> currentShiftId = const Value.absent(),
                required int teamId,
                Value<bool> isArchived = const Value.absent(),
                Value<int> currentHalf = const Value.absent(),
                Value<int> gameTimeSeconds = const Value.absent(),
                Value<bool> isGameActive = const Value.absent(),
                Value<int?> formationId = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                startTime: startTime,
                opponent: opponent,
                currentShiftId: currentShiftId,
                teamId: teamId,
                isArchived: isArchived,
                currentHalf: currentHalf,
                gameTimeSeconds: gameTimeSeconds,
                isGameActive: isGameActive,
                formationId: formationId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GamesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                teamId = false,
                formationId = false,
                shiftsRefs = false,
                playerMetricsRefs = false,
                gamePlayersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shiftsRefs) db.shifts,
                    if (playerMetricsRefs) db.playerMetrics,
                    if (gamePlayersRefs) db.gamePlayers,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (teamId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.teamId,
                                    referencedTable: $$GamesTableReferences
                                        ._teamIdTable(db),
                                    referencedColumn: $$GamesTableReferences
                                        ._teamIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (formationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.formationId,
                                    referencedTable: $$GamesTableReferences
                                        ._formationIdTable(db),
                                    referencedColumn: $$GamesTableReferences
                                        ._formationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shiftsRefs)
                        await $_getPrefetchedData<Game, $GamesTable, Shift>(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._shiftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(db, table, p0).shiftsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playerMetricsRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          PlayerMetric
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._playerMetricsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).playerMetricsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (gamePlayersRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          GamePlayer
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._gamePlayersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).gamePlayersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $GamesTable,
      Game,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (Game, $$GamesTableReferences),
      Game,
      PrefetchHooks Function({
        bool teamId,
        bool formationId,
        bool shiftsRefs,
        bool playerMetricsRefs,
        bool gamePlayersRefs,
      })
    >;
typedef $$ShiftsTableCreateCompanionBuilder =
    ShiftsCompanion Function({
      Value<int> id,
      required int gameId,
      required int startSeconds,
      Value<int?> endSeconds,
      Value<String?> notes,
      Value<int> actualSeconds,
    });
typedef $$ShiftsTableUpdateCompanionBuilder =
    ShiftsCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> startSeconds,
      Value<int?> endSeconds,
      Value<String?> notes,
      Value<int> actualSeconds,
    });

final class $$ShiftsTableReferences
    extends BaseReferences<_$AppDb, $ShiftsTable, Shift> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDb db) =>
      db.games.createAlias($_aliasNameGenerator(db.shifts.gameId, db.games.id));

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlayerShiftsTable, List<PlayerShift>>
  _playerShiftsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.playerShifts,
    aliasName: $_aliasNameGenerator(db.shifts.id, db.playerShifts.shiftId),
  );

  $$PlayerShiftsTableProcessedTableManager get playerShiftsRefs {
    final manager = $$PlayerShiftsTableTableManager(
      $_db,
      $_db.playerShifts,
    ).filter((f) => f.shiftId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playerShiftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShiftsTableFilterComposer extends Composer<_$AppDb, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startSeconds => $composableBuilder(
    column: $table.startSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endSeconds => $composableBuilder(
    column: $table.endSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualSeconds => $composableBuilder(
    column: $table.actualSeconds,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playerShiftsRefs(
    Expression<bool> Function($$PlayerShiftsTableFilterComposer f) f,
  ) {
    final $$PlayerShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerShifts,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerShiftsTableFilterComposer(
            $db: $db,
            $table: $db.playerShifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableOrderingComposer extends Composer<_$AppDb, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startSeconds => $composableBuilder(
    column: $table.startSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endSeconds => $composableBuilder(
    column: $table.endSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualSeconds => $composableBuilder(
    column: $table.actualSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShiftsTableAnnotationComposer extends Composer<_$AppDb, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startSeconds => $composableBuilder(
    column: $table.startSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endSeconds => $composableBuilder(
    column: $table.endSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get actualSeconds => $composableBuilder(
    column: $table.actualSeconds,
    builder: (column) => column,
  );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playerShiftsRefs<T extends Object>(
    Expression<T> Function($$PlayerShiftsTableAnnotationComposer a) f,
  ) {
    final $$PlayerShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playerShifts,
      getReferencedColumn: (t) => t.shiftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayerShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.playerShifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShiftsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ShiftsTable,
          Shift,
          $$ShiftsTableFilterComposer,
          $$ShiftsTableOrderingComposer,
          $$ShiftsTableAnnotationComposer,
          $$ShiftsTableCreateCompanionBuilder,
          $$ShiftsTableUpdateCompanionBuilder,
          (Shift, $$ShiftsTableReferences),
          Shift,
          PrefetchHooks Function({bool gameId, bool playerShiftsRefs})
        > {
  $$ShiftsTableTableManager(_$AppDb db, $ShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> startSeconds = const Value.absent(),
                Value<int?> endSeconds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> actualSeconds = const Value.absent(),
              }) => ShiftsCompanion(
                id: id,
                gameId: gameId,
                startSeconds: startSeconds,
                endSeconds: endSeconds,
                notes: notes,
                actualSeconds: actualSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int startSeconds,
                Value<int?> endSeconds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> actualSeconds = const Value.absent(),
              }) => ShiftsCompanion.insert(
                id: id,
                gameId: gameId,
                startSeconds: startSeconds,
                endSeconds: endSeconds,
                notes: notes,
                actualSeconds: actualSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ShiftsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, playerShiftsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (playerShiftsRefs) db.playerShifts],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable: $$ShiftsTableReferences
                                    ._gameIdTable(db),
                                referencedColumn: $$ShiftsTableReferences
                                    ._gameIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playerShiftsRefs)
                    await $_getPrefetchedData<Shift, $ShiftsTable, PlayerShift>(
                      currentTable: table,
                      referencedTable: $$ShiftsTableReferences
                          ._playerShiftsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ShiftsTableReferences(
                        db,
                        table,
                        p0,
                      ).playerShiftsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.shiftId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ShiftsTable,
      Shift,
      $$ShiftsTableFilterComposer,
      $$ShiftsTableOrderingComposer,
      $$ShiftsTableAnnotationComposer,
      $$ShiftsTableCreateCompanionBuilder,
      $$ShiftsTableUpdateCompanionBuilder,
      (Shift, $$ShiftsTableReferences),
      Shift,
      PrefetchHooks Function({bool gameId, bool playerShiftsRefs})
    >;
typedef $$PlayerShiftsTableCreateCompanionBuilder =
    PlayerShiftsCompanion Function({
      Value<int> id,
      required int shiftId,
      required int playerId,
      required String position,
    });
typedef $$PlayerShiftsTableUpdateCompanionBuilder =
    PlayerShiftsCompanion Function({
      Value<int> id,
      Value<int> shiftId,
      Value<int> playerId,
      Value<String> position,
    });

final class $$PlayerShiftsTableReferences
    extends BaseReferences<_$AppDb, $PlayerShiftsTable, PlayerShift> {
  $$PlayerShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDb db) => db.shifts.createAlias(
    $_aliasNameGenerator(db.playerShifts.shiftId, db.shifts.id),
  );

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<int>('shift_id')!;

    final manager = $$ShiftsTableTableManager(
      $_db,
      $_db.shifts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDb db) => db.players.createAlias(
    $_aliasNameGenerator(db.playerShifts.playerId, db.players.id),
  );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayerShiftsTableFilterComposer
    extends Composer<_$AppDb, $PlayerShiftsTable> {
  $$PlayerShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableFilterComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerShiftsTableOrderingComposer
    extends Composer<_$AppDb, $PlayerShiftsTable> {
  $$PlayerShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerShiftsTableAnnotationComposer
    extends Composer<_$AppDb, $PlayerShiftsTable> {
  $$PlayerShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftId,
      referencedTable: $db.shifts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.shifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerShiftsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $PlayerShiftsTable,
          PlayerShift,
          $$PlayerShiftsTableFilterComposer,
          $$PlayerShiftsTableOrderingComposer,
          $$PlayerShiftsTableAnnotationComposer,
          $$PlayerShiftsTableCreateCompanionBuilder,
          $$PlayerShiftsTableUpdateCompanionBuilder,
          (PlayerShift, $$PlayerShiftsTableReferences),
          PlayerShift,
          PrefetchHooks Function({bool shiftId, bool playerId})
        > {
  $$PlayerShiftsTableTableManager(_$AppDb db, $PlayerShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> shiftId = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<String> position = const Value.absent(),
              }) => PlayerShiftsCompanion(
                id: id,
                shiftId: shiftId,
                playerId: playerId,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int shiftId,
                required int playerId,
                required String position,
              }) => PlayerShiftsCompanion.insert(
                id: id,
                shiftId: shiftId,
                playerId: playerId,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayerShiftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftId = false, playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shiftId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shiftId,
                                referencedTable: $$PlayerShiftsTableReferences
                                    ._shiftIdTable(db),
                                referencedColumn: $$PlayerShiftsTableReferences
                                    ._shiftIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$PlayerShiftsTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$PlayerShiftsTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayerShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $PlayerShiftsTable,
      PlayerShift,
      $$PlayerShiftsTableFilterComposer,
      $$PlayerShiftsTableOrderingComposer,
      $$PlayerShiftsTableAnnotationComposer,
      $$PlayerShiftsTableCreateCompanionBuilder,
      $$PlayerShiftsTableUpdateCompanionBuilder,
      (PlayerShift, $$PlayerShiftsTableReferences),
      PlayerShift,
      PrefetchHooks Function({bool shiftId, bool playerId})
    >;
typedef $$PlayerMetricsTableCreateCompanionBuilder =
    PlayerMetricsCompanion Function({
      Value<int> id,
      required int playerId,
      required int gameId,
      required String metric,
      Value<int> value,
    });
typedef $$PlayerMetricsTableUpdateCompanionBuilder =
    PlayerMetricsCompanion Function({
      Value<int> id,
      Value<int> playerId,
      Value<int> gameId,
      Value<String> metric,
      Value<int> value,
    });

final class $$PlayerMetricsTableReferences
    extends BaseReferences<_$AppDb, $PlayerMetricsTable, PlayerMetric> {
  $$PlayerMetricsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDb db) => db.players.createAlias(
    $_aliasNameGenerator(db.playerMetrics.playerId, db.players.id),
  );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GamesTable _gameIdTable(_$AppDb db) => db.games.createAlias(
    $_aliasNameGenerator(db.playerMetrics.gameId, db.games.id),
  );

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayerMetricsTableFilterComposer
    extends Composer<_$AppDb, $PlayerMetricsTable> {
  $$PlayerMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerMetricsTableOrderingComposer
    extends Composer<_$AppDb, $PlayerMetricsTable> {
  $$PlayerMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerMetricsTableAnnotationComposer
    extends Composer<_$AppDb, $PlayerMetricsTable> {
  $$PlayerMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerMetricsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $PlayerMetricsTable,
          PlayerMetric,
          $$PlayerMetricsTableFilterComposer,
          $$PlayerMetricsTableOrderingComposer,
          $$PlayerMetricsTableAnnotationComposer,
          $$PlayerMetricsTableCreateCompanionBuilder,
          $$PlayerMetricsTableUpdateCompanionBuilder,
          (PlayerMetric, $$PlayerMetricsTableReferences),
          PlayerMetric,
          PrefetchHooks Function({bool playerId, bool gameId})
        > {
  $$PlayerMetricsTableTableManager(_$AppDb db, $PlayerMetricsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<int> value = const Value.absent(),
              }) => PlayerMetricsCompanion(
                id: id,
                playerId: playerId,
                gameId: gameId,
                metric: metric,
                value: value,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playerId,
                required int gameId,
                required String metric,
                Value<int> value = const Value.absent(),
              }) => PlayerMetricsCompanion.insert(
                id: id,
                playerId: playerId,
                gameId: gameId,
                metric: metric,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayerMetricsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false, gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$PlayerMetricsTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$PlayerMetricsTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable: $$PlayerMetricsTableReferences
                                    ._gameIdTable(db),
                                referencedColumn: $$PlayerMetricsTableReferences
                                    ._gameIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayerMetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $PlayerMetricsTable,
      PlayerMetric,
      $$PlayerMetricsTableFilterComposer,
      $$PlayerMetricsTableOrderingComposer,
      $$PlayerMetricsTableAnnotationComposer,
      $$PlayerMetricsTableCreateCompanionBuilder,
      $$PlayerMetricsTableUpdateCompanionBuilder,
      (PlayerMetric, $$PlayerMetricsTableReferences),
      PlayerMetric,
      PrefetchHooks Function({bool playerId, bool gameId})
    >;
typedef $$GamePlayersTableCreateCompanionBuilder =
    GamePlayersCompanion Function({
      Value<int> id,
      required int gameId,
      required int playerId,
      Value<bool> isPresent,
    });
typedef $$GamePlayersTableUpdateCompanionBuilder =
    GamePlayersCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> playerId,
      Value<bool> isPresent,
    });

final class $$GamePlayersTableReferences
    extends BaseReferences<_$AppDb, $GamePlayersTable, GamePlayer> {
  $$GamePlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDb db) => db.games.createAlias(
    $_aliasNameGenerator(db.gamePlayers.gameId, db.games.id),
  );

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDb db) => db.players.createAlias(
    $_aliasNameGenerator(db.gamePlayers.playerId, db.players.id),
  );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GamePlayersTableFilterComposer
    extends Composer<_$AppDb, $GamePlayersTable> {
  $$GamePlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPresent => $composableBuilder(
    column: $table.isPresent,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GamePlayersTableOrderingComposer
    extends Composer<_$AppDb, $GamePlayersTable> {
  $$GamePlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPresent => $composableBuilder(
    column: $table.isPresent,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GamePlayersTableAnnotationComposer
    extends Composer<_$AppDb, $GamePlayersTable> {
  $$GamePlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isPresent =>
      $composableBuilder(column: $table.isPresent, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GamePlayersTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $GamePlayersTable,
          GamePlayer,
          $$GamePlayersTableFilterComposer,
          $$GamePlayersTableOrderingComposer,
          $$GamePlayersTableAnnotationComposer,
          $$GamePlayersTableCreateCompanionBuilder,
          $$GamePlayersTableUpdateCompanionBuilder,
          (GamePlayer, $$GamePlayersTableReferences),
          GamePlayer,
          PrefetchHooks Function({bool gameId, bool playerId})
        > {
  $$GamePlayersTableTableManager(_$AppDb db, $GamePlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamePlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamePlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamePlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<bool> isPresent = const Value.absent(),
              }) => GamePlayersCompanion(
                id: id,
                gameId: gameId,
                playerId: playerId,
                isPresent: isPresent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int playerId,
                Value<bool> isPresent = const Value.absent(),
              }) => GamePlayersCompanion.insert(
                id: id,
                gameId: gameId,
                playerId: playerId,
                isPresent: isPresent,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GamePlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable: $$GamePlayersTableReferences
                                    ._gameIdTable(db),
                                referencedColumn: $$GamePlayersTableReferences
                                    ._gameIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$GamePlayersTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$GamePlayersTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GamePlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $GamePlayersTable,
      GamePlayer,
      $$GamePlayersTableFilterComposer,
      $$GamePlayersTableOrderingComposer,
      $$GamePlayersTableAnnotationComposer,
      $$GamePlayersTableCreateCompanionBuilder,
      $$GamePlayersTableUpdateCompanionBuilder,
      (GamePlayer, $$GamePlayersTableReferences),
      GamePlayer,
      PrefetchHooks Function({bool gameId, bool playerId})
    >;
typedef $$PlayerPositionTotalsTableCreateCompanionBuilder =
    PlayerPositionTotalsCompanion Function({
      Value<int> id,
      required int playerId,
      required String position,
      Value<int> totalSeconds,
    });
typedef $$PlayerPositionTotalsTableUpdateCompanionBuilder =
    PlayerPositionTotalsCompanion Function({
      Value<int> id,
      Value<int> playerId,
      Value<String> position,
      Value<int> totalSeconds,
    });

final class $$PlayerPositionTotalsTableReferences
    extends
        BaseReferences<
          _$AppDb,
          $PlayerPositionTotalsTable,
          PlayerPositionTotal
        > {
  $$PlayerPositionTotalsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDb db) => db.players.createAlias(
    $_aliasNameGenerator(db.playerPositionTotals.playerId, db.players.id),
  );

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayerPositionTotalsTableFilterComposer
    extends Composer<_$AppDb, $PlayerPositionTotalsTable> {
  $$PlayerPositionTotalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerPositionTotalsTableOrderingComposer
    extends Composer<_$AppDb, $PlayerPositionTotalsTable> {
  $$PlayerPositionTotalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerPositionTotalsTableAnnotationComposer
    extends Composer<_$AppDb, $PlayerPositionTotalsTable> {
  $$PlayerPositionTotalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => column,
  );

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayerPositionTotalsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $PlayerPositionTotalsTable,
          PlayerPositionTotal,
          $$PlayerPositionTotalsTableFilterComposer,
          $$PlayerPositionTotalsTableOrderingComposer,
          $$PlayerPositionTotalsTableAnnotationComposer,
          $$PlayerPositionTotalsTableCreateCompanionBuilder,
          $$PlayerPositionTotalsTableUpdateCompanionBuilder,
          (PlayerPositionTotal, $$PlayerPositionTotalsTableReferences),
          PlayerPositionTotal,
          PrefetchHooks Function({bool playerId})
        > {
  $$PlayerPositionTotalsTableTableManager(
    _$AppDb db,
    $PlayerPositionTotalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerPositionTotalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerPositionTotalsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlayerPositionTotalsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<int> totalSeconds = const Value.absent(),
              }) => PlayerPositionTotalsCompanion(
                id: id,
                playerId: playerId,
                position: position,
                totalSeconds: totalSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playerId,
                required String position,
                Value<int> totalSeconds = const Value.absent(),
              }) => PlayerPositionTotalsCompanion.insert(
                id: id,
                playerId: playerId,
                position: position,
                totalSeconds: totalSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayerPositionTotalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$PlayerPositionTotalsTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$PlayerPositionTotalsTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlayerPositionTotalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $PlayerPositionTotalsTable,
      PlayerPositionTotal,
      $$PlayerPositionTotalsTableFilterComposer,
      $$PlayerPositionTotalsTableOrderingComposer,
      $$PlayerPositionTotalsTableAnnotationComposer,
      $$PlayerPositionTotalsTableCreateCompanionBuilder,
      $$PlayerPositionTotalsTableUpdateCompanionBuilder,
      (PlayerPositionTotal, $$PlayerPositionTotalsTableReferences),
      PlayerPositionTotal,
      PrefetchHooks Function({bool playerId})
    >;
typedef $$FormationPositionsTableCreateCompanionBuilder =
    FormationPositionsCompanion Function({
      Value<int> id,
      required int formationId,
      required int index,
      required String positionName,
    });
typedef $$FormationPositionsTableUpdateCompanionBuilder =
    FormationPositionsCompanion Function({
      Value<int> id,
      Value<int> formationId,
      Value<int> index,
      Value<String> positionName,
    });

final class $$FormationPositionsTableReferences
    extends
        BaseReferences<_$AppDb, $FormationPositionsTable, FormationPosition> {
  $$FormationPositionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FormationsTable _formationIdTable(_$AppDb db) =>
      db.formations.createAlias(
        $_aliasNameGenerator(
          db.formationPositions.formationId,
          db.formations.id,
        ),
      );

  $$FormationsTableProcessedTableManager get formationId {
    final $_column = $_itemColumn<int>('formation_id')!;

    final manager = $$FormationsTableTableManager(
      $_db,
      $_db.formations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_formationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FormationPositionsTableFilterComposer
    extends Composer<_$AppDb, $FormationPositionsTable> {
  $$FormationPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get index => $composableBuilder(
    column: $table.index,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get positionName => $composableBuilder(
    column: $table.positionName,
    builder: (column) => ColumnFilters(column),
  );

  $$FormationsTableFilterComposer get formationId {
    final $$FormationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formationId,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableFilterComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormationPositionsTableOrderingComposer
    extends Composer<_$AppDb, $FormationPositionsTable> {
  $$FormationPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get index => $composableBuilder(
    column: $table.index,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get positionName => $composableBuilder(
    column: $table.positionName,
    builder: (column) => ColumnOrderings(column),
  );

  $$FormationsTableOrderingComposer get formationId {
    final $$FormationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formationId,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableOrderingComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormationPositionsTableAnnotationComposer
    extends Composer<_$AppDb, $FormationPositionsTable> {
  $$FormationPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get index =>
      $composableBuilder(column: $table.index, builder: (column) => column);

  GeneratedColumn<String> get positionName => $composableBuilder(
    column: $table.positionName,
    builder: (column) => column,
  );

  $$FormationsTableAnnotationComposer get formationId {
    final $$FormationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.formationId,
      referencedTable: $db.formations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FormationsTableAnnotationComposer(
            $db: $db,
            $table: $db.formations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FormationPositionsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $FormationPositionsTable,
          FormationPosition,
          $$FormationPositionsTableFilterComposer,
          $$FormationPositionsTableOrderingComposer,
          $$FormationPositionsTableAnnotationComposer,
          $$FormationPositionsTableCreateCompanionBuilder,
          $$FormationPositionsTableUpdateCompanionBuilder,
          (FormationPosition, $$FormationPositionsTableReferences),
          FormationPosition,
          PrefetchHooks Function({bool formationId})
        > {
  $$FormationPositionsTableTableManager(
    _$AppDb db,
    $FormationPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormationPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormationPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormationPositionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> formationId = const Value.absent(),
                Value<int> index = const Value.absent(),
                Value<String> positionName = const Value.absent(),
              }) => FormationPositionsCompanion(
                id: id,
                formationId: formationId,
                index: index,
                positionName: positionName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int formationId,
                required int index,
                required String positionName,
              }) => FormationPositionsCompanion.insert(
                id: id,
                formationId: formationId,
                index: index,
                positionName: positionName,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FormationPositionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({formationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (formationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.formationId,
                                referencedTable:
                                    $$FormationPositionsTableReferences
                                        ._formationIdTable(db),
                                referencedColumn:
                                    $$FormationPositionsTableReferences
                                        ._formationIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FormationPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $FormationPositionsTable,
      FormationPosition,
      $$FormationPositionsTableFilterComposer,
      $$FormationPositionsTableOrderingComposer,
      $$FormationPositionsTableAnnotationComposer,
      $$FormationPositionsTableCreateCompanionBuilder,
      $$FormationPositionsTableUpdateCompanionBuilder,
      (FormationPosition, $$FormationPositionsTableReferences),
      FormationPosition,
      PrefetchHooks Function({bool formationId})
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$FormationsTableTableManager get formations =>
      $$FormationsTableTableManager(_db, _db.formations);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$PlayerShiftsTableTableManager get playerShifts =>
      $$PlayerShiftsTableTableManager(_db, _db.playerShifts);
  $$PlayerMetricsTableTableManager get playerMetrics =>
      $$PlayerMetricsTableTableManager(_db, _db.playerMetrics);
  $$GamePlayersTableTableManager get gamePlayers =>
      $$GamePlayersTableTableManager(_db, _db.gamePlayers);
  $$PlayerPositionTotalsTableTableManager get playerPositionTotals =>
      $$PlayerPositionTotalsTableTableManager(_db, _db.playerPositionTotals);
  $$FormationPositionsTableTableManager get formationPositions =>
      $$FormationPositionsTableTableManager(_db, _db.formationPositions);
}
