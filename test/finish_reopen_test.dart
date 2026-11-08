import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';
import 'package:kaartmaat/features/stats/stats_calculator.dart';

void main() {
  late AppDatabase db;
  late GameRepository games;
  late List<int> ids;
  late int gid;

  Entries pts(int a, int b) => {
    '${ids[0]}': {'points': a},
    '${ids[1]}': {'points': b},
  };

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    games = GameRepository(db);
    final p = PlayerRepository(db);
    ids = [(await p.add('Anna')).id!, (await p.add('Bas')).id!];
    gid = await games.createGame('custom', ids, {});
    await games.addRound(gid, pts(10, 3));
  });
  tearDown(() => db.close());

  test('finishing twice keeps the first time and says so', () async {
    expect(await games.finish(gid), isTrue);
    final first = (await games.load(gid))!.finishedAt;
    expect(await games.finish(gid), isFalse);
    expect((await games.load(gid))!.finishedAt, first);
  });

  test(
    'finish, resume, edit, finish again: counted once, ranking follows the rounds',
    () async {
      await games.finish(gid);
      var stats = computeStats(await games.watchFinished().first);
      expect(stats.firstWhere((s) => s.name == 'Anna').wins, 1);

      await games.reopen(gid);
      expect((await games.load(gid))!.isFinished, isFalse);
      expect(await games.watchFinished().first, isEmpty);
      expect(await games.watchUnfinishedIds().first, [gid]);
      stats = computeStats(await games.watchFinished().first);
      expect(stats, isEmpty, reason: 'a resumed game counts nowhere');

      await games.updateRound(gid, 1, pts(1, 30)); // correct the round
      await games.finish(gid);
      final finished = await games.watchFinished().first;
      expect(finished.length, 1);
      stats = computeStats(finished);
      expect(stats.firstWhere((s) => s.name == 'Bas').wins, 1);
      expect(stats.firstWhere((s) => s.name == 'Anna').wins, 0);
      expect(stats.every((s) => s.played == 1), isTrue);
      expect(GameView(finished.single).winners, ['${ids[1]}']);
    },
  );

  test('reopening an unfinished game changes nothing', () async {
    await games.reopen(gid);
    expect((await games.load(gid))!.isFinished, isFalse);
  });
}
