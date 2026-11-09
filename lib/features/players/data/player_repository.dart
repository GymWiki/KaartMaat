import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/providers.dart';
import '../../../core/ui/avatars.dart' show avatarCount;
import '../../games/data/game_state.dart';

enum PlayerNameError { empty, exists }

class PlayerRepository {
  PlayerRepository(this.db);
  final AppDatabase db;

  Stream<List<PlayerRef>> watchActive() => (db.select(db.players)
        ..where((p) => p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.name.lower())]))
      .watch()
      .map((rows) => [
            for (final r in rows)
              PlayerRef(id: r.id, name: r.name, avatar: r.avatar),
          ]);

  /// When each player last took part in a game (the day the game was
  /// started), for ordering the player list: recent first. Derived from the
  /// games, nothing extra is stored.
  Stream<Map<int, DateTime>> watchLastPlayed() => db
      .customSelect(
        'SELECT gp.player_id AS player_id, MAX(g.created_at) AS last '
        'FROM game_players gp JOIN games g ON g.id = gp.game_id '
        'GROUP BY gp.player_id',
        readsFrom: {db.gamePlayers, db.games},
      )
      .watch()
      .map(
        (rows) => {
          for (final r in rows)
            r.read<int>('player_id'): DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('last') * 1000,
            ),
        },
      );

  /// Returns the new id, or the reason the name was refused.
  Future<({int? id, PlayerNameError? error})> add(String name) async {
    final error = await _check(name, null);
    if (error != null) return (id: null, error: error);
    final id = await db
        .into(db.players)
        .insert(PlayersCompanion.insert(name: name.trim()));
    // Spread the built-in avatars over new players.
    await setAvatar(id, id % avatarCount);
    return (id: id, error: null);
  }

  Future<PlayerNameError?> rename(int id, String name) async {
    final error = await _check(name, id);
    if (error != null) return error;
    await (db.update(db.players)..where((p) => p.id.equals(id)))
        .write(PlayersCompanion(name: Value(name.trim())));
    return null;
  }

  Future<void> setAvatar(int id, int avatar) =>
      (db.update(db.players)..where((p) => p.id.equals(id)))
          .write(PlayersCompanion(avatar: Value(avatar)));

  Future<void> delete(int id) =>
      (db.update(db.players)..where((p) => p.id.equals(id)))
          .write(PlayersCompanion(deletedAt: Value(DateTime.now())));

  Future<PlayerNameError?> _check(String name, int? ignoreId) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return PlayerNameError.empty;
    final active = await (db.select(db.players)
          ..where((p) => p.deletedAt.isNull()))
        .get();
    final clash = active.any((p) =>
        p.id != ignoreId && p.name.toLowerCase() == trimmed.toLowerCase());
    return clash ? PlayerNameError.exists : null;
  }
}

final playerRepositoryProvider =
    Provider((ref) => PlayerRepository(ref.watch(databaseProvider)));

final lastPlayedProvider = StreamProvider<Map<int, DateTime>>(
    (ref) => ref.watch(playerRepositoryProvider).watchLastPlayed());

final playersProvider = StreamProvider<List<PlayerRef>>(
    (ref) => ref.watch(playerRepositoryProvider).watchActive());
