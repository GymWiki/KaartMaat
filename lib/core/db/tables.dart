import 'package:drift/drift.dart';

@DataClassName('PlayerRow')
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 24)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft delete: finished games keep referencing the player.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('GroupRow')
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
}

@DataClassName('GroupMemberRow')
class GroupMembers extends Table {
  IntColumn get groupId =>
      integer().references(Groups, #id, onDelete: KeyAction.cascade)();
  IntColumn get playerId => integer().references(Players, #id)();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {groupId, playerId};
}

@DataClassName('GameRow')
class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get settings => text().withDefault(const Constant('{}'))();

  /// The saved card group this game was started from, if any.
  IntColumn get groupId =>
      integer().nullable().references(Groups, #id, onDelete: KeyAction.setNull)();
}

@DataClassName('GamePlayerRow')
class GamePlayers extends Table {
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  IntColumn get playerId => integer().references(Players, #id)();
  IntColumn get seat => integer()();
  IntColumn get team => integer().nullable()();

  @override
  Set<Column> get primaryKey => {gameId, playerId};
}

/// Totals are never stored: they are derived from these rows.
@DataClassName('RoundRow')
class Rounds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();

  /// JSON map of participantId to the game specific values.
  TextColumn get entries => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {gameId, number},
      ];
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
