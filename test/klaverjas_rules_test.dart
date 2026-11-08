import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';

const rules = KlaverjasRules();
const players = ['a', 'b', 'c', 'd'];

GameConfig cfg({Map<String, Object?> overrides = const {}}) => GameConfig(
  type: 'klaverjassen',
  participants: const ['wij', 'zij'],
  players: players,
  settings: {...rules.defaultSettings, ...overrides},
);

/// [playing] chose trump and made [cards] card points. [wijRoem]/[zijRoem]
/// are counter maps like {'three': 1, 'stuk': 1}.
RoundData round(
  int n, {
  required String playing,
  required int cards,
  bool pit = false,
  Map<String, int> wijRoem = const {},
  Map<String, int> zijRoem = const {},
}) {
  final other = KlaverjasRules.other(playing);
  Entry entry(String team, int c, Map<String, int> roem) => {
    'playing': team == playing,
    'pit': pit && team == playing,
    'cards': c,
    ...roem,
  };
  return RoundData(
    number: n,
    entries: {
      playing: entry(playing, cards, playing == 'wij' ? wijRoem : zijRoem),
      other: entry(other, 162 - cards, other == 'wij' ? wijRoem : zijRoem),
    },
  );
}

void main() {
  final c = cfg();

  group('basis', () {
    test('162 card points are split over both teams', () {
      final s = rules.scoreRound(c, round(1, playing: 'wij', cards: 100));
      expect(s, {'wij': 100, 'zij': 62});
      expect(s.values.reduce((a, b) => a + b), 162);
    });

    test('exactly more than half makes the contract: 82 vs 80', () {
      final s = rules.scoreRound(c, round(1, playing: 'zij', cards: 82));
      expect(s, {'wij': 80, 'zij': 82});
    });
  });

  group('roem', () {
    test('values: three 20, four 50, stuk 20, four equal 100, jacks 200', () {
      expect(rules.roemOf(c, {'three': 1}), 20);
      expect(rules.roemOf(c, {'four': 1}), 50);
      expect(rules.roemOf(c, {'stuk': 1}), 20);
      expect(rules.roemOf(c, {'equal': 1}), 100);
      expect(rules.roemOf(c, {'jacks': 1}), 200);
    });

    test('three or four in a row with stuk = 40 and 70', () {
      expect(rules.roemOf(c, {'three': 1, 'stuk': 1}), 40);
      expect(rules.roemOf(c, {'four': 1, 'stuk': 1}), 70);
    });

    test('roem is added to the card points', () {
      final s = rules.scoreRound(
        c,
        round(
          1,
          playing: 'wij',
          cards: 100,
          wijRoem: {'stuk': 1, 'three': 1},
          zijRoem: {'three': 1},
        ),
      );
      expect(s, {'wij': 140, 'zij': 82});
    });

    test('values come from the settings', () {
      final custom = cfg(overrides: {'roemThree': 30, 'roemFourJacks': 100});
      expect(rules.roemOf(custom, {'three': 2, 'jacks': 1}), 160);
    });
  });

  group('nat', () {
    test('playing team with 81 of 162 is nat (tie counts as nat)', () {
      final s = rules.scoreRound(c, round(1, playing: 'wij', cards: 81));
      expect(s, {'wij': 0, 'zij': 162});
    });

    test('a tie is only nat when the setting says so', () {
      final lenient = cfg(overrides: {'tieIsNat': false});
      final s = rules.scoreRound(lenient, round(1, playing: 'wij', cards: 81));
      expect(s, {'wij': 81, 'zij': 81});
    });

    test('roem counts in the comparison: 90 cards but opponents out-roem', () {
      final r = round(
        1,
        playing: 'wij',
        cards: 90,
        wijRoem: {'three': 1}, // 110
        zijRoem: {'jacks': 1},
      ); // 72 + 200 = 272
      final s = rules.scoreRound(c, r);
      // nat: opponents get 162 plus the roem of both teams
      expect(s, {'wij': 0, 'zij': 162 + 20 + 200});
    });

    test(
      'nat can also come from roem of the playing team alone not helping',
      () {
        // 80 cards + stuk = 100 vs 82: not nat.
        final ok = rules.scoreRound(
          c,
          round(1, playing: 'wij', cards: 80, wijRoem: {'stuk': 1}),
        );
        expect(ok, {'wij': 100, 'zij': 82});
      },
    );

    test('defenders winning every trick is just nat, no pit bonus', () {
      final s = rules.scoreRound(c, round(1, playing: 'wij', cards: 0));
      expect(s, {'wij': 0, 'zij': 162});
    });
  });

  group('pit', () {
    test('all tricks: 162 + 100 bonus', () {
      final s = rules.scoreRound(
        c,
        round(1, playing: 'zij', cards: 162, pit: true),
      );
      expect(s, {'wij': 0, 'zij': 262});
    });

    test('pit with roem and a custom bonus', () {
      final custom = cfg(overrides: {'pitBonus': 80});
      final s = rules.scoreRound(
        custom,
        round(1, playing: 'wij', cards: 162, pit: true, wijRoem: {'four': 1}),
      );
      expect(s, {'wij': 162 + 50 + 80, 'zij': 0});
    });

    test('a pit is refused when the other team also has points or roem', () {
      final bad = round(
        1,
        playing: 'wij',
        cards: 150,
        pit: true,
      ); // others hold 12 points
      expect(rules.validateRound(c, bad), RoundIssue.invalidValue);
      final roemBad = round(
        1,
        playing: 'wij',
        cards: 162,
        pit: true,
        zijRoem: {'three': 1},
      );
      expect(rules.validateRound(c, roemBad), RoundIssue.invalidValue);
    });
  });

  group('validation', () {
    test('needs exactly one playing team', () {
      final none = RoundData(
        number: 1,
        entries: {
          'wij': {'playing': false, 'cards': 100},
          'zij': {'playing': false, 'cards': 62},
        },
      );
      expect(rules.validateRound(c, none), RoundIssue.missingEntry);
      final both = RoundData(
        number: 1,
        entries: {
          'wij': {'playing': true, 'cards': 100},
          'zij': {'playing': true, 'cards': 62},
        },
      );
      expect(rules.validateRound(c, both), RoundIssue.missingEntry);
    });

    test('card points must add up to 162 and stay in range', () {
      final off = RoundData(
        number: 1,
        entries: {
          'wij': {'playing': true, 'cards': 100},
          'zij': {'playing': false, 'cards': 50},
        },
      );
      expect(rules.validateRound(c, off), RoundIssue.invalidValue);
      final range = RoundData(
        number: 1,
        entries: {
          'wij': {'playing': true, 'cards': 163},
          'zij': {'playing': false, 'cards': -1},
        },
      );
      expect(rules.validateRound(c, range), RoundIssue.outOfRange);
    });

    test('a valid round passes', () {
      expect(
        rules.validateRound(c, round(1, playing: 'wij', cards: 90)),
        isNull,
      );
    });
  });

  group('teams and dealer', () {
    test('seats 1 and 3 are Wij, 2 and 4 are Zij', () {
      expect(rules.participantsFor(players), ['wij', 'zij']);
      expect(rules.membersOf(c, 'wij'), ['a', 'c']);
      expect(rules.membersOf(c, 'zij'), ['b', 'd']);
    });

    test('dealer rotates each deal and wraps after four', () {
      expect(
        [for (var n = 1; n <= 6; n++) rules.dealer(c, n)],
        ['a', 'b', 'c', 'd', 'a', 'b'],
      );
    });
  });

  group('game flow', () {
    test('totals, correction and winner', () {
      final rounds = [
        round(1, playing: 'wij', cards: 100), // 100 - 62
        round(2, playing: 'zij', cards: 70), // nat: 162 to wij
      ];
      expect(rules.totals(c, rounds), {'wij': 262, 'zij': 62});
      expect(rules.winners(c, rounds), ['wij']);

      rounds[1] = round(2, playing: 'zij', cards: 120); // zij 120 - wij 42
      expect(rules.totals(c, rounds), {'wij': 142, 'zij': 182});
      expect(rules.winners(c, rounds), ['zij']);
    });

    test('game ends after the configured number of deals', () {
      final rounds = [
        for (var i = 1; i <= 16; i++) round(i, playing: 'wij', cards: 100),
      ];
      expect(rules.isFinished(c, rounds.take(15).toList()), false);
      expect(rules.isFinished(c, rounds), true);
      expect(rules.plannedRounds(c), 16);
    });

    test('target mode: the target score ends the game, rounds are ignored', () {
      final open = cfg(
        overrides: {'endMode': 'target', 'rounds': 16, 'targetScore': 150},
      );
      expect(rules.plannedRounds(open), isNull);
      expect(
        rules.isFinished(open, [round(1, playing: 'wij', cards: 100)]),
        false,
      );
      expect(
        rules.isFinished(open, [
          round(1, playing: 'wij', cards: 100),
          round(2, playing: 'wij', cards: 100),
        ]),
        true,
      );
    });

    test('hands mode ignores the target score; rounds 0 never ends', () {
      final hands = cfg(
        overrides: {'endMode': 'hands', 'rounds': 2, 'targetScore': 50},
      );
      expect(
        rules.isFinished(hands, [round(1, playing: 'wij', cards: 100)]),
        false,
      );
      expect(
        rules.isFinished(hands, [
          round(1, playing: 'wij', cards: 100),
          round(2, playing: 'wij', cards: 100),
        ]),
        true,
      );
      final open = cfg(overrides: {'endMode': 'hands', 'rounds': 0});
      expect(rules.plannedRounds(open), isNull);
      expect(
        rules.isFinished(open, [
          for (var i = 1; i <= 40; i++) round(i, playing: 'wij', cards: 100),
        ]),
        false,
      );
    });

    test('games saved before endMode existed end on hands or target', () {
      final legacy = GameConfig(
        type: 'klaverjassen',
        participants: const ['wij', 'zij'],
        players: const ['1', '2', '3', '4'],
        settings: const {'rounds': 16, 'targetScore': 150},
      );
      expect(
        rules.isFinished(legacy, [
          round(1, playing: 'wij', cards: 100),
          round(2, playing: 'wij', cards: 100),
        ]),
        true,
      );
      expect(rules.plannedRounds(legacy), 16);
    });

    test('Amsterdams and Rotterdams score the same (per the sources)', () {
      final r = round(1, playing: 'wij', cards: 95, wijRoem: {'three': 1});
      expect(
        rules.scoreRound(cfg(overrides: {'variant': 'amsterdams'}), r),
        rules.scoreRound(cfg(overrides: {'variant': 'rotterdams'}), r),
      );
    });
  });
}
