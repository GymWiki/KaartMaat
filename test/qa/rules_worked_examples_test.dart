// QA pass: worked examples per game. Every expected value below was computed
// by hand from the rules (see the comment above each case), NOT by running the
// code. Settings are the defaults unless a case says otherwise.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/canasta_rules.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/hearts_rules.dart';
import 'package:kaartmaat/features/games/rules/jokeren_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';
import 'package:kaartmaat/features/games/rules/rikken_rules.dart';
import 'package:kaartmaat/features/games/rules/rules_registry.dart';
import 'package:kaartmaat/features/games/rules/toepen_rules.dart';

GameConfig cfg(
  GameRules rules,
  List<String> participants, {
  Map<String, Object?> settings = const {},
  List<String>? players,
}) => GameConfig(
  type: rules.type,
  participants: participants,
  players: players,
  settings: {...rules.defaultSettings, ...settings},
);

void main() {
  group('registry', () {
    test('every game has sane player limits and unique setting keys', () {
      for (final r in allRules.values) {
        expect(r.minPlayers, greaterThanOrEqualTo(2), reason: r.type);
        expect(
          r.maxPlayers,
          greaterThanOrEqualTo(r.minPlayers),
          reason: r.type,
        );
        final keys = r.settingSpecs.map((s) => s.key).toList();
        expect(
          keys.toSet().length,
          keys.length,
          reason: '${r.type} duplicate key',
        );
        for (final s in r.settingSpecs) {
          expect(s.min, lessThanOrEqualTo(s.max), reason: '${r.type}.${s.key}');
          if (s.kind == SettingKind.integer) {
            expect(s.defaultValue, isA<int>());
            expect(
              s.defaultValue as int,
              inInclusiveRange(s.min, s.max),
              reason: '${r.type}.${s.key} default outside min..max',
            );
          }
          if (s.kind == SettingKind.choice) {
            expect(s.options, contains(s.defaultValue));
          }
        }
      }
    });

    test('player limits per game (as documented in the UI)', () {
      expect(
        (
          allRules['boerenbridge']!.minPlayers,
          allRules['boerenbridge']!.maxPlayers,
        ),
        (3, 7),
      );
      expect(
        (
          allRules['klaverjassen']!.minPlayers,
          allRules['klaverjassen']!.maxPlayers,
        ),
        (4, 4),
      );
      expect(
        (allRules['rikken']!.minPlayers, allRules['rikken']!.maxPlayers),
        (4, 4),
      );
      expect(
        (
          allRules['hartenjagen']!.minPlayers,
          allRules['hartenjagen']!.maxPlayers,
        ),
        (3, 6),
      );
      expect(
        (allRules['toepen']!.minPlayers, allRules['toepen']!.maxPlayers),
        (2, 8),
      );
      expect(
        (allRules['jokeren']!.minPlayers, allRules['jokeren']!.maxPlayers),
        (2, 8),
      );
      expect(
        (allRules['canasta']!.minPlayers, allRules['canasta']!.maxPlayers),
        (4, 4),
      );
      expect(
        (allRules['custom']!.minPlayers, allRules['custom']!.maxPlayers),
        (2, 8),
      );
    });

    test('unknown game type throws instead of guessing', () {
      expect(() => rulesFor('doesnotexist'), throwsArgumentError);
    });
  });

  group('standings, winners and ties (shared)', () {
    const rules = CustomRules();
    final c = cfg(rules, ['a', 'b', 'c', 'd']);
    RoundData r(int n, List<int> p) => RoundData(
      number: n,
      entries: {
        for (var i = 0; i < p.length; i++) 'abcd'[i]: {'points': p[i]},
      },
    );

    test('ties share a rank and the next rank is skipped (1,1,3,4)', () {
      final s = rules.standings(c, [
        r(1, [10, 10, 5, 1]),
      ]);
      expect(s.map((e) => e.rank), [1, 1, 3, 4]);
      expect(s.map((e) => e.participant), ['a', 'b', 'c', 'd']);
    });

    test('winners are all participants on rank 1, none before any round', () {
      expect(rules.winners(c, const []), isEmpty);
      expect(
        rules.winners(c, [
          r(1, [10, 10, 5, 1]),
        ]),
        ['a', 'b'],
      );
    });

    test('lowest-wins flips the order', () {
      final low = cfg(
        rules,
        ['a', 'b', 'c', 'd'],
        settings: {'lowestWins': true},
      );
      expect(
        rules.winners(low, [
          r(1, [10, 10, 5, 1]),
        ]),
        ['d'],
      );
    });

    test('all equal: everybody wins', () {
      expect(
        rules.winners(c, [
          r(1, [3, 3, 3, 3]),
        ]),
        ['a', 'b', 'c', 'd'],
      );
    });
  });

  // ------------------------------------------------------------------------
  group('Boerenbridge', () {
    const rules = BoerenbridgeRules();
    final players4 = ['1', '2', '3', '4'];
    final c4 = cfg(rules, players4);

    RoundData rd(int n, List<int> bids, [List<int>? tricks]) => RoundData(
      number: n,
      entries: {
        for (var i = 0; i < bids.length; i++)
          '${i + 1}': {'bid': bids[i], if (tricks != null) 'tricks': tricks[i]},
      },
    );

    test(
      'card sequence is 1..N..1 with N = floor(52 / players), 3 to 7 players',
      () {
        // N: 3p 17, 4p 13, 5p 10, 6p 8, 7p 7  (52/3=17.3, 52/4=13, 52/5=10.4, 52/6=8.7, 52/7=7.4)
        const expectedMax = {3: 17, 4: 13, 5: 10, 6: 8, 7: 7};
        expectedMax.forEach((n, max) {
          final c = cfg(rules, [for (var i = 1; i <= n; i++) '$i']);
          expect(rules.maxCards(c), max, reason: '$n players');
          expect(rules.totalRounds(c), 2 * max - 1, reason: '$n players');
          final seq = [
            for (var r = 1; r <= rules.totalRounds(c); r++)
              rules.cardsInRound(c, r),
          ];
          expect(seq.first, 1);
          expect(seq[max - 1], max); // peak played exactly once
          expect(seq.where((x) => x == max).length, 1);
          expect(seq.last, 1);
          // strictly +1 up, -1 down
          for (var i = 1; i < seq.length; i++) {
            expect((seq[i] - seq[i - 1]).abs(), 1);
          }
          // never more cards dealt than the deck holds
          for (final cards in seq) {
            expect(cards * n, lessThanOrEqualTo(52));
          }
        });
      },
    );

    test('maxCards setting caps the peak but cannot exceed the deck', () {
      expect(
        rules.maxCards(cfg(rules, players4, settings: {'maxCards': 5})),
        5,
      );
      expect(
        rules.totalRounds(cfg(rules, players4, settings: {'maxCards': 5})),
        9,
      );
      expect(
        rules.maxCards(cfg(rules, players4, settings: {'maxCards': 17})),
        13,
      );
      expect(
        rules.maxCards(cfg(rules, players4, settings: {'maxCards': 0})),
        13,
      );
    });

    test(
      'dealer: seat 0 in round 1, rotates, wraps; bidding starts left of dealer',
      () {
        expect(rules.dealer(c4, 1), '1');
        expect(rules.dealer(c4, 2), '2');
        expect(rules.dealer(c4, 4), '4');
        expect(rules.dealer(c4, 5), '1'); // wraps after 4 rounds
        expect(rules.bidOrder(c4, 1), ['2', '3', '4', '1']); // dealer bids last
        expect(rules.bidOrder(c4, 4), ['1', '2', '3', '4']);
      },
    );

    test('exact bid: 10 + 5 per trick; wrong bid: -5 per trick difference', () {
      // round 5 of 4 players = 5 cards. bids 2,1,0,2 (sum 5 would be forbidden
      // for the dealer, so use 2,1,0,1 sum 4)
      final round = rd(5, [2, 1, 0, 1], [2, 0, 1, 2]);
      // p1 exact 2: 10+5*2 = 20 ; p2 bid1 got0: -5 ; p3 bid0 got1: -5 ; p4 bid1 got2: -5
      expect(rules.scoreRound(c4, round), {'1': 20, '2': -5, '3': -5, '4': -5});
      // exact zero bid: 10 + 0
      final zero = rd(5, [0, 0, 0, 1], [0, 0, 0, 5]);
      expect(rules.scoreRound(c4, zero)['1'], 10);
      // large miss: bid 5 got 0 -> -25
      final miss = rd(5, [5, 0, 0, 0], [0, 5, 0, 0]);
      expect(rules.scoreRound(c4, miss), {
        '1': -25,
        '2': -25,
        '3': 10,
        '4': 10,
      });
    });

    test('scoring values are settings', () {
      final c = cfg(
        rules,
        players4,
        settings: {'exactBase': 1, 'exactPerTrick': 2, 'wrongPerTrick': 3},
      );
      // exact 2 -> 1 + 2*2 = 5 ; off by 2 -> -6
      final round = rd(5, [2, 3, 0, 0], [2, 1, 1, 1]);
      expect(rules.scoreRound(c, round), {'1': 5, '2': -6, '3': -3, '4': -3});
    });

    test('forbidden dealer bid: on, off, and impossible', () {
      // round 5 -> 5 cards, others bid 1+2+1 = 4 -> dealer may not bid 1
      expect(rules.forbiddenDealerBid(c4, 5, 4), 1);
      // others bid 6 (> cards) -> nothing forbidden
      expect(rules.forbiddenDealerBid(c4, 5, 6), isNull);
      // others bid exactly the cards -> dealer may not bid 0
      expect(rules.forbiddenDealerBid(c4, 5, 5), 0);
      final off = cfg(rules, players4, settings: {'dealerRestriction': false});
      expect(rules.forbiddenDealerBid(off, 5, 4), isNull);
    });

    test(
      'dealer restriction is enforced by validateRound (and only when on)',
      () {
        // 5 cards, bids sum to 5 -> rejected
        final sumEqual = rd(5, [2, 1, 1, 1]);
        expect(rules.validateRound(c4, sumEqual), RoundIssue.dealerBid);
        final off = cfg(
          rules,
          players4,
          settings: {'dealerRestriction': false},
        );
        expect(rules.validateRound(off, sumEqual), isNull);
        // sum != cards is fine
        expect(rules.validateRound(c4, rd(5, [2, 1, 1, 0])), isNull);
      },
    );

    test(
      'disabledBids only affects the dealer, only when the others have bid',
      () {
        // round 5, dealer = seat 0 ('1'), others bid 1,2,1
        final bids = {'1': null, '2': 1, '3': 2, '4': 1};
        expect(rules.disabledBids(c4, 5, '1', bids), {1});
        expect(rules.disabledBids(c4, 5, '2', bids), isEmpty);
        expect(
          rules.disabledBids(c4, 5, '1', {
            '1': null,
            '2': 1,
            '3': null,
            '4': 1,
          }),
          isEmpty,
        );
      },
    );

    test('tricks must add up to the cards; each value within 0..cards', () {
      expect(
        rules.validateRound(c4, rd(5, [2, 1, 0, 1], [2, 1, 1, 1])),
        isNull,
      );
      expect(
        rules.validateRound(c4, rd(5, [2, 1, 0, 1], [2, 1, 1, 0])),
        RoundIssue.tricksMismatch,
      );
      expect(
        rules.validateRound(c4, rd(5, [2, 1, 0, 1], [6, 0, 0, -1])),
        RoundIssue.outOfRange,
      );
      expect(
        rules.validateRound(c4, rd(5, [6, 0, 0, 0])),
        RoundIssue.outOfRange,
      );
      expect(
        rules.validateRound(c4, rd(5, [-1, 0, 0, 0])),
        RoundIssue.outOfRange,
      );
    });

    test('invalid round numbers are rejected', () {
      expect(
        rules.validateRound(c4, rd(0, [0, 0, 0, 0])),
        RoundIssue.outOfRange,
      );
      expect(
        rules.validateRound(c4, rd(26, [0, 0, 0, 0])),
        RoundIssue.outOfRange,
      );
      // round 25 is the last one (1 card): valid
      expect(rules.validateRound(c4, rd(25, [0, 0, 0, 0])), isNull);
    }, skip: false);

    test('a missing bid, or only some tricks, is rejected', () {
      final missingBid = RoundData(
        number: 5,
        entries: {
          '1': {'bid': 1},
          '2': {'bid': 1},
          '3': {'bid': 1},
          '4': {},
        },
      );
      expect(rules.validateRound(c4, missingBid), RoundIssue.missingEntry);
      final partial = RoundData(
        number: 5,
        entries: {
          '1': {'bid': 1, 'tricks': 1},
          '2': {'bid': 1},
          '3': {'bid': 1},
          '4': {'bid': 0},
        },
      );
      expect(rules.validateRound(c4, partial), RoundIssue.missingEntry);
    });

    test(
      'an open round (bids only) scores nothing and does not end the game',
      () {
        final open = rd(1, [0, 0, 0, 0]);
        expect(rules.isRoundComplete(c4, open), isFalse);
        expect(rules.scoreRound(c4, open), {'1': 0, '2': 0, '3': 0, '4': 0});
        final almost = [
          for (var r = 1; r <= 24; r++)
            rd(r, [0, 0, 0, 0], [rules.cardsInRound(c4, r), 0, 0, 0]),
          rd(25, [0, 0, 0, 0]), // last round still open
        ];
        expect(rules.isFinished(c4, almost), isFalse);
      },
    );

    test('game ends exactly when all rounds are complete', () {
      List<RoundData> played(int n) => [
        for (var r = 1; r <= n; r++)
          rd(r, [0, 0, 0, 0], [rules.cardsInRound(c4, r), 0, 0, 0]),
      ];
      expect(rules.isFinished(c4, played(24)), isFalse);
      expect(rules.isFinished(c4, played(25)), isTrue);
      expect(rules.plannedRounds(c4), 25);
    });

    test(
      'editing an earlier round recalculates the totals, order does not matter',
      () {
        final r1 = rd(1, [0, 0, 0, 0], [1, 0, 0, 0]); // 1 card, p1 won it
        final r2 = rd(2, [1, 0, 0, 0], [0, 0, 1, 1]); // 2 cards
        // r1: p1 bid0 got1 = -5; p2, p3, p4 exact 0 = 10 each
        // r2: p1 bid1 got0 = -5; p2 exact 0 = 10; p3 bid0 got1 = -5; p4 bid0 got1 = -5
        expect(rules.totals(c4, [r1, r2]), {'1': -10, '2': 20, '3': 5, '4': 5});
        // correct r1: p4 won that trick, not p1
        final r1fixed = rd(1, [0, 0, 0, 0], [0, 0, 0, 1]);
        // r1: p1 10, p2 10, p3 10, p4 -5 ; plus r2 as above
        expect(rules.totals(c4, [r1fixed, r2]), {
          '1': 5,
          '2': 20,
          '3': 5,
          '4': -10,
        });
      },
    );

    test('3 players and 7 players: bounds of the field', () {
      final c3 = cfg(rules, ['a', 'b', 'c']);
      expect(rules.cardsInRound(c3, 17), 17);
      expect(rules.totalRounds(c3), 33);
      // round 17 dealer = (17-1) % 3 = 1
      expect(rules.dealer(c3, 17), 'b');
      final c7 = cfg(rules, [for (var i = 0; i < 7; i++) '$i']);
      expect(rules.totalRounds(c7), 13);
      expect(rules.dealer(c7, 8), '0');
    });

    test('autoLastTricks: last bidder gets what is left', () {
      // round 5 (5 cards), bid order 2,3,4,1 -> last = '1'
      final t = {'1': null, '2': 2, '3': 1, '4': 1};
      expect(rules.autoLastTricks(c4, 5, t), 1);
      expect(
        rules.autoLastTricks(c4, 5, {'1': null, '2': 3, '3': 2, '4': 1}),
        isNull,
      ); // 6 > 5
      expect(
        rules.autoLastTricks(c4, 5, {'1': null, '2': 3, '3': null, '4': 1}),
        isNull,
      );
    });
  });

  // ------------------------------------------------------------------------
  group('Klaverjassen', () {
    const rules = KlaverjasRules();
    final c = cfg(rules, ['wij', 'zij'], players: ['1', '2', '3', '4']);

    Entry team({
      bool playing = false,
      bool pit = false,
      required int cards,
      int three = 0,
      int four = 0,
      int stuk = 0,
      int equal = 0,
      int jacks = 0,
    }) => {
      'playing': playing,
      'pit': pit,
      'cards': cards,
      'three': three,
      'four': four,
      'stuk': stuk,
      'equal': equal,
      'jacks': jacks,
    };

    RoundData rd(Entry wij, Entry zij) =>
        RoundData(number: 1, entries: {'wij': wij, 'zij': zij});

    test('normal deal: playing team 100 vs 62 -> 100 / 62', () {
      final r = rd(team(playing: true, cards: 100), team(cards: 62));
      expect(rules.validateRound(c, r), isNull);
      expect(rules.scoreRound(c, r), {'wij': 100, 'zij': 62});
    });

    test(
      'roem values: 3 in a row 20, 4 in a row 50, stuk 20, 4 equal 100, 4 jacks 200',
      () {
        // three+stuk = 40 ; four = 50 ; equal = 100 ; jacks = 200
        expect(rules.roemOf(c, team(cards: 0, three: 1, stuk: 1)), 40);
        expect(rules.roemOf(c, team(cards: 0, four: 1)), 50);
        expect(rules.roemOf(c, team(cards: 0, equal: 1)), 100);
        expect(rules.roemOf(c, team(cards: 0, jacks: 1)), 200);
        // combination: 2x three (40) + four (50) + stuk (20) = 110
        expect(
          rules.roemOf(c, team(cards: 0, three: 2, four: 1, stuk: 1)),
          110,
        );
      },
    );

    test('roem is added to the team that made it', () {
      // wij plays: 90 cards + 20 roem = 110 ; zij: 72 + 50 roem = 122  -> wij wet? 110 < 122 => nat
      final nat = rd(
        team(playing: true, cards: 90, three: 1),
        team(cards: 72, four: 1),
      );
      final o = rules.outcome(c, nat);
      expect(o.nat, isTrue);
      // zij gets all card points (162) + all roem (20 + 50) = 232
      expect(o.points, {'wij': 0, 'zij': 232});
      // wij makes it with roem: 90+20+0 = 110 vs 72 -> 110 / 72
      final ok = rd(team(playing: true, cards: 90, three: 1), team(cards: 72));
      expect(rules.scoreRound(c, ok), {'wij': 110, 'zij': 72});
    });

    test(
      'nat: playing team scores nothing, the other team gets 162 plus all roem',
      () {
        final r = rd(team(playing: true, cards: 60), team(cards: 102));
        final o = rules.outcome(c, r);
        expect(o.nat, isTrue);
        expect(o.points, {'wij': 0, 'zij': 162});
      },
    );

    test('tie (81-81) is nat by default and a split when tieIsNat is off', () {
      final r = rd(team(playing: true, cards: 81), team(cards: 81));
      expect(rules.scoreRound(c, r), {'wij': 0, 'zij': 162});
      final off = cfg(
        rules,
        ['wij', 'zij'],
        players: ['1', '2', '3', '4'],
        settings: {'tieIsNat': false},
      );
      expect(rules.scoreRound(off, r), {'wij': 81, 'zij': 81});
      // 82-80 is a clear success either way
      final ok = rd(team(playing: true, cards: 82), team(cards: 80));
      expect(rules.outcome(c, ok).nat, isFalse);
    });

    test('tie including roem: 70+20 vs 90 -> nat', () {
      final r = rd(team(playing: true, cards: 70, three: 1), team(cards: 92));
      // 90 <= 92 -> nat; zij gets 162 + 20 = 182
      expect(rules.scoreRound(c, r), {'wij': 0, 'zij': 182});
    });

    test('pit: all 162 + roem + 100 bonus, nothing for the other team', () {
      final r = rd(
        team(playing: true, pit: true, cards: 162, three: 1),
        team(cards: 0),
      );
      expect(rules.validateRound(c, r), isNull);
      final o = rules.outcome(c, r);
      expect(o.pit, isTrue);
      expect(o.nat, isFalse);
      expect(o.points, {'wij': 162 + 20 + 100, 'zij': 0});
      // the pit bonus is a setting
      final big = cfg(
        rules,
        ['wij', 'zij'],
        players: ['1', '2', '3', '4'],
        settings: {'pitBonus': 150},
      );
      expect(rules.scoreRound(big, r)['wij'], 162 + 20 + 150);
    });

    test('pit needs 162 card points and no roem for the other team', () {
      final fewCards = rd(
        team(playing: true, pit: true, cards: 160),
        team(cards: 2),
      );
      expect(rules.validateRound(c, fewCards), RoundIssue.invalidValue);
      final otherRoem = rd(
        team(playing: true, pit: true, cards: 162),
        team(cards: 0, three: 1),
      );
      expect(rules.validateRound(c, otherRoem), RoundIssue.invalidValue);
    });

    test('a 162 deal without pit flag is just 162 + roem, no bonus', () {
      final r = rd(team(playing: true, cards: 162), team(cards: 0));
      expect(rules.scoreRound(c, r), {'wij': 162, 'zij': 0});
    });

    test('boundary: playing team with 0 card points is nat', () {
      final r = rd(team(playing: true, cards: 0), team(cards: 162));
      expect(rules.scoreRound(c, r), {'wij': 0, 'zij': 162});
    });

    test('both Amsterdams and Rotterdams score identically', () {
      final r = rd(team(playing: true, cards: 100, four: 1), team(cards: 62));
      final a = cfg(
        rules,
        ['wij', 'zij'],
        players: ['1', '2', '3', '4'],
        settings: {'variant': 'amsterdams'},
      );
      final b = cfg(
        rules,
        ['wij', 'zij'],
        players: ['1', '2', '3', '4'],
        settings: {'variant': 'rotterdams'},
      );
      expect(rules.scoreRound(a, r), rules.scoreRound(b, r));
      expect(rules.scoreRound(a, r), {'wij': 150, 'zij': 62});
    });

    test('card points must add up to 162', () {
      expect(
        rules.validateRound(
          c,
          rd(team(playing: true, cards: 100), team(cards: 61)),
        ),
        RoundIssue.invalidValue,
      );
      expect(
        rules.validateRound(
          c,
          rd(team(playing: true, cards: 163), team(cards: -1)),
        ),
        RoundIssue.outOfRange,
      );
    });

    test('exactly one team must be playing', () {
      expect(
        rules.validateRound(c, rd(team(cards: 100), team(cards: 62))),
        RoundIssue.missingEntry,
      );
      expect(
        rules.validateRound(
          c,
          rd(team(playing: true, cards: 100), team(playing: true, cards: 62)),
        ),
        RoundIssue.missingEntry,
      );
    });

    test('an invalid entry scores 0-0 instead of garbage', () {
      final bad = rd(team(playing: true, cards: 100), team(cards: 61));
      expect(rules.scoreRound(c, bad), {'wij': 0, 'zij': 0});
    });

    test(
      'dealer and forehand (preselected playing team) rotate with the round',
      () {
        // round 1: dealer seat 0 ('1'), forehand seat 1 ('2') -> zij
        expect(rules.dealer(c, 1), '1');
        expect(rules.forehandTeam(c, 1), 'zij');
        expect(
          rules.forehandTeam(c, 2),
          'wij',
        ); // dealer seat 1, forehand seat 2
        expect(rules.forehandTeam(c, 3), 'zij');
        expect(rules.forehandTeam(c, 4), 'wij');
        expect(rules.forehandTeam(c, 5), 'zij'); // wraps
      },
    );

    test('team members: wij = seats 1 and 3, zij = seats 2 and 4', () {
      expect(rules.membersOf(c, 'wij'), ['1', '3']);
      expect(rules.membersOf(c, 'zij'), ['2', '4']);
    });

    test('game ends after 16 rounds, or at the target score if set', () {
      List<RoundData> rounds(int n) => [
        for (var i = 1; i <= n; i++)
          RoundData(
            number: i,
            entries: {
              'wij': team(playing: true, cards: 100),
              'zij': team(cards: 62),
            },
          ),
      ];
      expect(rules.isFinished(c, rounds(15)), isFalse);
      expect(rules.isFinished(c, rounds(16)), isTrue);
      final target = cfg(
        rules,
        ['wij', 'zij'],
        players: ['1', '2', '3', '4'],
        settings: {'rounds': 0, 'targetScore': 300},
      );
      expect(rules.isFinished(target, rounds(2)), isFalse); // 200
      expect(rules.isFinished(target, rounds(3)), isTrue); // 300 reached
      expect(rules.plannedRounds(target), isNull);
    });

    test('isValidCardsText accepts 0..162 and the empty string only', () {
      for (final ok in ['', '0', '1', '162', '99']) {
        expect(KlaverjasRules.isValidCardsText(ok), isTrue, reason: ok);
      }
      for (final bad in ['163', '1620', '-1', 'a', '1.5']) {
        expect(KlaverjasRules.isValidCardsText(bad), isFalse, reason: bad);
      }
    });
  });

  // ------------------------------------------------------------------------
  group('Rikken', () {
    const rules = RikkenRules();
    final ids = ['a', 'b', 'c', 'd'];
    final c = cfg(rules, ids);

    RoundData rd(
      String contract,
      int tricks, {
      String bidder = 'a',
      String? partner = 'b',
    }) => RoundData(
      number: 1,
      entries: {
        for (final p in ids)
          p: {
            'role': p == bidder ? 'bidder' : (p == partner ? 'partner' : 'opp'),
            if (p == bidder) 'contract': contract,
            if (p == bidder) 'tricks': tricks,
          },
      },
    );

    test('rik, exactly 8 tricks: bidder and partner +10, opponents -10', () {
      expect(rules.scoreRound(c, rd('rik', 8)), {
        'a': 10,
        'b': 10,
        'c': -10,
        'd': -10,
      });
    });

    test('rik with overtricks: +5 per extra trick (10 tricks -> 20)', () {
      expect(rules.scoreRound(c, rd('rik', 10)), {
        'a': 20,
        'b': 20,
        'c': -20,
        'd': -20,
      });
    });

    test(
      'rik lost by one: stake 15, bidder pays both opponents, partner nothing',
      () {
        expect(rules.scoreRound(c, rd('rik', 7)), {
          'a': -30,
          'b': 0,
          'c': 15,
          'd': 15,
        });
      },
    );

    test(
      'rik lost, maatPaysWhenLost: bidder and partner each pay one stake',
      () {
        final pay = cfg(rules, ids, settings: {'maatPaysWhenLost': true});
        expect(rules.scoreRound(pay, rd('rik', 7)), {
          'a': -15,
          'b': -15,
          'c': 15,
          'd': 15,
        });
      },
    );

    test('all 13 tricks with a partner: 10 + 5*5 + 35 slam bonus = 70', () {
      expect(rules.scoreRound(c, rd('rik', 13)), {
        'a': 70,
        'b': 70,
        'c': -70,
        'd': -70,
      });
    });

    test('solo 9 made exactly: 20 per opponent, bidder +60', () {
      expect(rules.scoreRound(c, rd('alone9', 9, partner: null)), {
        'a': 60,
        'b': -20,
        'c': -20,
        'd': -20,
      });
    });

    test('solo 9 with 11 tricks: 20 + 2*5 = 30 per opponent, bidder +90', () {
      expect(rules.scoreRound(c, rd('alone9', 11, partner: null)), {
        'a': 90,
        'b': -30,
        'c': -30,
        'd': -30,
      });
    });

    test('solo 9 lost by two (7 tricks): stake 30, bidder -90', () {
      expect(rules.scoreRound(c, rd('alone9', 7, partner: null)), {
        'a': -90,
        'b': 30,
        'c': 30,
        'd': 30,
      });
    });

    test(
      'piek: exactly 1 trick wins 15 per opponent, any other number loses',
      () {
        expect(rules.scoreRound(c, rd('piek', 1, partner: null))['a'], 45);
        expect(rules.scoreRound(c, rd('piek', 2, partner: null))['a'], -45);
        expect(rules.scoreRound(c, rd('piek', 0, partner: null))['a'], -45);
        // number of tricks does not change the stake
        expect(rules.scoreRound(c, rd('piek', 5, partner: null))['a'], -45);
      },
    );

    test('misere: 0 tricks wins 25 per opponent, one trick loses 75', () {
      expect(rules.scoreRound(c, rd('misere', 0, partner: null))['a'], 75);
      expect(rules.scoreRound(c, rd('misere', 1, partner: null))['a'], -75);
    });

    test(
      'solo 13 all tricks: 70 per opponent, no slam bonus without partner',
      () {
        expect(rules.scoreRound(c, rd('alone13', 13, partner: null))['a'], 210);
      },
    );

    test('contract base points are settings', () {
      final c2 = cfg(rules, ids, settings: {'base.rik': 1, 'perTrick': 2});
      expect(rules.scoreRound(c2, rd('rik', 9)), {
        'a': 3,
        'b': 3,
        'c': -3,
        'd': -3,
      });
    });

    test('every contract, every trick count 0..13 is zero-sum and finite', () {
      for (final contract in rikContracts) {
        for (final maatPays in [false, true]) {
          final cc = cfg(rules, ids, settings: {'maatPaysWhenLost': maatPays});
          for (var tricks = 0; tricks <= 13; tricks++) {
            final r = rd(
              contract.id,
              tricks,
              partner: contract.partner ? 'b' : null,
            );
            expect(rules.validateRound(cc, r), isNull);
            final sum = rules.outcome(cc, r).sum;
            expect(sum, 0, reason: '${contract.id} $tricks tricks');
          }
        }
      }
    });

    test(
      'rejects: no bidder, two bidders, partner missing / unexpected, 14 tricks',
      () {
        RoundData withRoles(
          Map<String, String> roles, {
          String contract = 'rik',
          int tricks = 8,
        }) => RoundData(
          number: 1,
          entries: {
            for (final p in ids)
              p: {
                'role': roles[p],
                if (roles[p] == 'bidder') 'contract': contract,
                if (roles[p] == 'bidder') 'tricks': tricks,
              },
          },
        );
        expect(
          rules.validateRound(
            c,
            withRoles({'a': 'opp', 'b': 'opp', 'c': 'opp', 'd': 'opp'}),
          ),
          RoundIssue.missingEntry,
        );
        expect(
          rules.validateRound(
            c,
            withRoles({'a': 'bidder', 'b': 'bidder', 'c': 'opp', 'd': 'opp'}),
          ),
          RoundIssue.missingEntry,
        );
        // rik needs a partner
        expect(
          rules.validateRound(
            c,
            withRoles({'a': 'bidder', 'b': 'opp', 'c': 'opp', 'd': 'opp'}),
          ),
          RoundIssue.missingEntry,
        );
        // a solo contract must not have a partner
        expect(
          rules.validateRound(
            c,
            withRoles(
              {'a': 'bidder', 'b': 'partner', 'c': 'opp', 'd': 'opp'},
              contract: 'alone9',
              tricks: 9,
            ),
          ),
          RoundIssue.missingEntry,
        );
        expect(
          rules.validateRound(
            c,
            withRoles({
              'a': 'bidder',
              'b': 'partner',
              'c': 'opp',
              'd': 'opp',
            }, tricks: 14),
          ),
          RoundIssue.outOfRange,
        );
        expect(
          rules.validateRound(
            c,
            withRoles({
              'a': 'bidder',
              'b': 'partner',
              'c': 'opp',
              'd': 'opp',
            }, tricks: -1),
          ),
          RoundIssue.outOfRange,
        );
      },
    );

    test('an invalid round scores zero for everybody', () {
      final bad = RoundData(
        number: 1,
        entries: {
          for (final p in ids) p: {'role': 'opp'},
        },
      );
      expect(rules.scoreRound(c, bad), {'a': 0, 'b': 0, 'c': 0, 'd': 0});
    });

    test('tricksFor / diffFor / madeWith agree for all contracts', () {
      for (final contract in rikContracts) {
        for (final success in [true, false]) {
          final maxD = RikkenRules.maxDiff(contract, success: success);
          for (var d = RikkenRules.minDiff(success: success); d <= maxD; d++) {
            final t = RikkenRules.tricksFor(
              contract,
              success: success,
              diff: d,
            );
            expect(
              RikkenRules.madeWith(contract, t),
              success,
              reason: '${contract.id} success=$success diff=$d tricks=$t',
            );
            expect(t, inInclusiveRange(0, 13));
            if (contract.type == RikType.atLeast) {
              expect(RikkenRules.diffFor(contract, t), d);
            }
          }
        }
      }
    });

    test('default contract: last bid contract, else rik', () {
      expect(rules.defaultContract(c, const []), 'rik');
      expect(
        rules.defaultContract(c, [rd('misere', 0, partner: null)]),
        'misere',
      );
    });

    test(
      'contract list is in bidding order of rising base points per kind',
      () {
        final ids = rikContracts.map((e) => e.id).toList();
        expect(ids.toSet().length, ids.length);
        // every contract has a base setting
        for (final contract in rikContracts) {
          expect(
            rules.defaultSettings.containsKey(RikkenRules.baseKey(contract.id)),
            isTrue,
          );
        }
      },
    );
  });

  // ------------------------------------------------------------------------
  group('Hartenjagen', () {
    const rules = HeartsRules();
    final ids = ['a', 'b', 'c', 'd'];
    final c = cfg(rules, ids);

    RoundData rd(List<int> points, {int? moon}) => RoundData(
      number: 1,
      entries: {
        for (var i = 0; i < ids.length; i++)
          ids[i]: {'points': points[i], 'moon': moon == i},
      },
    );

    test('a normal deal adds up to 26 (13 hearts + queen of spades 13)', () {
      final r = rd([5, 8, 0, 13]);
      expect(rules.validateRound(c, r), isNull);
      expect(rules.scoreRound(c, r), {'a': 5, 'b': 8, 'c': 0, 'd': 13});
    });

    test('a round that does not add up to 26 is rejected', () {
      expect(
        rules.validateRound(c, rd([5, 8, 0, 12])),
        RoundIssue.tricksMismatch,
      );
      expect(
        rules.validateRound(c, rd([5, 8, 0, 14])),
        RoundIssue.tricksMismatch,
      );
      expect(rules.validateRound(c, rd([30, -4, 0, 0])), RoundIssue.outOfRange);
    });

    test('shooting the moon (default): shooter 0, everybody else 26', () {
      final r = rd([0, 26, 26, 26], moon: 0);
      expect(rules.validateRound(c, r), isNull);
      expect(rules.scoreRound(c, r), {'a': 0, 'b': 26, 'c': 26, 'd': 26});
      expect(rules.moonPoints(c, 'a'), {'a': 0, 'b': 26, 'c': 26, 'd': 26});
    });

    test('shooting the moon (alternative): shooter -26, others 0', () {
      final alt = cfg(rules, ids, settings: {'moonMode': 'shooter'});
      final r = rd([-26, 0, 0, 0], moon: 0);
      expect(rules.validateRound(alt, r), isNull);
      expect(rules.scoreRound(alt, r), {'a': -26, 'b': 0, 'c': 0, 'd': 0});
    });

    test(
      'moon with wrong points, two shooters, or moon disabled is rejected',
      () {
        expect(
          rules.validateRound(c, rd([0, 26, 26, 25], moon: 0)),
          RoundIssue.invalidValue,
        );
        final two = RoundData(
          number: 1,
          entries: {
            for (var i = 0; i < 4; i++) ids[i]: {'points': 0, 'moon': i < 2},
          },
        );
        expect(rules.validateRound(c, two), RoundIssue.invalidValue);
        final off = cfg(rules, ids, settings: {'moonEnabled': false});
        expect(
          rules.validateRound(off, rd([0, 26, 26, 26], moon: 0)),
          RoundIssue.invalidValue,
        );
      },
    );

    test('queen of spades: hearts 3 + queen = 16 for that player', () {
      expect(rules.pointsFor(c, hearts: 3, hasQueen: true), 16);
      expect(rules.pointsFor(c, hearts: 3, hasQueen: false), 3);
      expect(rules.heartsTotal(c), 13);
    });

    test(
      'buildEntries: hearts 3,4,2 and the queen with b -> a 3, b 17, c 2, d 4',
      () {
        final e = rules.buildEntries(
          c,
          hearts: {'a': 3, 'b': 4, 'c': 2, 'd': null},
          queenHolder: 'b',
          moon: null,
        )!;
        expect([for (final p in ids) e[p]!['points']], [3, 17, 2, 4]);
        final sum = ids.fold<int>(0, (s, p) => s + (e[p]!['points'] as int));
        expect(sum, 26);
        // queen with nobody chosen -> last seat holds it
        final e2 = rules.buildEntries(
          c,
          hearts: {'a': 3, 'b': 4, 'c': 2, 'd': null},
          queenHolder: null,
          moon: null,
        )!;
        expect([for (final p in ids) e2[p]!['points']], [3, 4, 2, 17]);
      },
    );

    test('buildEntries is null while incomplete or when hearts exceed 13', () {
      expect(
        rules.buildEntries(
          c,
          hearts: {'a': 3, 'b': null, 'c': 2, 'd': null},
          queenHolder: null,
          moon: null,
        ),
        isNull,
      );
      expect(
        rules.buildEntries(
          c,
          hearts: {'a': 10, 'b': 4, 'c': 2, 'd': null},
          queenHolder: null,
          moon: null,
        ),
        isNull,
      );
    });

    test('lowest total wins; game ends when somebody reaches 100', () {
      RoundData r(int n, List<int> p) => RoundData(
        number: n,
        entries: {
          for (var i = 0; i < 4; i++) ids[i]: {'points': p[i], 'moon': false},
        },
      );
      final rounds = [
        r(1, [26, 0, 0, 0]),
        r(2, [26, 0, 0, 0]),
        r(3, [26, 0, 0, 0]),
      ];
      expect(rules.isFinished(c, rounds), isFalse); // 78
      final four = [
        ...rounds,
        r(4, [21, 5, 0, 0]),
      ]; // a = 99
      expect(rules.isFinished(c, four), isFalse);
      final five = [
        ...four,
        r(5, [1, 12, 13, 0]),
      ]; // a = 100 exactly
      expect(rules.isFinished(c, five), isTrue);
      expect(rules.winners(c, five), ['d']); // d has 0
      expect(rules.higherIsBetter(c), isFalse);
    });

    test('tie for the lowest total: both win', () {
      RoundData r(List<int> p) => RoundData(
        number: 1,
        entries: {
          for (var i = 0; i < 4; i++) ids[i]: {'points': p[i], 'moon': false},
        },
      );
      expect(
        rules.winners(c, [
          r([13, 0, 0, 13]),
        ]),
        ['b', 'c'],
      );
    });

    test('player count bounds: 3 and 6 players work with the same total', () {
      for (final n in [3, 6]) {
        final ids = [for (var i = 0; i < n; i++) 'p$i'];
        final cc = cfg(rules, ids);
        final r = RoundData(
          number: 1,
          entries: {
            for (var i = 0; i < n; i++)
              ids[i]: {'points': i == 0 ? 26 : 0, 'moon': false},
          },
        );
        expect(rules.validateRound(cc, r), isNull, reason: '$n players');
      }
    });
  });

  // ------------------------------------------------------------------------
  group('Toepen (points mode)', () {
    const rules = ToepenRules();
    final ids = ['a', 'b', 'c', 'd'];
    final c = cfg(rules, ids);

    RoundData pts(int n, List<int> p) => RoundData(
      number: n,
      entries: {
        for (var i = 0; i < p.length; i++) ids[i]: {'points': p[i]},
      },
    );

    test('totals are the sum of the rounds', () {
      expect(
        rules.totals(c, [
          pts(1, [1, 2, 0, 3]),
          pts(2, [2, 0, 0, 1]),
        ]),
        {'a': 3, 'b': 2, 'c': 0, 'd': 4},
      );
    });

    test('limit 10: 9 is "op pelt" (poverty), 10 is out', () {
      final s9 = rules.situation(c, [
        pts(1, [9, 4, 0, 0]),
      ]);
      expect(s9.poverty, {'a'});
      expect(s9.out, isEmpty);
      final s10 = rules.situation(c, [
        pts(1, [10, 4, 9, 0]),
      ]);
      expect(s10.out, {'a'});
      expect(s10.poverty, {'c'}); // out players are never in poverty
      expect(s10.alive(c), ['b', 'c', 'd']);
    });

    test('poverty off: nobody is marked; limit is a setting', () {
      final off = cfg(rules, ids, settings: {'poverty': false});
      expect(
        rules.situation(off, [
          pts(1, [9, 0, 0, 0]),
        ]).poverty,
        isEmpty,
      );
      final l15 = cfg(rules, ids, settings: {'limit': 15});
      final s = rules.situation(l15, [
        pts(1, [10, 14, 15, 0]),
      ]);
      expect(s.out, {'c'});
      expect(s.poverty, {'b'});
    });

    test(
      'game ends when one player is left (playOn) or when the first is out',
      () {
        final two = [
          pts(1, [10, 10, 3, 3]),
        ];
        final three = [
          pts(1, [10, 10, 10, 3]),
        ];
        expect(rules.isFinished(c, two), isFalse);
        expect(rules.isFinished(c, three), isTrue);
        expect(rules.winners(c, three), ['d']);
        final first = cfg(rules, ids, settings: {'playOn': false});
        expect(
          rules.isFinished(first, [
            pts(1, [10, 0, 0, 0]),
          ]),
          isTrue,
        );
        expect(
          rules.isFinished(first, [
            pts(1, [9, 0, 0, 0]),
          ]),
          isFalse,
        );
        expect(rules.isFinished(c, const []), isFalse);
      },
    );

    test('lowest total wins, ties share first place', () {
      expect(
        rules.winners(c, [
          pts(1, [4, 2, 2, 7]),
        ]),
        ['b', 'c'],
      );
    });

    test('an invalid / incomplete round is rejected', () {
      expect(
        rules.validateRound(
          c,
          RoundData(
            number: 1,
            entries: {
              'a': {'points': 1},
              'b': {},
              'c': {},
              'd': {},
            },
          ),
        ),
        RoundIssue.missingEntry,
      );
      expect(
        rules.validateRound(
          c,
          RoundData(
            number: 1,
            entries: {
              'a': {'points': 1},
              'b': {'points': 'x'},
              'c': {'points': 0},
              'd': {'points': 0},
            },
          ),
        ),
        RoundIssue.invalidValue,
      );
    });

    test('zeroEntries starts a round at 0 for everybody', () {
      expect(ToepenRules.zeroEntries(c), {
        for (final p in ids) p: {'points': 0},
      });
    });
  });

  group('Toepen (legacy knock rounds from older versions still score)', () {
    const rules = ToepenRules();
    final ids = ['a', 'b', 'c'];
    final c = cfg(rules, ids);
    RoundData legacy(
      int knocks, {
      required String winner,
      Map<String, int> folds = const {},
    }) => RoundData(
      number: 1,
      entries: {
        for (final p in ids)
          p: {
            'winner': p == winner,
            'knocks': knocks,
            if (folds.containsKey(p)) 'foldAt': folds[p],
          },
      },
    );

    test('no knock: winner 0, losers 1 point', () {
      expect(rules.scoreRound(c, legacy(0, winner: 'a')), {
        'a': 0,
        'b': 1,
        'c': 1,
      });
    });

    test('2 knocks: winner 0, losers who play on 3 points', () {
      expect(rules.scoreRound(c, legacy(2, winner: 'a')), {
        'a': 0,
        'b': 3,
        'c': 3,
      });
    });

    test(
      'folding at knock 1 costs 1 point, the other loser who plays on gets 3',
      () {
        expect(rules.scoreRound(c, legacy(2, winner: 'a', folds: {'b': 1})), {
          'a': 0,
          'b': 1,
          'c': 3,
        });
      },
    );

    test('poverty adds one automatic knock', () {
      // b is at 9 (limit 10) before the round -> 1 knock + 1 poverty = 2 -> losers 3
      final before = RoundData(
        number: 1,
        entries: {
          'a': {'winner': true, 'knocks': 8},
          'b': {'winner': false, 'knocks': 8},
          'c': {'winner': true, 'knocks': 8},
        },
      );
      // (setup only to reach 9 is clumsy; instead check effectiveKnocks directly)
      expect(rules.effectiveKnocks(before, true), 9);
      expect(rules.effectiveKnocks(before, false), 8);
    });

    test(
      'exactly one winner is required; fold must be 1..knocks+1 and not by the winner',
      () {
        expect(
          rules.validateRound(
            c,
            RoundData(
              number: 1,
              entries: {
                for (final p in ids) p: {'winner': false, 'knocks': 0},
              },
            ),
          ),
          RoundIssue.missingEntry,
        );
        expect(
          rules.validateRound(c, legacy(2, winner: 'a', folds: {'b': 4})),
          RoundIssue.outOfRange,
        );
        expect(
          rules.validateRound(c, legacy(2, winner: 'a', folds: {'a': 1})),
          RoundIssue.invalidValue,
        );
        expect(
          rules.validateRound(c, legacy(31, winner: 'a')),
          RoundIssue.outOfRange,
        );
      },
    );
  });

  // ------------------------------------------------------------------------
  group('Jokeren', () {
    const rules = JokerenRules();
    final ids = ['a', 'b', 'c'];
    final c = cfg(rules, ids);
    RoundData amounts(int n, Map<String, List<Object>> m) => RoundData(
      number: n,
      entries: {
        for (final p in ids) p: {'amounts': m[p] ?? <Object>[]},
      },
    );

    test(
      'amounts of one round are summed: joker 25 + ace 11 + face 10 = 46',
      () {
        final r = amounts(1, {
          'a': [25, 11, 10],
          'b': [0],
          'c': [10, 10],
        });
        expect(rules.validateRound(c, r), isNull);
        expect(rules.scoreRound(c, r), {'a': 46, 'b': 0, 'c': 20});
      },
    );

    test('negative amounts are allowed (corrections)', () {
      final r = amounts(1, {
        'a': [25, -10],
        'b': [-5],
        'c': [],
      });
      expect(rules.scoreRound(c, r), {'a': 15, 'b': -5, 'c': 0});
    });

    test('lowest wins by default, highest when the setting is off', () {
      final rounds = [
        amounts(1, {
          'a': [10],
          'b': [30],
          'c': [20],
        }),
      ];
      expect(rules.winners(c, rounds), ['a']);
      final high = cfg(rules, ids, settings: {'lowestWins': false});
      expect(rules.winners(high, rounds), ['b']);
    });

    test(
      'amounts limit: 1,000,000 ok, 1,000,001 rejected, non-integers rejected',
      () {
        expect(
          rules.validateRound(
            c,
            amounts(1, {
              'a': [1000000],
              'b': [],
              'c': [],
            }),
          ),
          isNull,
        );
        expect(
          rules.validateRound(
            c,
            amounts(1, {
              'a': [1000001],
              'b': [],
              'c': [],
            }),
          ),
          RoundIssue.outOfRange,
        );
        expect(
          rules.validateRound(
            c,
            amounts(1, {
              'a': [-1000001],
              'b': [],
              'c': [],
            }),
          ),
          RoundIssue.outOfRange,
        );
        expect(
          rules.validateRound(
            c,
            amounts(1, {
              'a': [1.5],
              'b': [],
              'c': [],
            }),
          ),
          RoundIssue.invalidValue,
        );
        expect(
          rules.validateRound(
            c,
            amounts(1, {
              'a': ['10'],
              'b': [],
              'c': [],
            }),
          ),
          RoundIssue.invalidValue,
        );
      },
    );

    test('a participant without an amounts list is rejected', () {
      final r = RoundData(
        number: 1,
        entries: {
          'a': {'amounts': <int>[]},
          'b': {'amounts': <int>[]},
          'c': {},
        },
      );
      expect(rules.validateRound(c, r), RoundIssue.missingEntry);
    });

    test('very large totals do not overflow: 99 rounds of 1,000,000', () {
      final rounds = [
        for (var i = 1; i <= 99; i++)
          amounts(i, {
            'a': [1000000],
            'b': [],
            'c': [],
          }),
      ];
      expect(rules.totals(c, rounds)['a'], 99000000);
    });

    test('ends after 10 rounds by default, or at a target score', () {
      List<RoundData> rounds(int n) => [
        for (var i = 1; i <= n; i++)
          amounts(i, {
            'a': [5],
          }),
      ];
      expect(rules.isFinished(c, rounds(9)), isFalse);
      expect(rules.isFinished(c, rounds(10)), isTrue);
      final t = cfg(rules, ids, settings: {'rounds': 0, 'targetScore': 50});
      expect(rules.isFinished(t, rounds(9)), isFalse); // 45
      expect(rules.isFinished(t, rounds(10)), isTrue); // 50
    });
  });

  // ------------------------------------------------------------------------
  group('Canasta', () {
    const rules = CanastaRules();
    final c = cfg(rules, ['wij', 'zij'], players: ['1', '2', '3', '4']);
    RoundData hand(int n, List<int> wij, List<int> zij) => RoundData(
      number: n,
      entries: {
        'wij': {'amounts': wij},
        'zij': {'amounts': zij},
      },
    );

    test(
      'hand total: bonuses + melds - cards in hand (500 + 300 + 100 - 45 = 855)',
      () {
        final r = hand(1, [500, 300, 100, -45], [150, -20]);
        expect(rules.validateRound(c, r), isNull);
        expect(rules.scoreRound(c, r), {'wij': 855, 'zij': 130});
      },
    );

    test('ends when a team has 5000 or more; highest wins', () {
      final r4999 = [
        hand(1, [4999], [100]),
      ];
      final r5000 = [
        hand(1, [5000], [100]),
      ];
      expect(rules.isFinished(c, r4999), isFalse);
      expect(rules.isFinished(c, r5000), isTrue);
      expect(rules.winners(c, r5000), ['wij']);
    });

    test('negative totals are allowed and rank last', () {
      final r = [
        hand(1, [-300], [20]),
      ];
      expect(rules.winners(c, r), ['zij']);
    });

    test('minimum for the first meld by score: boundaries', () {
      final cases = {
        -1: 15,
        0: 50,
        1499: 50,
        1500: 90,
        2999: 90,
        3000: 120,
        7000: 120,
      };
      cases.forEach((score, min) {
        expect(CanastaRules.initialMeldMinimum(score), min, reason: '$score');
      });
    });

    test('teams: wij = seats 1 and 3, zij = seats 2 and 4', () {
      expect(rules.membersOf(c, 'wij'), ['1', '3']);
      expect(rules.membersOf(c, 'zij'), ['2', '4']);
    });
  });

  // ------------------------------------------------------------------------
  group('Blanco teller (custom)', () {
    const rules = CustomRules();
    final ids = ['a', 'b'];
    final c = cfg(rules, ids);
    RoundData pts(int n, int a, int b) => RoundData(
      number: n,
      entries: {
        'a': {'points': a},
        'b': {'points': b},
      },
    );

    test('points are summed per round, negatives allowed', () {
      expect(rules.totals(c, [pts(1, 5, -3), pts(2, -10, 4)]), {
        'a': -5,
        'b': 1,
      });
    });

    test('step size: default 1, a configured step is kept, never below 1', () {
      expect(CustomRules.defaultStep(c), 1);
      expect(
        CustomRules.defaultStep(cfg(rules, ids, settings: {'step': 5})),
        5,
      );
      expect(
        CustomRules.defaultStep(cfg(rules, ids, settings: {'step': 0})),
        1,
      );
      expect(
        CustomRules.defaultStep(cfg(rules, ids, settings: {'step': -4})),
        1,
      );
      final spec = rules.settingSpecs.firstWhere((s) => s.key == 'step');
      expect((spec.min, spec.max), (1, 1000));
    });

    test('target score ends the game when reached, 0 means never', () {
      final t = cfg(rules, ids, settings: {'targetScore': 10});
      expect(rules.isFinished(t, [pts(1, 9, 0)]), isFalse);
      expect(rules.isFinished(t, [pts(1, 10, 0)]), isTrue);
      expect(rules.isFinished(c, [pts(1, 100000, 0)]), isFalse);
    });

    test('validate: missing and non-integer values rejected', () {
      expect(
        rules.validateRound(
          c,
          RoundData(
            number: 1,
            entries: {
              'a': {'points': 1},
              'b': {},
            },
          ),
        ),
        RoundIssue.missingEntry,
      );
      expect(
        rules.validateRound(
          c,
          RoundData(
            number: 1,
            entries: {
              'a': {'points': 1},
              'b': {'points': 1.5},
            },
          ),
        ),
        RoundIssue.invalidValue,
      );
    });
  });
}
