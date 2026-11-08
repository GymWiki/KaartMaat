import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/canasta_rules.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/hearts_rules.dart';
import 'package:kaartmaat/features/games/rules/jokeren_rules.dart';
import 'package:kaartmaat/features/games/rules/rikken_rules.dart';
import 'package:kaartmaat/features/games/rules/toepen_rules.dart';

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
  group('Canasta', () {
    const r = CanastaRules();
    final c = cfg(r, ['wij', 'zij'], players: ['1', '2', '3', '4']);
    RoundData hand(int n, int wij, int zij) => RoundData(
      number: n,
      entries: {
        'wij': {
          'amounts': [wij],
        },
        'zij': {
          'amounts': [zij],
        },
      },
    );

    test('default target 5000 counts "5000 or more", checked per hand', () {
      expect(r.isFinished(c, [hand(1, 4999, 0)]), isFalse);
      expect(r.isFinished(c, [hand(1, 5000, 0)]), isTrue);
      // the hand being entered is not part of the rounds yet: not finished
      expect(r.isFinished(c, [hand(1, 3000, 2000)]), isFalse);
    });

    test('"more than 5000" is a setting', () {
      final gt = cfg(
        r,
        ['wij', 'zij'],
        players: ['1', '2', '3', '4'],
        s: {'targetInclusive': false},
      );
      expect(r.isFinished(gt, [hand(1, 5000, 0)]), isFalse);
      expect(r.isFinished(gt, [hand(1, 5001, 0)]), isTrue);
    });

    test('both teams above the target: the highest total wins', () {
      final rounds = [hand(1, 5200, 5600)];
      expect(r.isFinished(c, rounds), isTrue);
      expect(r.winners(c, rounds), ['zij']);
    });

    test('the target is a setting', () {
      final t = cfg(
        r,
        ['wij', 'zij'],
        players: ['1', '2', '3', '4'],
        s: {'targetScore': 3000},
      );
      expect(r.isFinished(t, [hand(1, 3000, 0)]), isTrue);
    });

    test('a tie at the top is a shared win', () {
      expect(r.winners(c, [hand(1, 5100, 5100)]), ['wij', 'zij']);
    });
  });

  group('Hartenjagen', () {
    const r = HeartsRules();
    final c = cfg(r, ['a', 'b', 'c']);
    final c3 = cfg(r, ['a', 'b', 'c'], s: {'rounds': 3, 'targetScore': 1000});
    RoundData round(int n, List<int> p) => RoundData(
      number: n,
      entries: {
        for (var i = 0; i < 3; i++)
          'abc'[i]: {'points': p[i], 'moon': false},
      },
    );

    test('a fixed number of rounds ends the game, lowest wins', () {
      final rounds = [
        round(1, [10, 10, 6]),
        round(2, [10, 10, 6]),
      ];
      expect(r.isFinished(c3, rounds), isFalse);
      final three = [
        ...rounds,
        round(3, [0, 10, 16]),
      ];
      expect(r.isFinished(c3, three), isTrue);
      expect(r.winners(c3, three), ['a']);
    });

    test('rounds 0 = only the target score decides', () {
      expect(r.plannedRounds(c), isNull);
      expect(r.isFinished(c, [for (var i = 1; i <= 5; i++) round(i, [10, 10, 6])]), isFalse);
    });

    test('several players at or above 100: the lowest total still wins', () {
      final rounds = [
        for (var i = 1; i <= 4; i++) round(i, [10, 10, 6]),
        round(5, [10, 10, 6]),
        round(6, [10, 10, 6]),
        round(7, [10, 10, 6]),
        round(8, [10, 10, 6]),
        round(9, [10, 10, 6]),
        round(10, [10, 10, 6]),
      ];
      // a and b: 100, c: 60
      expect(r.isFinished(c, rounds), isTrue);
      expect(r.winners(c, rounds), ['c']);
    });
  });

  group('Rikken', () {
    const r = RikkenRules();
    final ids = ['a', 'b', 'c', 'd'];
    RoundData round(int n) => RoundData(
      number: n,
      entries: {
        for (final p in ids)
          p: {
            'role': p == 'a' ? 'bidder' : 'opp',
            if (p == 'a') 'contract': 'misere',
            if (p == 'a') 'tricks': 0,
          },
      },
    );

    test('by default only a manual finish ends the game', () {
      final c = cfg(r, ids);
      expect(r.plannedRounds(c), isNull);
      expect(r.isFinished(c, [for (var i = 1; i <= 50; i++) round(i)]), isFalse);
    });

    test('an optional number of rounds ends it; highest total wins', () {
      final c = cfg(r, ids, s: {'rounds': 3});
      expect(r.isFinished(c, [round(1), round(2)]), isFalse);
      final three = [round(1), round(2), round(3)];
      expect(r.isFinished(c, three), isTrue);
      expect(r.winners(c, three), ['a']);
    });
  });

  group('Toepen', () {
    const r = ToepenRules();
    final c = cfg(r, ['a', 'b', 'c']);
    RoundData pts(int n, List<int> p) => RoundData(
      number: n,
      entries: {
        for (var i = 0; i < 3; i++) 'abc'[i]: {'points': p[i]},
      },
    );

    test('last player standing wins; several out at once: lowest total wins', () {
      final rounds = [
        pts(1, [10, 10, 4]),
      ];
      expect(r.isFinished(c, rounds), isTrue);
      expect(r.winners(c, rounds), ['c']);
      final allOut = [
        pts(1, [10, 10, 10]),
        pts(2, [0, 1, 0]),
      ];
      expect(r.isFinished(c, allOut), isTrue);
      expect(r.winners(c, allOut), ['a', 'c']); // lowest total: shared win
    });
  });

  group('Jokeren, Blanco teller, Boerenbridge', () {
    test('Jokeren: 10 rounds by default, lowest wins', () {
      const r = JokerenRules();
      final c = cfg(r, ['a', 'b']);
      RoundData round(int n) => RoundData(
        number: n,
        entries: {
          'a': {
            'amounts': [n],
          },
          'b': {
            'amounts': [0],
          },
        },
      );
      expect(r.isFinished(c, [for (var i = 1; i <= 9; i++) round(i)]), isFalse);
      final ten = [for (var i = 1; i <= 10; i++) round(i)];
      expect(r.isFinished(c, ten), isTrue);
      expect(r.winners(c, ten), ['b']);
    });

    test('Blanco teller: no target means finish by hand; highest wins', () {
      const r = CustomRules();
      final c = cfg(r, ['a', 'b']);
      final big = [
        RoundData(
          number: 1,
          entries: {
            'a': {'points': 99999},
            'b': {'points': 1},
          },
        ),
      ];
      expect(r.isFinished(c, big), isFalse);
      expect(r.winners(c, big), ['a']);
    });

    test('Boerenbridge ends after the last round of the card sequence', () {
      const r = BoerenbridgeRules();
      final c = cfg(r, ['1', '2', '3', '4', '5', '6', '7']);
      RoundData done(int n) => RoundData(
        number: n,
        entries: {
          for (var i = 1; i <= 7; i++)
            '$i': {'bid': 0, 'tricks': i == 1 ? r.cardsInRound(c, n) : 0},
        },
      );
      expect(r.isFinished(c, [for (var i = 1; i <= 12; i++) done(i)]), isFalse);
      expect(r.isFinished(c, [for (var i = 1; i <= 13; i++) done(i)]), isTrue);
    });
  });
}
