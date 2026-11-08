// QA pass: characterisation tests for the findings in docs/qa-report.md.
// Each test pins the CURRENT behaviour (which is the finding), so the suite
// stays green. When a finding is fixed, flip the expectation in the same
// commit as the fix.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/hearts_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';
import 'package:kaartmaat/features/games/rules/rikken_rules.dart';
import 'package:kaartmaat/features/games/rules/toepen_rules.dart';
import 'package:drift/native.dart';

GameConfig cfg(
  GameRules r,
  List<String> p, {
  List<String>? players,
  Map<String, Object?> s = const {},
}) => GameConfig(
  type: r.type,
  participants: p,
  players: players,
  settings: {...r.defaultSettings, ...s},
);

void main() {
  test(
    'QA-01 (fixed) all unfinished games stay reachable, newest first',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = GameRepository(db);
      final first = await repo.createGame('custom', [], {});
      final second = await repo.createGame('custom', [], {});
      expect(await repo.watchUnfinishedIds().first, [second, first]);
    },
  );

  test(
    'QA-03 Toepen totals can exceed the limit after correcting an earlier round',
    () {
      const r = ToepenRules();
      final c = cfg(r, ['a', 'b']);
      RoundData round(int n, int a) => RoundData(
        number: n,
        entries: {
          'a': {'points': a},
          'b': {'points': 0},
        },
      );
      // a: 4 + 5 + 1 = 10 (out exactly at the limit)
      expect(r.totals(c, [round(1, 4), round(2, 5), round(3, 1)])['a'], 10);
      // correcting round 1 to 8: later points still count -> 14, above limit 10
      expect(r.totals(c, [round(1, 8), round(2, 5), round(3, 1)])['a'], 14);
    },
  );

  test(
    'QA-04 Klaverjassen accepts impossible roem counts (8 stuks, 8 four-jacks)',
    () {
      const r = KlaverjasRules();
      final c = cfg(r, ['wij', 'zij'], players: ['1', '2', '3', '4']);
      Entry t({
        bool playing = false,
        required int cards,
        int stuk = 0,
        int jacks = 0,
      }) => {
        'playing': playing,
        'pit': false,
        'cards': cards,
        'three': 0,
        'four': 0,
        'stuk': stuk,
        'equal': 0,
        'jacks': jacks,
      };
      final round = RoundData(
        number: 1,
        entries: {
          'wij': t(playing: true, cards: 100, stuk: 8, jacks: 8),
          'zij': t(cards: 62),
        },
      );
      expect(r.validateRound(c, round), isNull); // accepted
      expect(r.scoreRound(c, round)['wij'], 100 + 8 * 20 + 8 * 200); // 1860
    },
  );

  test('QA-05 Hartenjagen accepts a queen worth more than the whole round', () {
    const r = HeartsRules();
    final c = cfg(
      r,
      ['a', 'b', 'c'],
      s: {'totalPoints': 10, 'queenPoints': 40},
    );
    // hearts left = 10 - 40 = -30: the panel can never complete such a round
    expect(r.heartsTotal(c), -30);
    expect(r.autoLast(c, {'a': 0, 'b': 0, 'c': null}, null), isNull);
  });

  test(
    'QA-06 Rikken accepts an unknown role: that player silently pays nothing',
    () {
      const r = RikkenRules();
      final c = cfg(r, ['a', 'b', 'c', 'd']);
      final round = RoundData(
        number: 1,
        entries: {
          'a': {'role': 'bidder', 'contract': 'alone9', 'tricks': 9},
          'b': {'role': 'opp'},
          'c': {'role': 'opp'},
          'd': {'role': 'typo'},
        },
      );
      expect(r.validateRound(c, round), isNull); // accepted
      expect(
        r.outcome(c, round).points['a'],
        40,
      ); // should be refused; 60 if d were an opponent
    },
  );

  test(
    'QA-07 Rikken has no "rik beter" (9 tricks with a partner) contract',
    () {
      expect(
        rikContracts
            .where((c) => c.partner)
            .map((c) => (c.id, c.target))
            .toList(),
        [('rik', 8), ('troela', 8)],
      );
    },
  );

  test('QA-08 Amsterdams and Rotterdams score alike; Gronings is the variant that differs', () {
    const r = KlaverjasRules();
    expect(r.settingSpecs.firstWhere((s) => s.key == 'variant').options, [
      'amsterdams',
      'rotterdams',
      'gronings',
    ]);
    // see rules_worked_examples_test: identical scores for both variants
  });
}
