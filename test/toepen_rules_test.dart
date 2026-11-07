import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/toepen_rules.dart';

const rules = ToepenRules();
const ids = ['a', 'b', 'c', 'd'];

GameConfig cfg([Map<String, Object?> o = const {}]) => GameConfig(
      type: 'toepen',
      participants: ids,
      settings: {...rules.defaultSettings, ...o},
    );

/// [winner] wins; [fold] maps player -> knock number they folded at.
RoundData deal(int n, String winner, {int knocks = 0, Map<String, int> fold = const {}}) =>
    RoundData(number: n, entries: {
      for (final p in ids)
        p: {
          'winner': p == winner,
          'knocks': knocks,
          if (fold.containsKey(p)) 'foldAt': fold[p],
        },
    });

void main() {
  final c = cfg();

  group('points per round', () {
    test('no knock: the winner gets 0, every loser 1', () {
      expect(rules.scoreRound(c, deal(1, 'a')), {'a': 0, 'b': 1, 'c': 1, 'd': 1});
    });

    test('one knock: players who play on and lose get 2, folders 1', () {
      final s = rules.scoreRound(c, deal(1, 'a', knocks: 1, fold: {'c': 1}));
      expect(s, {'a': 0, 'b': 2, 'c': 1, 'd': 2});
    });

    test('two knocks: folding at the second knock costs 2', () {
      final s = rules.scoreRound(
          c, deal(1, 'b', knocks: 2, fold: {'a': 1, 'c': 2}));
      expect(s, {'a': 1, 'b': 0, 'c': 2, 'd': 3});
    });

    test('everybody folds: the knocker wins, folders pay their knock', () {
      final s = rules.scoreRound(
          c, deal(1, 'a', knocks: 1, fold: {'b': 1, 'c': 1, 'd': 1}));
      expect(s, {'a': 0, 'b': 1, 'c': 1, 'd': 1});
    });
  });

  group('validation', () {
    test('exactly one winner, folds within the knocks, winner cannot fold', () {
      expect(rules.validateRound(c, deal(1, 'a')), isNull);
      final none = RoundData(number: 1, entries: {
        for (final p in ids) p: {'winner': false, 'knocks': 0},
      });
      expect(rules.validateRound(c, none), RoundIssue.missingEntry);
      expect(rules.validateRound(c, deal(1, 'a', knocks: 1, fold: {'b': 3})),
          RoundIssue.outOfRange);
      expect(rules.validateRound(c, deal(1, 'a', knocks: 1, fold: {'a': 1})),
          RoundIssue.invalidValue);
    });
  });

  group('elimination and poverty', () {
    final tight = cfg({'limit': 4});

    test('limit and poverty are derived from earlier rounds', () {
      final rounds = [deal(1, 'a'), deal(2, 'a'), deal(3, 'a')]; // b, c, d on 3
      final s = rules.situation(tight, rounds);
      expect(s.totals, {'a': 0, 'b': 3, 'c': 3, 'd': 3});
      expect(s.poverty, {'b', 'c', 'd'});
      expect(s.out, isEmpty);
    });

    test('poverty adds an automatic knock to the next round', () {
      final rounds = [deal(1, 'a'), deal(2, 'a'), deal(3, 'a'), deal(4, 'a')];
      // round 4 is played in poverty: one extra knock, so the losers get 2
      final scores = rules.roundScores(tight, rounds);
      expect(scores[3], {'a': 0, 'b': 2, 'c': 2, 'd': 2});
      expect(rules.totals(tight, rounds), {'a': 0, 'b': 5, 'c': 5, 'd': 5});
    });

    test('poverty can be switched off', () {
      final noPoverty = cfg({'limit': 4, 'poverty': false});
      final rounds = [deal(1, 'a'), deal(2, 'a'), deal(3, 'a'), deal(4, 'a')];
      expect(rules.roundScores(noPoverty, rounds)[3],
          {'a': 0, 'b': 1, 'c': 1, 'd': 1});
    });

    test('a folder in poverty pays 1 for the poverty knock', () {
      final rounds = [
        deal(1, 'a'),
        deal(2, 'a'),
        deal(3, 'a'),
        deal(4, 'a', fold: {'b': 1}),
      ];
      expect(rules.roundScores(tight, rounds)[3]['b'], 1);
    });

    test('players who are out score nothing afterwards', () {
      final cfg2 = cfg({'limit': 2, 'poverty': false});
      final rounds = [deal(1, 'a'), deal(2, 'a'), deal(3, 'a')];
      // b, c, d reach 2 after round 2 and are out; round 3 scores nothing
      expect(rules.roundScores(cfg2, rounds)[2], {'a': 0, 'b': 0, 'c': 0, 'd': 0});
      expect(rules.totals(cfg2, rounds), {'a': 0, 'b': 2, 'c': 2, 'd': 2});
    });

    test('a correction can change who is out', () {
      final cfg2 = cfg({'limit': 2, 'poverty': false});
      final rounds = [deal(1, 'a'), deal(2, 'a')];
      expect(rules.situation(cfg2, rounds).out, {'b', 'c', 'd'});
      rounds[1] = deal(2, 'b'); // now a: 1, b: 1, c: 2, d: 2 after round 2
      expect(rules.situation(cfg2, rounds).out, {'c', 'd'});
    });
  });

  group('end of game', () {
    test('play on until one player is left', () {
      final cfg2 = cfg({'limit': 2, 'poverty': false});
      final two = [deal(1, 'a'), deal(2, 'a')]; // b, c, d out, a alive
      expect(rules.isFinished(cfg2, two), true);
      expect(rules.winners(cfg2, two), ['a']);
      final one = [deal(1, 'a')];
      expect(rules.isFinished(cfg2, one), false);
    });

    test('or stop at the first player who is out', () {
      final cfg2 = cfg({'limit': 2, 'poverty': false, 'playOn': false});
      expect(rules.isFinished(cfg2, [deal(1, 'a')]), false);
      expect(rules.isFinished(cfg2, [deal(1, 'a'), deal(2, 'b')]), true);
    });
  });
}
