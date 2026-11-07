import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/providers.dart';
import '../rules/game_rules.dart';
import 'game_state.dart';

class GameRepository {
  GameRepository(this.db);
  final AppDatabase db;

  Set<TableInfo> get _tables => {db.games, db.gamePlayers, db.rounds, db.players};

  Future<int> createGame(
    String type,
    List<int> playerIds,
    Map<String, Object?> settings,
  ) =>
      db.transaction(() async {
        final id = await db.into(db.games).insert(GamesCompanion.insert(
              type: type,
              settings: Value(jsonEncode(settings)),
            ));
        for (var seat = 0; seat < playerIds.length; seat++) {
          await db.into(db.gamePlayers).insert(GamePlayersCompanion.insert(
                gameId: id,
                playerId: playerIds[seat],
                seat: seat,
              ));
        }
        return id;
      });

  Future<GameState?> load(int id) async {
    final game = await (db.select(db.games)..where((g) => g.id.equals(id)))
        .getSingleOrNull();
    if (game == null) return null;

    final playerRows = await (db.select(db.gamePlayers).join([
      innerJoin(db.players, db.players.id.equalsExp(db.gamePlayers.playerId)),
    ])
          ..where(db.gamePlayers.gameId.equals(id))
          ..orderBy([OrderingTerm.asc(db.gamePlayers.seat)]))
        .get();
    final roundRows = await (db.select(db.rounds)
          ..where((r) => r.gameId.equals(id))
          ..orderBy([(r) => OrderingTerm.asc(r.number)]))
        .get();

    return GameState(
      id: game.id,
      type: game.type,
      createdAt: game.createdAt,
      finishedAt: game.finishedAt,
      settings: Map<String, Object?>.from(jsonDecode(game.settings) as Map),
      players: [
        for (final row in playerRows)
          PlayerRef(
            id: row.readTable(db.players).id,
            name: row.readTable(db.players).name,
          ),
      ],
      rounds: [
        for (final r in roundRows)
          RoundData(number: r.number, entries: _decodeEntries(r.entries)),
      ],
    );
  }

  Stream<GameState?> watch(int id) => db
      .customSelect('SELECT 1', readsFrom: _tables)
      .watch()
      .asyncMap((_) => load(id));

  /// Id of the most recently started unfinished game, if any.
  Stream<int?> watchLastUnfinishedId() => (db.select(db.games)
        ..where((g) => g.finishedAt.isNull())
        ..orderBy([
          (g) => OrderingTerm.desc(g.createdAt),
          (g) => OrderingTerm.desc(g.id),
        ])
        ..limit(1))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.first.id);

  /// Finished games, newest first.
  Stream<List<GameState>> watchFinished() => db
      .customSelect('SELECT 1', readsFrom: _tables)
      .watch()
      .asyncMap((_) async {
    final rows = await (db.select(db.games)
          ..where((g) => g.finishedAt.isNotNull())
          ..orderBy([
            (g) => OrderingTerm.desc(g.finishedAt),
            (g) => OrderingTerm.desc(g.id),
          ]))
        .get();
    final states = <GameState>[];
    for (final row in rows) {
      final s = await load(row.id);
      if (s != null) states.add(s);
    }
    return states;
  });

  Future<void> addRound(int gameId, Entries entries) => db.transaction(() async {
        final max = db.rounds.number.max();
        final last = await (db.selectOnly(db.rounds)
              ..addColumns([max])
              ..where(db.rounds.gameId.equals(gameId)))
            .map((r) => r.read(max))
            .getSingle();
        await db.into(db.rounds).insert(RoundsCompanion.insert(
              gameId: gameId,
              number: (last ?? 0) + 1,
              entries: jsonEncode(entries),
            ));
      });

  Future<void> updateRound(int gameId, int number, Entries entries) =>
      (db.update(db.rounds)
            ..where((r) => r.gameId.equals(gameId) & r.number.equals(number)))
          .write(RoundsCompanion(entries: Value(jsonEncode(entries))));

  Future<void> deleteLastRound(int gameId) => db.transaction(() async {
        final last = await (db.select(db.rounds)
              ..where((r) => r.gameId.equals(gameId))
              ..orderBy([(r) => OrderingTerm.desc(r.number)])
              ..limit(1))
            .getSingleOrNull();
        if (last != null) {
          await (db.delete(db.rounds)..where((r) => r.id.equals(last.id))).go();
        }
      });

  Future<void> finish(int gameId) =>
      (db.update(db.games)..where((g) => g.id.equals(gameId)))
          .write(GamesCompanion(finishedAt: Value(DateTime.now())));

  Future<void> deleteGame(int gameId) => db.transaction(() async {
        await (db.delete(db.rounds)..where((r) => r.gameId.equals(gameId))).go();
        await (db.delete(db.gamePlayers)..where((p) => p.gameId.equals(gameId)))
            .go();
        await (db.delete(db.games)..where((g) => g.id.equals(gameId))).go();
      });

  Entries _decodeEntries(String json) => {
        for (final e in (jsonDecode(json) as Map).entries)
          e.key as String: Map<String, Object?>.from(e.value as Map),
      };
}

final gameRepositoryProvider =
    Provider((ref) => GameRepository(ref.watch(databaseProvider)));

final gameStateProvider = StreamProvider.family<GameState?, int>(
    (ref, id) => ref.watch(gameRepositoryProvider).watch(id));

final lastUnfinishedIdProvider = StreamProvider<int?>(
    (ref) => ref.watch(gameRepositoryProvider).watchLastUnfinishedId());

final finishedGamesProvider = StreamProvider<List<GameState>>(
    (ref) => ref.watch(gameRepositoryProvider).watchFinished());
