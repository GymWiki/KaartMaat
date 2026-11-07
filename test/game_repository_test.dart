import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';

void main() {
  late AppDatabase db;
  late GameRepository games;
  late PlayerRepository players;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    games = GameRepository(db);
    players = PlayerRepository(db);
  });
  tearDown(() => db.close());

  test('game survives reload; corrections and undo recalc totals', () async {
    final a = (await players.add('Anna')).id!;
    final b = (await players.add('Bas')).id!;
    final id = await games.createGame('custom', [a, b], {'targetScore': 0});

    await games.addRound(id, {'$a': {'points': 10}, '$b': {'points': 5}});
    await games.addRound(id, {'$a': {'points': 1}, '$b': {'points': 20}});

    var state = (await games.load(id))!;
    expect(GameView(state).standings.first.participant, '$b');
    expect(state.isFinished, false);

    await games.updateRound(id, 2, {'$a': {'points': 100}, '$b': {'points': 0}});
    state = (await games.load(id))!;
    expect(GameView(state).standings.first.total, 110);

    await games.deleteLastRound(id);
    state = (await games.load(id))!;
    expect(state.rounds.length, 1);
    expect(await games.watchLastUnfinishedId().first, id);

    await games.finish(id);
    expect(await games.watchLastUnfinishedId().first, isNull);
    expect((await games.watchFinished().first).length, 1);
  });

  test('player names are unique, deleted players free the name', () async {
    final r = await players.add('Anna');
    expect((await players.add('anna ')).error, PlayerNameError.exists);
    expect((await players.add('  ')).error, PlayerNameError.empty);
    await players.delete(r.id!);
    expect((await players.add('Anna')).error, isNull);
  });
}
