import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';

void main() {
  test('team game is stored per player but scored per team', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final players = PlayerRepository(db);
    final ids = [
      for (final n in ['Anna', 'Bas', 'Chris', 'Dora']) (await players.add(n)).id!,
    ];
    final repo = GameRepository(db);
    final gameId = await repo.createGame(
        'klaverjassen', ids, const KlaverjasRules().defaultSettings);

    Map<String, Object?> team(bool playing, int cards) =>
        {'playing': playing, 'pit': false, 'cards': cards};
    await repo.addRound(gameId, {
      'wij': team(true, 100),
      'zij': team(false, 62),
    });
    await repo.addRound(gameId, {
      'wij': team(true, 70), // nat
      'zij': team(false, 92),
    });

    final view = GameView((await repo.load(gameId))!);
    expect(view.config.participants, ['wij', 'zij']);
    expect(view.nameOf('wij'), 'Anna & Chris');
    expect(view.nameOf('zij'), 'Bas & Dora');
    expect(view.standings.map((s) => s.total).toList(), [224, 100]);
    expect(view.winners, ['zij']);
    // statistics credit both players of the winning team
    expect(view.winningPlayers, ['${ids[1]}', '${ids[3]}']);
  });
}
