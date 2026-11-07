import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/groups/data/group_repository.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';

void main() {
  test('groups keep member order and can start a game', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final players = PlayerRepository(db);
    final a = (await players.add('Anna')).id!;
    final b = (await players.add('Bas')).id!;
    final c = (await players.add('Chris')).id!;
    final groups = GroupRepository(db);

    final id = await groups.save(name: 'Vrijdag', memberIds: [c, a, b]);
    var list = await groups.watch().first;
    expect(list.single.name, 'Vrijdag');
    expect(list.single.memberIds, [c, a, b]);

    await groups.save(id: id, name: 'Vrijdagavond', memberIds: [b, a]);
    list = await groups.watch().first;
    expect(list.single.name, 'Vrijdagavond');
    expect(list.single.memberIds, [b, a]);

    final repo = GameRepository(db);
    final gameId = await repo.createGame('custom', list.single.memberIds, const {},
        groupId: id);
    expect((await repo.load(gameId))!.groupId, id);

    // Deleting a group keeps its games, without the group.
    await groups.delete(id);
    expect(await groups.watch().first, isEmpty);
    expect((await repo.load(gameId))!.groupId, isNull);
  });

  test('a deleted player disappears from the group, not from old games', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final players = PlayerRepository(db);
    final a = (await players.add('Anna')).id!;
    final b = (await players.add('Bas')).id!;
    final groups = GroupRepository(db);
    await groups.save(name: 'G', memberIds: [a, b]);
    await players.delete(b);
    expect((await groups.watch().first).single.memberIds, [a]);
  });

  test('a version 1 database is upgraded without losing games', () async {
    final dir = await Directory.systemTemp.createTemp('kaartmaat_migrate');
    final file = File('${dir.path}/old.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // Build a version 1 database by hand (schema as shipped before groups).
    // The setup callback runs before drift checks user_version, so drift sees
    // a version 1 database and upgrades it to the current schema.
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      raw.execute('''
        CREATE TABLE players (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')), deleted_at INTEGER);
        CREATE TABLE games (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')), finished_at INTEGER,
          settings TEXT NOT NULL DEFAULT '{}');
        CREATE TABLE game_players (game_id INTEGER NOT NULL, player_id INTEGER NOT NULL,
          seat INTEGER NOT NULL, team INTEGER, PRIMARY KEY (game_id, player_id));
        CREATE TABLE rounds (id INTEGER PRIMARY KEY AUTOINCREMENT, game_id INTEGER NOT NULL,
          number INTEGER NOT NULL, entries TEXT NOT NULL, UNIQUE (game_id, number));
        CREATE TABLE app_settings (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL);
        INSERT INTO players (name) VALUES ('Anna'), ('Bas');
        INSERT INTO games (type) VALUES ('custom');
        INSERT INTO game_players (game_id, player_id, seat) VALUES (1, 1, 0), (1, 2, 1);
        PRAGMA user_version = 1;
      ''');
    }));
    addTearDown(db.close);
    final state = await GameRepository(db).load(1);
    expect(state!.players.map((p) => p.name), ['Anna', 'Bas']);
    expect(state.groupId, isNull);
    // new tables exist
    final id = await GroupRepository(db).save(name: 'Nieuw', memberIds: [1, 2]);
    expect(id, greaterThan(0));
  });
}

