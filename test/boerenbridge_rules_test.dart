import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';

const rules = BoerenbridgeRules();

GameConfig cfg(
  int players, {
  bool restriction = true,
  int exactBase = 10,
  int exactPerTrick = 5,
  int wrongPerTrick = 5,
  int maxCards = 0,
}) =>
    GameConfig(
      type: 'boerenbridge',
      participants: [for (var i = 1; i <= players; i++) '$i'],
      settings: {
        'dealerRestriction': restriction,
        'exactBase': exactBase,
        'exactPerTrick': exactPerTrick,
        'wrongPerTrick': wrongPerTrick,
        'maxCards': maxCards,
      },
    );

RoundData round(int n, List<int> bids, [List<int>? tricks]) => RoundData(
      number: n,
      entries: {
        for (var i = 0; i < bids.length; i++)
          '${i + 1}': {'bid': bids[i], if (tricks != null) 'tricks': tricks[i]},
      },
    );

void main() {
  group('round sequence', () {
    test('max cards and round count per player count', () {
      const expected = {3: 17, 4: 13, 5: 10, 6: 8, 7: 7};
      expected.forEach((players, n) {
        expect(rules.maxCards(cfg(players)), n, reason: '$players players');
        expect(rules.totalRounds(cfg(players)), 2 * n - 1);
      });
    });

    test('cards go 1..N..1', () {
      final c = cfg(7);
      final cards = [
        for (var r = 1; r <= rules.totalRounds(c); r++) rules.cardsInRound(c, r),
      ];
      expect(cards, [1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1]);
    });

    test('maxCards setting overrides but never exceeds the deck', () {
      expect(rules.maxCards(cfg(4, maxCards: 8)), 8);
      expect(rules.maxCards(cfg(4, maxCards: 17)), 13);
      expect(rules.totalRounds(cfg(4, maxCards: 8)), 15);
    });
  });

  group('dealer', () {
    test('rotates one seat per round and wraps', () {
      final c = cfg(4);
      expect([for (var r = 1; r <= 6; r++) rules.dealerIndex(c, r)],
          [0, 1, 2, 3, 0, 1]);
      expect(rules.dealer(c, 2), '2');
    });

    test('bidding starts left of the dealer and the dealer bids last', () {
      final c = cfg(4);
      expect(rules.bidOrder(c, 1), ['2', '3', '4', '1']);
      expect(rules.bidOrder(c, 4), ['1', '2', '3', '4']);
    });
  });

  group('dealer restriction', () {
    test('blocks bids that add up to the number of tricks', () {
      // round 3 = 3 cards, bids 1+1+1 = 3
      expect(rules.validateRound(cfg(3), round(3, [1, 1, 1])),
          RoundIssue.dealerBid);
      expect(rules.validateRound(cfg(3), round(3, [1, 1, 2])), isNull);
      expect(rules.validateRound(cfg(3), round(3, [0, 0, 0])), isNull);
    });

    test('is not enforced when switched off', () {
      expect(
          rules.validateRound(cfg(3, restriction: false), round(3, [1, 1, 1])),
          isNull);
    });

    test('forbiddenDealerBid tells the dealer which bid is illegal', () {
      expect(rules.forbiddenDealerBid(cfg(4), 5, 3), 2); // 5 cards - 3
      expect(rules.forbiddenDealerBid(cfg(4), 5, 6), isNull); // already over
      expect(rules.forbiddenDealerBid(cfg(4, restriction: false), 5, 3), isNull);
    });

    test('bids must be between 0 and the cards in the round', () {
      expect(rules.validateRound(cfg(3), round(2, [3, 0, 0])),
          RoundIssue.outOfRange);
      expect(rules.validateRound(cfg(3), round(2, [-1, 0, 0])),
          RoundIssue.outOfRange);
    });
  });

  group('tricks', () {
    test('must add up to the cards in the round', () {
      final bids = [1, 0, 1]; // 2 != 3 cards, restriction ok
      expect(rules.validateRound(cfg(3), round(3, bids, [1, 1, 1])), isNull);
      expect(rules.validateRound(cfg(3), round(3, bids, [1, 1, 2])),
          RoundIssue.tricksMismatch);
      expect(rules.validateRound(cfg(3), round(3, bids, [0, 0, 0])),
          RoundIssue.tricksMismatch);
    });

    test('partly filled tricks are refused', () {
      final partial = RoundData(number: 3, entries: {
        '1': {'bid': 1, 'tricks': 1},
        '2': {'bid': 0},
        '3': {'bid': 1},
      });
      expect(rules.validateRound(cfg(3), partial), RoundIssue.missingEntry);
    });

    test('a bids-only round is valid but not complete', () {
      final r = round(3, [1, 0, 1]);
      expect(rules.validateRound(cfg(3), r), isNull);
      expect(rules.isRoundComplete(cfg(3), r), false);
      expect(rules.scoreRound(cfg(3), r).values, [0, 0, 0]);
    });
  });

  group('scoring', () {
    test('exact bid: 10 + 5 per trick', () {
      final s = rules.scoreRound(cfg(3), round(3, [3, 0, 0], [3, 0, 0]));
      expect(s, {'1': 25, '2': 10, '3': 10}); // bid 0 exact = base only
    });

    test('too many tricks: -5 per trick of difference', () {
      final s = rules.scoreRound(cfg(3), round(4, [0, 1, 1], [3, 1, 0]));
      expect(s['1'], -15); // bid 0, won 3
      expect(s['2'], 15); // exact 1: 10 + 5
      expect(s['3'], -5); // bid 1, won 0
    });

    test('too few tricks', () {
      final s = rules.scoreRound(cfg(3), round(4, [3, 1, 0], [0, 2, 2]));
      expect(s['1'], -15);
      expect(s['2'], -5);
      expect(s['3'], -10);
    });

    test('all values come from settings', () {
      final c = cfg(3, exactBase: 20, exactPerTrick: 2, wrongPerTrick: 1);
      final s = rules.scoreRound(c, round(3, [2, 0, 0], [2, 1, 0]));
      expect(s['1'], 24);
      expect(s['2'], -1);
      expect(s['3'], 20);
    });
  });

  group('totals and corrections', () {
    final c = cfg(3);

    test('correcting an earlier round recalculates the totals', () {
      final rounds = [
        round(1, [1, 0, 0], [1, 0, 0]), // 15, 10, 10
        round(2, [0, 1, 0], [1, 1, 0]), // -5, 15, 10
      ];
      expect(rules.totals(c, rounds), {'1': 10, '2': 25, '3': 20});

      rounds[0] = round(1, [1, 0, 0], [0, 1, 0]); // -5, -5, 10
      expect(rules.totals(c, rounds), {'1': -10, '2': 10, '3': 20});
    });

    test('an open round does not change the totals', () {
      final rounds = [round(1, [1, 0, 0], [1, 0, 0]), round(2, [0, 1, 0])];
      expect(rules.totals(c, rounds), {'1': 15, '2': 10, '3': 10});
    });
  });

  group('end of game', () {
    final c = cfg(7, maxCards: 2); // 3 rounds: 1, 2, 1

    test('finished only when every planned round is complete', () {
      final r1 = round(1, [1, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0]);
      final r2 = round(2, [1, 0, 0, 0, 0, 0, 0], [1, 1, 0, 0, 0, 0, 0]);
      final r3 = round(3, [1, 0, 0, 0, 0, 0, 0]); // open
      expect(rules.isFinished(c, [r1, r2]), false);
      expect(rules.isFinished(c, [r1, r2, r3]), false);
      final r3done = round(3, [1, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0]);
      expect(rules.isFinished(c, [r1, r2, r3done]), true);
    });

    test('winner is the highest total, ties share', () {
      final r1 = round(1, [1, 0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 0, 0, 0]);
      expect(rules.winners(c, [r1]), ['1']);
    });
  });
}
