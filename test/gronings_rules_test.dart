import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';

/// Worked examples for Gronings klaverjassen, computed by hand from the
/// confirmed rules:
/// - a bid is a multiple of 10; raise by +10, +20 or +30; lowest 70
/// - everybody passes: the player left of the dealer must bid the minimum
/// - the bid is made with card points plus roem (exactly the bid is made)
/// - made: both teams score what they got; nat: playing team 0, the others
///   162 plus all roem; pit: 162 + roem + 100, always made
void main() {
  const rules = KlaverjasRules();
  GameConfig cfg([Map<String, Object?> s = const {}]) => GameConfig(
    type: rules.type,
    participants: const ['wij', 'zij'],
    players: const ['1', '2', '3', '4'],
    settings: {...rules.defaultSettings, 'variant': 'gronings', ...s},
  );

  Entry team({
    bool playing = false,
    bool pit = false,
    required int cards,
    int three = 0,
    int four = 0,
    int? bid,
    String? bidder,
    String? suit,
  }) => {
    'playing': playing,
    'pit': pit,
    'cards': cards,
    'three': three,
    'four': four,
    'stuk': 0,
    'equal': 0,
    'jacks': 0,
    'bid': ?bid,
    'bidder': ?bidder,
    'suit': ?suit,
  };

  RoundData hand(Entry wij, Entry zij, {int number = 1}) =>
      RoundData(number: number, entries: {'wij': wij, 'zij': zij});

  /// wij play with [bid]; the bid was made by player '1' with hearts.
  RoundData wijPlay({
    required int bid,
    required int cards,
    int three = 0,
    int zijFour = 0,
    int number = 1,
  }) => hand(
    team(
      playing: true,
      cards: cards,
      three: three,
      bid: bid,
      bidder: '1',
      suit: 'hearts',
    ),
    team(cards: 162 - cards, four: zijFour),
    number: number,
  );

  group('bidding', () {
    test('opening bids: multiples of 10 from 70 up to the highest bid', () {
      final c = cfg();
      for (final ok in [70, 80, 100, 160, 260]) {
        expect(rules.isValidOpening(c, ok), isTrue, reason: '$ok');
      }
      for (final bad in [0, 60, 65, 75, 69, 71, 270, 300, -10]) {
        expect(rules.isValidOpening(c, bad), isFalse, reason: '$bad');
      }
    });

    test('raises: +10, +20 and +30 only', () {
      final c = cfg();
      expect(rules.isValidRaise(c, 90, 100), isTrue);
      expect(rules.isValidRaise(c, 90, 110), isTrue);
      expect(rules.isValidRaise(c, 90, 120), isTrue);
      for (final bad in [90, 95, 99, 130, 140, 80, 70]) {
        expect(rules.isValidRaise(c, 90, bad), isFalse, reason: '90 -> $bad');
      }
    });

    test('a raise may not go past the highest bid', () {
      final c = cfg();
      expect(rules.raisesFor(c, 230), [10, 20, 30]);
      expect(rules.raisesFor(c, 240), [10, 20]);
      expect(rules.raisesFor(c, 250), [10]);
      expect(rules.raisesFor(c, 260), isEmpty);
      expect(rules.isValidRaise(c, 250, 270), isFalse);
    });

    test('quick buttons: 70 to 160 in steps of 10; limits are settings', () {
      expect(
        rules.openingBids(cfg()),
        [70, 80, 90, 100, 110, 120, 130, 140, 150, 160],
      );
      expect(rules.openingBids(cfg({'minBid': 80, 'maxBid': 100})), [
        80,
        90,
        100,
      ]);
    });

    test('the highest bid wins the bidding', () {
      final c = cfg();
      final bids = [
        (player: '2', bid: 70),
        (player: '4', bid: 90),
        (player: '3', bid: 110),
      ];
      expect(rules.isValidBidding(c, bids), isTrue);
      expect(rules.resolveBidding(c, 1, bids), (bidder: '3', bid: 110));
    });

    test('an illegal bidding is refused: wrong opening, skipped step', () {
      final c = cfg();
      expect(rules.isValidBidding(c, [(player: '2', bid: 65)]), isFalse);
      expect(
        rules.isValidBidding(c, [
          (player: '2', bid: 70),
          (player: '3', bid: 110),
        ]),
        isFalse,
        reason: '+40 is not a raise',
      );
      expect(
        rules.isValidBidding(c, [
          (player: '2', bid: 70),
          (player: '3', bid: 70),
        ]),
        isFalse,
        reason: 'must go up',
      );
      expect(rules.isValidBidding(c, const []), isTrue); // everybody passed
    });

    test('everybody passes: the player left of the dealer bids the minimum', () {
      final c = cfg();
      // round 1: dealer seat 0 (player 1) -> player 2 starts
      expect(rules.resolveBidding(c, 1, const []), (bidder: '2', bid: 70));
      // round 2: dealer player 2 -> player 3
      expect(rules.resolveBidding(c, 2, const []), (bidder: '3', bid: 70));
      // the minimum is a setting
      expect(rules.resolveBidding(cfg({'minBid': 80}), 1, const []), (
        bidder: '2',
        bid: 80,
      ));
    });

    test('the bidding order starts left of the dealer and wraps', () {
      final c = cfg();
      expect(rules.bidOrder(c, 1), ['2', '3', '4', '1']);
      expect(rules.bidOrder(c, 2), ['3', '4', '1', '2']);
      expect(rules.bidOrder(c, 4), ['1', '2', '3', '4']);
      expect(rules.bidOrder(c, 5), ['2', '3', '4', '1']);
    });
  });

  group('scoring, worked examples', () {
    test('1. bid 90, 100 points made (62 for the others): 100 / 62', () {
      final r = wijPlay(bid: 90, cards: 100);
      expect(rules.validateRound(cfg(), r), isNull);
      final o = rules.outcome(cfg(), r);
      expect(o.nat, isFalse);
      expect(o.bid, 90);
      expect(o.points, {'wij': 100, 'zij': 62});
    });

    test('2. bid 100, 95 + 20 roem = 115 made: 115 / 67', () {
      final r = wijPlay(bid: 100, cards: 95, three: 1);
      expect(rules.scoreRound(cfg(), r), {'wij': 115, 'zij': 67});
    });

    test('3. bid 100 with 95 points and no roem: nat, 0 / 162', () {
      final r = wijPlay(bid: 100, cards: 95);
      final o = rules.outcome(cfg(), r);
      expect(o.nat, isTrue);
      expect(o.points, {'wij': 0, 'zij': 162});
    });

    test('4. exactly the bid is made: 100 + 20 roem against a bid of 120', () {
      final r = wijPlay(bid: 120, cards: 100, three: 1);
      expect(rules.outcome(cfg(), r).nat, isFalse);
      expect(rules.scoreRound(cfg(), r), {'wij': 120, 'zij': 62});
    });

    test('5. one short is nat: bid 130 with 100 + 20 roem = 120', () {
      final r = wijPlay(bid: 130, cards: 100, three: 1);
      final o = rules.outcome(cfg(), r);
      expect(o.nat, isTrue);
      // zij: all 162 card points + all roem (wij 20)
      expect(o.points, {'wij': 0, 'zij': 182});
    });

    test('6. nat gives the others the roem of both teams', () {
      // bid 110, wij 90 cards, zij 72 cards + 50 roem
      final r = wijPlay(bid: 110, cards: 90, zijFour: 1);
      final o = rules.outcome(cfg(), r);
      expect(o.nat, isTrue);
      expect(o.points, {'wij': 0, 'zij': 162 + 50});
    });

    test('7. a low bid made with less than half: 75 points on a bid of 70', () {
      // the other variants would call this nat (75 < 87); with a bid it is made
      final r = wijPlay(bid: 70, cards: 75);
      expect(rules.scoreRound(cfg(), r), {'wij': 75, 'zij': 87});
      final amsterdams = cfg({'variant': 'amsterdams'});
      expect(rules.outcome(amsterdams, r).nat, isTrue);
    });

    test('8. pit is always made: 162 + 20 roem + 100 bonus on a bid of 140', () {
      final r = hand(
        team(
          playing: true,
          pit: true,
          cards: 162,
          three: 1,
          bid: 140,
          bidder: '3',
          suit: 'spades',
        ),
        team(cards: 0),
      );
      expect(rules.validateRound(cfg(), r), isNull);
      final o = rules.outcome(cfg(), r);
      expect(o.pit, isTrue);
      expect(o.nat, isFalse);
      expect(o.points, {'wij': 282, 'zij': 0});
    });

    test('9. zij play (bidder 2) and make 111 + 50 roem', () {
      final r = hand(
        team(cards: 51),
        team(
          playing: true,
          cards: 111,
          four: 1,
          bid: 150,
          bidder: '2',
          suit: 'clubs',
        ),
      );
      expect(rules.validateRound(cfg(), r), isNull);
      // 111 + 50 = 161 >= 150 made
      expect(rules.scoreRound(cfg(), r), {'wij': 51, 'zij': 161});
    });

    test('10. correcting an earlier hand recalculates the totals', () {
      final h1 = wijPlay(bid: 100, cards: 95); // nat: 0 / 162
      final h2 = wijPlay(bid: 90, cards: 100, number: 2); // 100 / 62
      expect(rules.totals(cfg(), [h1, h2]), {'wij': 100, 'zij': 224});
      // corrected: 20 roem more, so the bid is made: 115 / 67
      final fixed = wijPlay(bid: 100, cards: 95, three: 1);
      expect(rules.totals(cfg(), [fixed, h2]), {'wij': 215, 'zij': 129});
    });

    test('the roem values stay settings in Gronings too', () {
      final c = cfg({'roemThree': 30});
      expect(rules.scoreRound(c, wijPlay(bid: 100, cards: 95, three: 1)), {
        'wij': 125,
        'zij': 67,
      });
    });
  });

  group('validation (Gronings hands need a proper bid)', () {
    RoundData withBid(Map<String, Object?> extra) {
      final base = team(playing: true, cards: 100);
      return hand({...base, ...extra}, team(cards: 62));
    }

    test('a hand without a bid is incomplete', () {
      final r = hand(team(playing: true, cards: 100), team(cards: 62));
      expect(rules.validateRound(cfg(), r), RoundIssue.missingEntry);
    });

    test('a bid that is not a multiple of 10 is invalid', () {
      final r = withBid({'bid': 85, 'bidder': '1', 'suit': 'hearts'});
      expect(rules.validateRound(cfg(), r), RoundIssue.invalidValue);
    });

    test('a bid below the minimum or above the maximum is out of range', () {
      expect(
        rules.validateRound(
          cfg(),
          withBid({'bid': 60, 'bidder': '1', 'suit': 'hearts'}),
        ),
        RoundIssue.outOfRange,
      );
      expect(
        rules.validateRound(
          cfg(),
          withBid({'bid': 270, 'bidder': '1', 'suit': 'hearts'}),
        ),
        RoundIssue.outOfRange,
      );
    });

    test('a trump suit is needed, and only a real suit', () {
      expect(
        rules.validateRound(cfg(), withBid({'bid': 90, 'bidder': '1'})),
        RoundIssue.missingEntry,
      );
      expect(
        rules.validateRound(
          cfg(),
          withBid({'bid': 90, 'bidder': '1', 'suit': 'stars'}),
        ),
        RoundIssue.missingEntry,
      );
    });

    test('the bidder must be in the playing team', () {
      // wij are players 1 and 3; player 2 is in zij
      expect(
        rules.validateRound(
          cfg(),
          withBid({'bid': 90, 'bidder': '2', 'suit': 'hearts'}),
        ),
        RoundIssue.invalidValue,
      );
      expect(
        rules.validateRound(
          cfg(),
          withBid({'bid': 90, 'bidder': '3', 'suit': 'hearts'}),
        ),
        isNull,
      );
    });

    test('the other variants do not ask for a bid and score as before', () {
      final a = cfg({'variant': 'amsterdams'});
      final plain = hand(team(playing: true, cards: 100), team(cards: 62));
      expect(rules.validateRound(a, plain), isNull);
      expect(rules.scoreRound(a, plain), {'wij': 100, 'zij': 62});
      expect(rules.outcome(a, plain).bid, isNull);
    });

    test('sixteen hands still end the game', () {
      final hands = [
        for (var i = 1; i <= 16; i++) wijPlay(bid: 90, cards: 100, number: i),
      ];
      expect(rules.isFinished(cfg(), hands.sublist(0, 15)), isFalse);
      expect(rules.isFinished(cfg(), hands), isTrue);
    });
  });
}
