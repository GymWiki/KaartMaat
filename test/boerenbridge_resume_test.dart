import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';

void main() {
  test('open Boerenbridge round survives an app restart', () async {
    final dir = await Directory.systemTemp.createTemp('kaartmaat_test');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // Session 1: bids entered, app "killed" before the tricks.
    var db = AppDatabase(NativeDatabase(file));
    var players = PlayerRepository(db);
    final ids = [
      for (final n in ['A', 'B', 'C']) (await players.add(n)).id!,
    ];
    final settings = const BoerenbridgeRules().defaultSettings;
    final gameId =
        await GameRepository(db).createGame('boerenbridge', ids, settings);
    await GameRepository(db).addRound(gameId, {
      '${ids[0]}': {'bid': 1},
      '${ids[1]}': {'bid': 0},
      '${ids[2]}': {'bid': 0},
    });
    await db.close();

    // Session 2: reopen the same file.
    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final repo = GameRepository(db);
    expect(await repo.watchLastUnfinishedId().first, gameId);

    var view = GameView((await repo.load(gameId))!);
    expect(view.openRound?.number, 1);
    expect(view.nextRoundNumber, 1);
    expect(view.standings.every((s) => s.total == 0), true);

    // Tricks entered after the restart complete the same round.
    await repo.updateRound(gameId, 1, {
      '${ids[0]}': {'bid': 1, 'tricks': 1},
      '${ids[1]}': {'bid': 0, 'tricks': 0},
      '${ids[2]}': {'bid': 0, 'tricks': 0},
    });
    view = GameView((await repo.load(gameId))!);
    expect(view.openRound, isNull);
    expect(view.nextRoundNumber, 2);
    expect(view.standings.first.total, 15);

    // Correcting round 1 recalculates everything.
    await repo.updateRound(gameId, 1, {
      '${ids[0]}': {'bid': 1, 'tricks': 0},
      '${ids[1]}': {'bid': 0, 'tricks': 1},
      '${ids[2]}': {'bid': 0, 'tricks': 0},
    });
    view = GameView((await repo.load(gameId))!);
    expect(view.standings.map((s) => s.total).toList(), [10, -5, -5]);
  });
}
