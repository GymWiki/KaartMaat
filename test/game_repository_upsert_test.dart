import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';

void main() {
  late AppDatabase db;
  late GameRepository games;
  late int gameId;
  late List<int> ids;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    games = GameRepository(db);
    final players = PlayerRepository(db);
    ids = [(await players.add('A')).id!, (await players.add('B')).id!];
    gameId = await games.createGame('custom', ids, {});
  });
  tearDown(() => db.close());

  Map<String, Map<String, Object?>> pts(int a) => {
    '${ids[0]}': {'points': a},
    '${ids[1]}': {'points': 0},
  };

  test(
    'QA-02: quick repeated saves of one round never create duplicates',
    () async {
      // what a fast tapper does: save 1, 2, 3 ... without waiting in between
      await Future.wait([
        for (var i = 1; i <= 6; i++) games.upsertRound(gameId, 1, pts(i)),
      ]);
      final s = (await games.load(gameId))!;
      expect(s.rounds.length, 1);
      expect(s.rounds.single.entries['${ids[0]}'], {'points': 6});
    },
  );

  test('upsert returns the replaced entries, null for a new round', () async {
    expect(await games.upsertRound(gameId, 1, pts(1)), isNull);
    expect(await games.upsertRound(gameId, 1, pts(2)), pts(1));
    expect(await games.upsertRound(gameId, 2, pts(5)), isNull);
    expect((await games.load(gameId))!.rounds.map((r) => r.number), [1, 2]);
  });

  test('live queries see an upsert (no nested transaction)', () async {
    final seen = <int>[];
    final sub = games.watch(gameId).listen((s) => seen.add(s!.rounds.length));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await games.upsertRound(gameId, 1, pts(1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await games.upsertRound(gameId, 1, pts(2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(seen.first, 0);
    expect(seen.last, 1);
  });
}
