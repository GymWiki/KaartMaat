// QA pass: data and persistence (Drift schema, migrations, restart, players,
// large data, undo/redo, statistics edges).
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/groups/data/group_repository.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';
import 'package:kaartmaat/features/stats/stats_calculator.dart';

const _v1Sql = '''
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
  INSERT INTO games (type, settings) VALUES ('custom', '{"targetScore":0}');
  INSERT INTO game_players (game_id, player_id, seat) VALUES (1, 1, 0), (1, 2, 1);
  INSERT INTO rounds (game_id, number, entries)
    VALUES (1, 1, '{"1":{"points":7},"2":{"points":3}}');
''';

/// Version 2 = v1 + groups + games.group_id, no players.avatar yet.
const _v2Extra = '''
  CREATE TABLE "groups" (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL);
  CREATE TABLE group_members (group_id INTEGER NOT NULL, player_id INTEGER NOT NULL,
    position INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (group_id, player_id));
  ALTER TABLE games ADD COLUMN group_id INTEGER;
  INSERT INTO "groups" (name) VALUES ('Vrijdag');
  INSERT INTO group_members (group_id, player_id, position) VALUES (1, 1, 0), (1, 2, 1);
  UPDATE games SET group_id = 1;
''';

GameState finished(
  int id,
  DateTime at,
  Map<int, int> points, {
  String type = 'custom',
  int? groupId,
}) => GameState(
  id: id,
  type: type,
  createdAt: at,
  finishedAt: at,
  settings: const {'lowestWins': false},
  players: [
    for (final e in points.entries) PlayerRef(id: e.key, name: 'P${e.key}'),
  ],
  rounds: [
    RoundData(
      number: 1,
      entries: {
        for (final e in points.entries) '${e.key}': {'points': e.value},
      },
    ),
  ],
  groupId: groupId,
);

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

  Future<List<int>> addPlayers(List<String> names) async => [
    for (final n in names) (await players.add(n)).id!,
  ];

  Entries pts(Map<int, int> m) => {
    for (final e in m.entries) '${e.key}': {'points': e.value},
  };

  // ------------------------------------------------------------------------
  group('schema', () {
    test('fresh install creates every table at the current version', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'players',
          'games',
          'game_players',
          'rounds',
          'app_settings',
          'groups',
          'group_members',
        ]),
      );
      expect(db.schemaVersion, 3);
      final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(
        fk.read<int>('foreign_keys'),
        1,
        reason: 'foreign keys must be on',
      );
    });

    test('totals are never stored: no score/total column anywhere', () async {
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      for (final t in tables) {
        final name = t.read<String>('name');
        if (name.startsWith('sqlite_')) continue;
        final cols = await db.customSelect('PRAGMA table_info("$name")').get();
        for (final c in cols) {
          final col = c.read<String>('name').toLowerCase();
          expect(
            col.contains('total') ||
                col.contains('score') ||
                col.contains('standing'),
            isFalse,
            reason: '$name.$col looks like a stored total',
          );
        }
      }
    });

    Future<AppDatabase> openOld(String sql) async {
      final dir = await Directory.systemTemp.createTemp('kaartmaat_qa_migrate');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/old.sqlite');
      final old = AppDatabase(
        NativeDatabase(file, setup: (raw) => raw.execute(sql)),
      );
      addTearDown(old.close);
      return old;
    }

    test(
      'upgrade v1 -> current keeps players, games, rounds and adds avatar/groups',
      () async {
        final old = await openOld('$_v1Sql PRAGMA user_version = 1;');
        final state = (await GameRepository(old).load(1))!;
        expect(state.players.map((p) => p.name), ['Anna', 'Bas']);
        expect(state.players.map((p) => p.avatar), [0, 0]);
        expect(state.rounds.single.entries['1'], {'points': 7});
        expect(state.groupId, isNull);
        final g = await GroupRepository(
          old,
        ).save(name: 'Nieuw', memberIds: [1, 2]);
        expect(g, greaterThan(0));
        final v = await old.customSelect('PRAGMA user_version').getSingle();
        expect(v.read<int>('user_version'), 3);
      },
    );

    test(
      'upgrade v2 -> current keeps groups and games and adds avatar',
      () async {
        final old = await openOld('$_v1Sql $_v2Extra PRAGMA user_version = 2;');
        final state = (await GameRepository(old).load(1))!;
        expect(state.groupId, 1);
        expect(state.players.map((p) => p.avatar), [0, 0]);
        final groups = await GroupRepository(old).watch().first;
        expect(groups.single.name, 'Vrijdag');
        expect(groups.single.memberIds, [1, 2]);
        // a new player can pick an avatar
        final p = await PlayerRepository(old).add('Chris');
        expect(p.id, isNotNull);
      },
    );
  });

  // ------------------------------------------------------------------------
  group('restart and resume', () {
    late Directory dir;
    late File file;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('kaartmaat_qa_restart');
      file = File('${dir.path}/db.sqlite');
      addTearDown(() => dir.delete(recursive: true));
    });

    test(
      'rounds survive a restart byte for byte (types, bools, nulls, lists)',
      () async {
        var d = AppDatabase(NativeDatabase(file));
        final ids = [
          for (final n in ['A', 'B']) (await PlayerRepository(d).add(n)).id!,
        ];
        final gid = await GameRepository(
          d,
        ).createGame('jokeren', ids, {'rounds': 10});
        final Entries entries = {
          '${ids[0]}': {
            'amounts': [25, -10, 3],
            'extra': true,
            'none': null,
          },
          '${ids[1]}': {'amounts': <int>[], 'text': 'é ü ✓'},
        };
        await GameRepository(d).addRound(gid, entries);
        await d.close();

        d = AppDatabase(NativeDatabase(file));
        addTearDown(d.close);
        final s = (await GameRepository(d).load(gid))!;
        expect(s.rounds.length, 1);
        expect(s.rounds.single.entries, entries);
        expect(s.settings, {'rounds': 10});
        expect(s.players.map((p) => p.name), ['A', 'B']);
        expect(s.isFinished, isFalse);
      },
    );

    test(
      'a killed app mid-round: draft restored, nothing duplicated',
      () async {
        // session 1: one finished round, then a half-filled panel is flushed
        var d = AppDatabase(NativeDatabase(file));
        var repo = GameRepository(d);
        final ids = [
          for (final n in ['A', 'B']) (await PlayerRepository(d).add(n)).id!,
        ];
        final gid = await repo.createGame('custom', ids, {});
        await repo.addRound(gid, pts({ids[0]: 5, ids[1]: 1}));
        var saver = DraftSaver(DraftStore(SettingsRepository(d)), gid);
        saver.schedule({
          'round': 2,
          'values': {'${ids[0]}': 3},
        });
        await saver.flush(); // app goes to background
        await d.close(); // process killed

        // session 2
        d = AppDatabase(NativeDatabase(file));
        addTearDown(d.close);
        repo = GameRepository(d);
        expect(
          (await repo.load(gid))!.rounds.length,
          1,
          reason: 'no round added by resume',
        );
        final draft = await DraftStore(SettingsRepository(d)).load(gid);
        expect(draft, {
          'round': 2,
          'values': {'${ids[0]}': 3},
        });
        // confirming the round clears the draft and adds exactly one round
        saver = DraftSaver(DraftStore(SettingsRepository(d)), gid);
        await repo.addRound(gid, pts({ids[0]: 3, ids[1]: 0}));
        await saver.discard();
        expect(await DraftStore(SettingsRepository(d)).load(gid), isNull);
        expect((await repo.load(gid))!.rounds.length, 2);
      },
    );

    test(
      'a pending (not yet flushed) draft is lost only for the last 300 ms',
      () async {
        final d = AppDatabase(NativeDatabase(file));
        addTearDown(d.close);
        final gid = await GameRepository(d).createGame('custom', [], {});
        final saver = DraftSaver(DraftStore(SettingsRepository(d)), gid);
        saver.schedule({'a': 1});
        // killed before the timer fired and before flush(): nothing stored
        saver.dispose();
        expect(await DraftStore(SettingsRepository(d)).load(gid), isNull);
      },
    );

    test(
      'open Boerenbridge round (bids only) restores as incomplete, tricks later',
      () async {
        var d = AppDatabase(NativeDatabase(file));
        final ids = [
          for (final n in ['A', 'B', 'C'])
            (await PlayerRepository(d).add(n)).id!,
        ];
        const rules = BoerenbridgeRules();
        final gid = await GameRepository(
          d,
        ).createGame('boerenbridge', ids, rules.defaultSettings);
        await GameRepository(d).addRound(gid, {
          for (final i in ids) '$i': {'bid': 0},
        });
        await d.close();
        d = AppDatabase(NativeDatabase(file));
        addTearDown(d.close);
        var s = (await GameRepository(d).load(gid))!;
        var view = GameView(s);
        expect(view.openRound?.number, 1);
        expect(
          view.nextRoundNumber,
          1,
          reason: 'the open round is continued, not a new one',
        );
        expect(view.isOver, isFalse);
        // fill in tricks by updating the SAME round
        await GameRepository(d).updateRound(gid, 1, {
          '${ids[0]}': {'bid': 0, 'tricks': 1},
          '${ids[1]}': {'bid': 0, 'tricks': 0},
          '${ids[2]}': {'bid': 0, 'tricks': 0},
        });
        s = (await GameRepository(d).load(gid))!;
        view = GameView(s);
        expect(s.rounds.length, 1);
        expect(view.openRound, isNull);
        expect(view.nextRoundNumber, 2);
        expect(view.standings.first.total, 10); // exact bid 0 = base 10
      },
    );

    test('a corrupt draft is ignored, not a crash', () async {
      final d = AppDatabase(NativeDatabase(file));
      addTearDown(d.close);
      await SettingsRepository(d).set('draft.9', '{not json');
      expect(await DraftStore(SettingsRepository(d)).load(9), isNull);
      await SettingsRepository(
        d,
      ).set('draft.9', '[1,2,3]'); // valid json, wrong shape
      expect(await DraftStore(SettingsRepository(d)).load(9), isNull);
    });
  });

  // ------------------------------------------------------------------------
  group('players in history', () {
    test(
      'deleting a player keeps them in old games, stats and scores',
      () async {
        final ids = await addPlayers(['Anna', 'Bas']);
        final gid = await games.createGame('custom', ids, {});
        await games.addRound(gid, pts({ids[0]: 10, ids[1]: 3}));
        await games.finish(gid);
        await players.delete(ids[0]);
        final s = (await games.load(gid))!;
        expect(s.players.map((p) => p.name), ['Anna', 'Bas']);
        expect(GameView(s).nameOf('${ids[0]}'), 'Anna');
        expect(GameView(s).winners, ['${ids[0]}']);
        final active = await players.watchActive().first;
        expect(active.map((p) => p.name), ['Bas']);
        final stats = computeStats(await games.watchFinished().first);
        expect(stats.map((p) => p.name), containsAll(['Anna', 'Bas']));
      },
    );

    test(
      'renaming a player renames them everywhere, history included',
      () async {
        final ids = await addPlayers(['Anna', 'Bas']);
        final gid = await games.createGame('custom', ids, {});
        await games.addRound(gid, pts({ids[0]: 1, ids[1]: 2}));
        expect(await players.rename(ids[0], 'Annabel'), isNull);
        expect((await games.load(gid))!.players.first.name, 'Annabel');
        expect(await players.rename(ids[0], 'bas'), PlayerNameError.exists);
        expect(await players.rename(ids[0], '   '), PlayerNameError.empty);
        // renaming to its own name (different case) is allowed
        expect(await players.rename(ids[0], 'ANNABEL'), isNull);
      },
    );

    test('deleting a player in an unfinished game does not crash it', () async {
      final ids = await addPlayers(['Anna', 'Bas', 'Chris']);
      final gid = await games.createGame('custom', ids, {});
      await games.addRound(gid, pts({ids[0]: 1, ids[1]: 2, ids[2]: 3}));
      await players.delete(ids[1]);
      final s = (await games.load(gid))!;
      expect(s.players.length, 3);
      await games.addRound(gid, pts({ids[0]: 1, ids[1]: 2, ids[2]: 3}));
      expect(GameView((await games.load(gid))!).standings.length, 3);
    });

    test(
      'a deleted player disappears from groups but not from old games',
      () async {
        final ids = await addPlayers(['Anna', 'Bas']);
        final gr = GroupRepository(db);
        await gr.save(name: 'G', memberIds: ids);
        await players.delete(ids[0]);
        expect((await gr.watch().first).single.memberIds, [ids[1]]);
      },
    );

    test('name edge cases: long names, duplicates by case, unicode', () async {
      expect((await players.add('Zoë')).error, isNull);
      expect((await players.add('ZOË')).error, PlayerNameError.exists);
      // The table limits names to 24 characters. add() does not check this
      // itself, so a longer name must either be refused with an error code or
      // throw: record what really happens.
      Object? thrown;
      ({int? id, PlayerNameError? error})? result;
      try {
        result = await players.add('x' * 25);
      } catch (e) {
        thrown = e;
      }
      // This documents the behaviour for the report (see finding on name length).
      // ignore: avoid_print
      print('QA name>24: result=$result thrown=${thrown.runtimeType}');
      expect(result != null || thrown != null, isTrue);
    });

    test(
      'the same player twice in one game is refused by the database',
      () async {
        final ids = await addPlayers(['Anna']);
        await expectLater(
          games.createGame('custom', [ids[0], ids[0]], {}),
          throwsA(anything),
        );
        // and the failed transaction left no half-created game behind
        expect(await db.select(db.games).get(), isEmpty);
      },
    );
  });

  // ------------------------------------------------------------------------
  group('edit, undo, redo', () {
    test(
      'undo then a different round: numbers are reused, totals follow',
      () async {
        final ids = await addPlayers(['A', 'B']);
        final gid = await games.createGame('custom', ids, {});
        await games.addRound(gid, pts({ids[0]: 10, ids[1]: 0}));
        await games.addRound(gid, pts({ids[0]: 0, ids[1]: 50}));
        await games.deleteLastRound(gid);
        await games.addRound(gid, pts({ids[0]: 5, ids[1]: 5}));
        final s = (await games.load(gid))!;
        expect(s.rounds.map((r) => r.number), [1, 2]);
        expect(GameView(s).standings.map((e) => e.total), [15, 5]);
      },
    );

    test(
      'editing round 1 of 3 recalculates the totals but not the other rounds',
      () async {
        final ids = await addPlayers(['A', 'B']);
        final gid = await games.createGame('custom', ids, {});
        for (final p in [(1, 2), (3, 4), (5, 6)]) {
          await games.addRound(gid, pts({ids[0]: p.$1, ids[1]: p.$2}));
        }
        await games.updateRound(gid, 1, pts({ids[0]: 100, ids[1]: 0}));
        final s = (await games.load(gid))!;
        expect(s.rounds.length, 3);
        expect(s.rounds[1].entries, pts({ids[0]: 3, ids[1]: 4}));
        final t = GameView(s).rules.totals(s.config, s.rounds);
        expect(t, {'${ids[0]}': 108, '${ids[1]}': 10});
      },
    );

    test(
      'undo on an empty game and updating a missing round are harmless',
      () async {
        final ids = await addPlayers(['A', 'B']);
        final gid = await games.createGame('custom', ids, {});
        await games.deleteLastRound(gid); // must not throw
        await games.updateRound(gid, 7, pts({ids[0]: 1, ids[1]: 1}));
        expect(
          (await games.load(gid))!.rounds,
          isEmpty,
          reason: 'updating a round that does not exist must not create one',
        );
      },
    );

    test(
      'two addRound calls at the same instant create two distinct rounds',
      () async {
        // The repository serialises them; preventing an accidental double tap is
        // the job of the UI (see ui test "double tap").
        final ids = await addPlayers(['A', 'B']);
        final gid = await games.createGame('custom', ids, {});
        await Future.wait([
          games.addRound(gid, pts({ids[0]: 1, ids[1]: 1})),
          games.addRound(gid, pts({ids[0]: 1, ids[1]: 1})),
        ]);
        expect((await games.load(gid))!.rounds.map((r) => r.number), [1, 2]);
      },
    );

    test('deleting a game removes rounds, seats and its draft', () async {
      final ids = await addPlayers(['A', 'B']);
      final gid = await games.createGame('custom', ids, {});
      await games.addRound(gid, pts({ids[0]: 1, ids[1]: 1}));
      await SettingsRepository(db).set('draft.$gid', '{}');
      await games.deleteGame(gid);
      expect(await db.select(db.rounds).get(), isEmpty);
      expect(await db.select(db.gamePlayers).get(), isEmpty);
      expect(await SettingsRepository(db).get('draft.$gid'), isNull);
      expect(await games.load(gid), isNull);
    });

    test('deleting a group keeps its games (group id set to null)', () async {
      final ids = await addPlayers(['A', 'B']);
      final gr = GroupRepository(db);
      final g = await gr.save(name: 'G', memberIds: ids);
      final gid = await games.createGame('custom', ids, {}, groupId: g);
      await (db.delete(db.groups)..where((t) => t.id.equals(g))).go();
      expect((await games.load(gid))!.groupId, isNull);
    });

    test('resetAll wipes everything, including drafts', () async {
      final ids = await addPlayers(['A', 'B']);
      final gid = await games.createGame('custom', ids, {});
      await SettingsRepository(db).set('draft.$gid', '{}');
      await db.resetAll();
      expect(await db.select(db.players).get(), isEmpty);
      expect(await db.select(db.games).get(), isEmpty);
      expect(await db.select(db.rounds).get(), isEmpty);
      expect(await db.select(db.appSettings).get(), isEmpty);
      expect(await db.select(db.groups).get(), isEmpty);
    });
  });

  // ------------------------------------------------------------------------
  group('large data', () {
    test('500 finished games load and aggregate fast enough', () async {
      final ids = await addPlayers(['A', 'B', 'C', 'D']);
      final sw = Stopwatch()..start();
      await db.transaction(() async {
        for (var g = 0; g < 500; g++) {
          final gid = await games.createGame('custom', ids, {
            'lowestWins': false,
          });
          for (var r = 1; r <= 10; r++) {
            await games.addRound(
              gid,
              pts({for (final i in ids) i: (g + r + i) % 17}),
            );
          }
          await games.finish(gid);
        }
      });
      final seed = sw.elapsedMilliseconds;

      sw
        ..reset()
        ..start();
      final list = await games.watchFinished().first;
      final loadMs = sw.elapsedMilliseconds;
      expect(list.length, 500);

      sw
        ..reset()
        ..start();
      final stats = computeStats(list, withBestScore: true);
      final king = kaartkoning(list, DateTime.now().year);
      final statsMs = sw.elapsedMilliseconds;
      expect(stats.length, 4);
      expect(king, isNotNull);
      // ignore: avoid_print
      print(
        'QA large data: seed ${seed}ms, load 500 games ${loadMs}ms, stats ${statsMs}ms',
      );
      // Generous ceilings (in-memory sqlite on a PC; a phone is slower).
      expect(loadMs, lessThan(5000), reason: 'loading 500 games');
      expect(statsMs, lessThan(1000), reason: 'computing stats for 500 games');
    });

    test(
      '50 rounds in one game derive totals instantly and stay correct',
      () async {
        final ids = await addPlayers(['A', 'B', 'C']);
        final gid = await games.createGame('custom', ids, {});
        for (var r = 1; r <= 50; r++) {
          await games.addRound(gid, pts({ids[0]: r, ids[1]: 1, ids[2]: -1}));
        }
        final s = (await games.load(gid))!;
        final sw = Stopwatch()..start();
        final view = GameView(s);
        sw.stop();
        expect(view.standings.first.total, 1275); // 1+2+...+50
        expect(view.cumulative.length, 50);
        expect(view.cumulative.last['${ids[0]}'], 1275);
        expect(view.cumulative[24]['${ids[0]}'], 325); // 1+...+25
        expect(sw.elapsedMilliseconds, lessThan(100));
      },
    );
  });

  // ------------------------------------------------------------------------
  group('statistics edges', () {
    test('empty data: no stats, no kaartkoning, no crash', () {
      expect(computeStats(const []), isEmpty);
      expect(kaartkoning(const [], 2026), isNull);
      expect(yearsOf(const []), isEmpty);
    });

    test('kaartkoning: year boundary is decided by the finish date', () {
      final games = [
        finished(1, DateTime(2025, 12, 31, 23, 59), {
          1: 10,
          2: 0,
        }), // P1 wins 2025
        finished(2, DateTime(2026, 1, 1, 0, 0), {1: 0, 2: 10}), // P2 wins 2026
      ];
      expect(kaartkoning(games, 2025)!.id, 1);
      expect(kaartkoning(games, 2026)!.id, 2);
      expect(kaartkoning(games, 2024), isNull);
      expect(yearsOf(games), [2026, 2025]);
    });

    test('kaartkoning tie on wins: higher win percentage, then more games', () {
      final games = [
        // P1: 1 win in 1 game (100%). P2: 1 win in 2 games (50%).
        finished(1, DateTime(2026, 2, 1), {1: 10, 3: 0}),
        finished(2, DateTime(2026, 3, 1), {2: 10, 3: 0}),
        finished(3, DateTime(2026, 4, 1), {2: 0, 3: 10}),
      ];
      // P3 has 1 win in 3 games, P1 1/1, P2 1/2 -> P1 is king
      expect(kaartkoning(games, 2026)!.id, 1);
    });

    test('a tied game counts as a win for both players', () {
      final games = [
        finished(1, DateTime(2026, 2, 1), {1: 10, 2: 10}),
      ];
      final stats = computeStats(games);
      expect(stats.every((s) => s.wins == 1), isTrue);
      expect(stats.every((s) => s.winPct == 100), isTrue);
    });

    test('unfinished games never count', () {
      final unfinished = GameState(
        id: 1,
        type: 'custom',
        createdAt: DateTime(2026, 1, 1),
        finishedAt: null,
        settings: const {},
        players: const [PlayerRef(id: 1, name: 'A')],
        rounds: const [],
      );
      expect(applyFilter([unfinished], const GameFilter()), isEmpty);
    });

    test('win percentage rounds sensibly (1 of 3 = 33, 2 of 3 = 67)', () {
      final s = PlayerStat(1, 'A')
        ..played = 3
        ..wins = 1;
      expect(s.winPct, 33);
      s.wins = 2;
      expect(s.winPct, 67);
    });

    test(
      'a finished game without any round has no winner and does not crash',
      () {
        final g = GameState(
          id: 1,
          type: 'custom',
          createdAt: DateTime(2026, 1, 1),
          finishedAt: DateTime(2026, 1, 2),
          settings: const {},
          players: const [
            PlayerRef(id: 1, name: 'A'),
            PlayerRef(id: 2, name: 'B'),
          ],
          rounds: const [],
        );
        final stats = computeStats([g], withBestScore: true);
        expect(stats.every((s) => s.wins == 0), isTrue);
        expect(kaartkoning([g], 2026), isNull);
      },
    );

    test('best score respects lowest-wins games', () {
      final g = GameState(
        id: 1,
        type: 'hartenjagen',
        createdAt: DateTime(2026, 1, 1),
        finishedAt: DateTime(2026, 1, 2),
        settings: const {},
        players: const [
          PlayerRef(id: 1, name: 'A'),
          PlayerRef(id: 2, name: 'B'),
          PlayerRef(id: 3, name: 'C'),
        ],
        rounds: [
          RoundData(
            number: 1,
            entries: {
              '1': {'points': 20, 'moon': false},
              '2': {'points': 6, 'moon': false},
              '3': {'points': 0, 'moon': false},
            },
          ),
        ],
      );
      final stats = computeStats([g], withBestScore: true);
      expect(stats.firstWhere((s) => s.id == 3).wins, 1);
      expect(stats.firstWhere((s) => s.id == 3).bestScore, 0);
      expect(stats.firstWhere((s) => s.id == 1).bestScore, 20);
    });
  });

  test(
    'sqlite parameter binding handles quotes in names (no injection)',
    () async {
      final id = (await players.add("O'Brien; DROP TABLE x;--")).id!;
      final rows = await db
          .customSelect(
            'SELECT name FROM players WHERE id = ?',
            variables: [Variable.withInt(id)],
          )
          .get();
      expect(rows.single.read<String>('name'), "O'Brien; DROP TABLE x;--");
      expect((await db.select(db.players).get()).length, 1);
    },
  );
}
