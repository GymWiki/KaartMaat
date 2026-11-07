import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
    tables: [Players, Games, GamePlayers, Rounds, AppSettings, Groups, GroupMembers])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'kaartmaat'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(groups);
            await m.createTable(groupMembers);
            await m.addColumn(games, games.groupId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> resetAll() => transaction(() async {
        await delete(rounds).go();
        await delete(gamePlayers).go();
        await delete(games).go();
        await delete(groupMembers).go();
        await delete(groups).go();
        await delete(players).go();
        await delete(appSettings).go();
      });
}
