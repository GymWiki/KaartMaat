import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';

const rules = BoerenbridgeRules();

GameConfig cfg(int players, {bool restriction = true}) => GameConfig(
      type: 'boerenbridge',
      participants: [for (var i = 1; i <= players; i++) '$i'],
      settings: {...rules.defaultSettings, 'dealerRestriction': restriction},
    );

void main() {
  // Round 3 with 3 players: 3 cards, dealer is seat 3, bidding order 1, 2, 3.
  final c = cfg(3);

  group('forbidden bid for the dealer', () {
    test('known once everybody else has bid', () {
      expect(rules.forbiddenBidForDealer(c, 3, {'1': 1, '2': 1}), 1); // 3 - 2
      expect(rules.forbiddenBidForDealer(c, 3, {'1': 0, '2': 0}), 3);
      expect(rules.forbiddenBidForDealer(c, 3, {'1': 3, '2': 2}), isNull); // over
    });

    test('unknown while somebody has not bid, and when the setting is off', () {
      expect(rules.forbiddenBidForDealer(c, 3, {'1': 1, '2': null}), isNull);
      expect(rules.forbiddenBidForDealer(cfg(3, restriction: false), 3, {'1': 1, '2': 1}),
          isNull);
    });

    test('only the dealer has a greyed-out bid', () {
      final bids = {'1': 1, '2': 1};
      expect(rules.disabledBids(c, 3, '3', bids), {1});
      expect(rules.disabledBids(c, 3, '1', bids), isEmpty);
      expect(rules.disabledBids(c, 3, '3', {'1': 1}), isEmpty);
    });

    test('follows the dealer rotation', () {
      // round 1: dealer is seat 1, so the bidding order is 2, 3, 1
      expect(rules.dealer(c, 1), '1');
      expect(rules.bidOrder(c, 1), ['2', '3', '1']);
      expect(rules.forbiddenBidForDealer(c, 1, {'2': 0, '3': 0}), 1);
      expect(rules.disabledBids(c, 1, '1', {'2': 0, '3': 0}), {1});
    });
  });

  group('tricks: last player is filled in automatically', () {
    test('the last player in bidding order gets what is left', () {
      expect(rules.autoLastTricks(c, 3, {'1': 1, '2': 0}), 2);
      expect(rules.autoLastTricks(c, 3, {'1': 3, '2': 0}), 0);
    });

    test('nothing until the others are in, nothing when they took too many', () {
      expect(rules.autoLastTricks(c, 3, {'1': 1}), isNull);
      expect(rules.autoLastTricks(c, 3, {'1': 3, '2': 1}), isNull);
    });

    test('the stored value of the last player is ignored', () {
      expect(rules.autoLastTricks(c, 3, {'1': 1, '2': 0, '3': 3}), 2);
    });

    test('values that cannot be right are disabled', () {
      // 3 cards: player 1 cannot take 3 when player 2 already took 1
      expect(rules.disabledTricks(c, 3, '1', {'2': 1}), {3});
      expect(rules.disabledTricks(c, 3, '1', {}), isEmpty);
      // the last player may only have the automatic value
      expect(rules.disabledTricks(c, 3, '3', {'1': 1, '2': 0}), {0, 1, 3});
      // not decided yet while others are missing
      expect(rules.disabledTricks(c, 3, '3', {'1': 1}), {0, 1, 2, 3});
    });

    test('the full tricks entry that results is valid', () {
      final tricks = {'1': 1, '2': 0};
      final last = rules.autoLastTricks(c, 3, tricks)!;
      final round = RoundData(number: 3, entries: {
        '1': {'bid': 1, 'tricks': 1},
        '2': {'bid': 0, 'tricks': 0},
        '3': {'bid': 1, 'tricks': last},
      });
      expect(rules.validateRound(c, round), isNull);
    });
  });

  group('round progression and corrections', () {
    RoundData round(int n, List<int> bids, [List<int>? tricks]) => RoundData(
          number: n,
          entries: {
            for (var i = 0; i < bids.length; i++)
              '${i + 1}': {'bid': bids[i], if (tricks != null) 'tricks': tricks[i]},
          },
        );

    test('cards and dealer move on after every round', () {
      expect([for (var n = 1; n <= 5; n++) rules.cardsInRound(cfg(4), n)], [1, 2, 3, 4, 5]);
      expect([for (var n = 1; n <= 5; n++) rules.dealer(cfg(4), n)],
          ['1', '2', '3', '4', '1']);
    });

    test('an open round does not count; completing it scores', () {
      final cc = cfg(3);
      final open = [round(1, [1, 0, 0])];
      expect(rules.totals(cc, open), {'1': 0, '2': 0, '3': 0});
      final done = [round(1, [1, 0, 0], [1, 0, 0])];
      expect(rules.totals(cc, done), {'1': 15, '2': 10, '3': 10});
    });

    test('correcting a past round recalculates the totals', () {
      final cc = cfg(3);
      final rounds = [
        round(1, [1, 0, 0], [1, 0, 0]), // 15 / 10 / 10
        round(2, [0, 1, 1], [0, 1, 1]), // 10 / 15 / 15
      ];
      expect(rules.totals(cc, rounds), {'1': 25, '2': 25, '3': 25});
      rounds[0] = round(1, [1, 0, 0], [0, 1, 0]); // 1 wrong: -5, 2 wrong: -5
      expect(rules.totals(cc, rounds), {'1': 5, '2': 10, '3': 25});
    });
  });
}
