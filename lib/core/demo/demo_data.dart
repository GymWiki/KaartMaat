import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../features/games/data/draft_store.dart';
import '../../features/games/rules/boerenbridge_rules.dart';
import '../../features/games/rules/game_rules.dart';
import '../../features/games/rules/duizenden_rules.dart';
import '../../features/games/rules/klaverjas_rules.dart';
import '../../features/games/rules/rules_registry.dart';
import '../db/database.dart';

/// Demo mode, only for store screenshots: start the app with
/// `--dart-define=DEMO=true` in a debug or profile build. It replaces ALL
/// local data with made-up data, so never use it on a device with real games.
/// It can never run in a release build.
bool get demoModeEnabled => const bool.fromEnvironment('DEMO') && !kReleaseMode;

const _names = ['Anna', 'Bram', 'Chantal', 'Daan', 'Eva', 'Joost', 'Lieke'];

/// Wipes the database and fills it with the same made-up data every time:
/// 7 players, 2 groups, 3 running games (Boerenbridge in round 5, Duizenden
/// with a half-filled round, Klaverjassen with roem) and 8 finished games.
/// Pro is switched on through the debug override.
Future<void> seedDemoData(AppDatabase db, {DateTime? today}) async {
  final day = today ?? DateTime.now();
  final midnight = DateTime(day.year, day.month, day.day);
  await db.resetAll();

  // ---- players and groups ---------------------------------------------
  final id = <String, int>{};
  for (var i = 0; i < _names.length; i++) {
    id[_names[i]] = await db
        .into(db.players)
        .insert(
          PlayersCompanion.insert(
            name: _names[i],
            avatar: Value(i),
            createdAt: Value(midnight.subtract(Duration(days: 60 - i))),
          ),
        );
  }

  Future<int> group(String name, List<String> members) async {
    final gid = await db
        .into(db.groups)
        .insert(GroupsCompanion.insert(name: name));
    for (var p = 0; p < members.length; p++) {
      await db
          .into(db.groupMembers)
          .insert(
            GroupMembersCompanion.insert(
              groupId: gid,
              playerId: id[members[p]]!,
              position: Value(p),
            ),
          );
    }
    return gid;
  }

  final vrijdag = await group('Vrijdagavond', [
    'Anna',
    'Bram',
    'Chantal',
    'Daan',
  ]);
  final familie = await group('Familie', [
    'Eva',
    'Joost',
    'Lieke',
    'Anna',
    'Bram',
    'Daan',
  ]);

  // ---- helpers ---------------------------------------------------------
  Future<int> game(
    String type,
    List<String> players,
    DateTime created, {
    DateTime? finished,
    Map<String, Object?> settings = const {},
    int? groupId,
    List<Map<String, Map<String, Object?>>> rounds = const [],
  }) async {
    final gid = await db
        .into(db.games)
        .insert(
          GamesCompanion.insert(
            type: type,
            createdAt: Value(created),
            finishedAt: Value(finished),
            settings: Value(
              jsonEncode({...rulesFor(type).defaultSettings, ...settings}),
            ),
            groupId: Value(groupId),
          ),
        );
    for (var seat = 0; seat < players.length; seat++) {
      await db
          .into(db.gamePlayers)
          .insert(
            GamePlayersCompanion.insert(
              gameId: gid,
              playerId: id[players[seat]]!,
              seat: seat,
            ),
          );
    }
    for (var n = 0; n < rounds.length; n++) {
      await db
          .into(db.rounds)
          .insert(
            RoundsCompanion.insert(
              gameId: gid,
              number: n + 1,
              entries: jsonEncode(rounds[n]),
            ),
          );
    }
    return gid;
  }

  String k(String name) => '${id[name]}';
  DateTime at(int daysAgo, int hour, int minute) => midnight
      .subtract(Duration(days: daysAgo))
      .add(Duration(hours: hour, minutes: minute));

  // ---- finished games (history and statistics) -------------------------
  final four = ['Anna', 'Bram', 'Chantal', 'Daan'];
  final six = ['Eva', 'Joost', 'Lieke', 'Anna', 'Bram', 'Daan'];
  const bb = BoerenbridgeRules();

  for (final (days, order, seed) in [
    (2, four, 1),
    (6, four, 2),
    (11, ['Eva', 'Joost', 'Lieke', 'Anna'], 3),
    (16, four, 4),
  ]) {
    final created = at(days, 20, 15);
    final settings = {BoerenbridgeRules.maxCardsKey: 3};
    final cfg = GameConfig(
      type: bb.type,
      participants: [for (final p in order) k(p)],
      settings: {...bb.defaultSettings, ...settings},
    );
    final g = _Gen(seed * 31);
    await game(
      bb.type,
      order,
      created,
      finished: created.add(const Duration(minutes: 55)),
      settings: settings,
      groupId: order.length == 4 && order.first == 'Anna' ? vrijdag : null,
      rounds: [
        for (var r = 1; r <= bb.totalRounds(cfg); r++)
          g.boerenRound(bb, cfg, r),
      ],
    );
  }

  for (final (days, order, seed) in [(4, six, 5), (9, six, 6)]) {
    final g = _Gen(seed * 17);
    final created = at(days, 19, 30);
    await game(
      DuizendenRules.typeId,
      order,
      created,
      finished: created.add(const Duration(minutes: 70)),
      groupId: familie,
      rounds: [
        for (var r = 0; r < 6; r++)
          {
            for (final p in order) k(p): {'points': g.next(40, 260)},
          },
      ],
    );
  }

  for (final (days, seed) in [(3, 8), (13, 9)]) {
    final g = _Gen(seed * 13);
    final created = at(days, 21, 0);
    await game(
      KlaverjasRules.typeId,
      four,
      created,
      finished: created.add(const Duration(minutes: 80)),
      groupId: vrijdag,
      rounds: [for (var r = 0; r < 8; r++) g.klaverRound(r.isEven)],
    );
  }

  // ---- running games ---------------------------------------------------
  // Klaverjassen with roem (oldest of the three).
  Map<String, Map<String, Object?>> kj(
    bool wijPlays,
    int wijCards,
    Map<String, int> wijRoem,
    Map<String, int> zijRoem,
  ) => {
    KlaverjasRules.wij: _klaverEntry(wijPlays, wijCards, wijRoem),
    KlaverjasRules.zij: _klaverEntry(!wijPlays, 162 - wijCards, zijRoem),
  };
  await game(
    KlaverjasRules.typeId,
    four,
    at(0, 18, 30),
    groupId: vrijdag,
    rounds: [
      kj(true, 95, {'three': 1, 'stuk': 1}, {}),
      kj(false, 74, {'four': 1}, {'three': 2, 'stuk': 1}),
      kj(true, 102, {'four': 1}, {'stuk': 1}),
      kj(false, 91, {'three': 1}, {'three': 1}),
    ],
  );

  // Duizenden, with a half-filled round 4.
  final duizendenOrder = ['Eva', 'Joost', 'Lieke', 'Anna'];
  Map<String, Map<String, Object?>> dz(List<int> points) => {
    for (var i = 0; i < 4; i++) k(duizendenOrder[i]): {'points': points[i]},
  };
  final duizendenId = await game(
    DuizendenRules.typeId,
    duizendenOrder,
    at(0, 19, 15),
    groupId: familie,
    rounds: [
      dz([120, 80, 150, -50]),
      dz([200, 260, 90, 140]),
      dz([380, 120, 240, 90]),
    ],
  );
  await db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: DraftStore.key(duizendenId),
          value: jsonEncode({
            'round': 4,
            'editing': false,
            'values': {
              k('Eva'): '320',
              k('Joost'): '95',
              k('Lieke'): '',
              k('Anna'): '',
            },
            'focus': 2,
          }),
        ),
      );

  // Boerenbridge, round 5 of 4 players: rounds 1-4 scored, 5 has bids only.
  Map<String, Map<String, Object?>> brRound(
    List<int> bids,
    List<int?> tricks,
  ) => {
    for (var i = 0; i < 4; i++)
      k(four[i]): {'bid': bids[i], if (tricks[i] != null) 'tricks': tricks[i]},
  };
  await game(
    BoerenbridgeRules.typeId,
    four,
    at(0, 20, 5),
    groupId: vrijdag,
    rounds: [
      brRound([1, 0, 1, 1], [0, 0, 1, 0]),
      brRound([1, 1, 0, 1], [1, 0, 1, 0]),
      brRound([1, 1, 1, 1], [1, 1, 0, 1]),
      brRound([2, 1, 1, 1], [2, 1, 0, 1]),
      brRound([2, 2, 1, 1], [null, null, null, null]),
    ],
  );

  // ---- settings: Pro on for the screenshots ----------------------------
  await db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: 'pro.debugOverride', value: 'on'),
      );
}

Map<String, Object?> _klaverEntry(
  bool playing,
  int cards,
  Map<String, int> roem,
) => {
  'playing': playing,
  'pit': false,
  'cards': cards,
  for (final f in KlaverjasRules.roemFields) f: roem[f] ?? 0,
};

/// Tiny fixed-seed generator, so "random" demo games are the same every run.
class _Gen {
  _Gen(int seed) : _s = seed;
  int _s;

  int next(int min, int max) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return min + (_s >> 8) % (max - min + 1);
  }

  Map<String, Map<String, Object?>> klaverRound(bool wijPlays) {
    final cards = next(70, 100);
    return {
      KlaverjasRules.wij: _klaverEntry(
        wijPlays,
        wijPlays ? cards : 162 - cards,
        {if (next(0, 2) == 0) 'three': 1},
      ),
      KlaverjasRules.zij: _klaverEntry(
        !wijPlays,
        wijPlays ? 162 - cards : cards,
        {if (next(0, 3) == 0) 'stuk': 1},
      ),
    };
  }

  Map<String, Map<String, Object?>> boerenRound(
    BoerenbridgeRules rules,
    GameConfig cfg,
    int round,
  ) {
    final cards = rules.cardsInRound(cfg, round);
    final order = cfg.participants;
    final bids = <String, int>{
      for (final p in order) p: next(0, cards > 1 ? cards - 1 : 1),
    };
    final dealer = rules.dealer(cfg, round);
    final forbidden = rules.forbiddenBidForDealer(cfg, round, bids);
    if (forbidden != null && bids[dealer] == forbidden) {
      bids[dealer] = (forbidden + 1) % (cards + 1);
    }
    final tricks = <String, int>{for (final p in order) p: 0};
    for (var t = 0; t < cards; t++) {
      final winner = order[next(0, order.length - 1)];
      tricks[winner] = tricks[winner]! + 1;
    }
    return {
      for (final p in order) p: {'bid': bids[p], 'tricks': tricks[p]},
    };
  }
}
