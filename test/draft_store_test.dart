import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

class _CountingStore extends DraftStore {
  _CountingStore(super.settings);
  final saved = <Map<String, Object?>>[];
  int cleared = 0;

  @override
  Future<void> save(int gameId, Map<String, Object?> draft) async => saved.add(draft);

  @override
  Future<void> clear(int gameId) async => cleared++;
}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  test('a draft survives a restart: save, load, clear', () async {
    final store = DraftStore(settings);
    expect(await store.load(1), isNull);

    await store.save(1, {'step': 'tricks', 'bids': [1, 0, 2], 'focus': 1});
    final loaded = await store.load(1);
    expect(loaded!['step'], 'tricks');
    expect(loaded['bids'], [1, 0, 2]);
    expect(await store.load(2), isNull); // per game

    await store.clear(1);
    expect(await store.load(1), isNull);
  });

  test('an unreadable draft is ignored instead of crashing', () async {
    await settings.set(DraftStore.key(1), '{not json');
    expect(await DraftStore(settings).load(1), isNull);
  });

  test('deleting a game removes its draft', () async {
    final a = (await PlayerRepository(db).add('A')).id!;
    final b = (await PlayerRepository(db).add('B')).id!;
    final games = GameRepository(db);
    final id = await games.createGame('custom', [a, b], const {});
    await DraftStore(settings).save(id, {'x': 1});

    await games.deleteGame(id);
    expect(await DraftStore(settings).load(id), isNull);
  });

  group('DraftSaver', () {
    const quick = Duration(milliseconds: 40);
    const wait = Duration(milliseconds: 200);

    test('waits for a pause in typing and saves only the last change', () async {
      final store = _CountingStore(settings);
      final saver = DraftSaver(store, 1, delay: quick);

      saver.schedule({'v': 1});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      saver.schedule({'v': 2});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      saver.schedule({'v': 3});
      expect(store.saved, isEmpty);

      await Future<void>.delayed(wait);
      expect(store.saved, [
        {'v': 3},
      ]);
    });

    test('flush saves at once (app goes to the background)', () async {
      final store = _CountingStore(settings);
      final saver = DraftSaver(store, 1, delay: quick);
      saver.schedule({'v': 1});
      await saver.flush();
      expect(store.saved, [
        {'v': 1},
      ]);
      await Future<void>.delayed(wait);
      expect(store.saved.length, 1); // the timer was cancelled
    });

    test('discard forgets a pending draft and clears the stored one', () async {
      final store = _CountingStore(settings);
      final saver = DraftSaver(store, 1, delay: quick);
      saver.schedule({'v': 1});
      await saver.discard();
      await Future<void>.delayed(wait);
      expect(store.saved, isEmpty);
      expect(store.cleared, 1);
    });
  });
}
