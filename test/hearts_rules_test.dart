import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/hearts_rules.dart';

const rules = HeartsRules();
const ids = ['a', 'b', 'c', 'd'];

GameConfig cfg([Map<String, Object?> o = const {}]) => GameConfig(
      type: 'hartenjagen',
      participants: ids,
      settings: {...rules.defaultSettings, ...o},
    );

RoundData deal(int n, List<int> points, {String? moon}) => RoundData(
      number: n,
      entries: {
        for (var i = 0; i < ids.length; i++)
          ids[i]: {'points': points[i], 'moon': ids[i] == moon},
      },
    );

void main() {
  final c = cfg();

  test('a normal deal must hand out exactly 26 points', () {
    expect(rules.validateRound(c, deal(1, [13, 5, 3, 5])), isNull);
    expect(rules.validateRound(c, deal(1, [13, 5, 3, 4])),
        RoundIssue.tricksMismatch);
    expect(rules.validateRound(c, deal(1, [30, 0, 0, -4])),
        RoundIssue.outOfRange);
  });

  test('the total is a setting (Dutch piket: 15)', () {
    final piket = cfg({'totalPoints': 15});
    expect(rules.validateRound(piket, deal(1, [8, 5, 2, 0])), isNull);
    expect(rules.validateRound(piket, deal(1, [13, 5, 3, 5])),
        RoundIssue.tricksMismatch);
  });

  group('de maan schieten', () {
    test('default: shooter 0, everybody else gets the full total', () {
      expect(rules.moonPoints(c, 'b'), {'a': 26, 'b': 0, 'c': 26, 'd': 26});
      expect(rules.validateRound(c, deal(1, [26, 0, 26, 26], moon: 'b')), isNull);
    });

    test('alternative: shooter gets minus the total', () {
      final alt = cfg({'moonMode': 'shooter'});
      expect(rules.moonPoints(alt, 'b'), {'a': 0, 'b': -26, 'c': 0, 'd': 0});
      expect(rules.validateRound(alt, deal(1, [0, -26, 0, 0], moon: 'b')), isNull);
    });

    test('the points must match the chosen mode', () {
      expect(rules.validateRound(c, deal(1, [0, -26, 0, 0], moon: 'b')),
          RoundIssue.invalidValue);
    });

    test('can be switched off', () {
      final off = cfg({'moonEnabled': false});
      expect(rules.validateRound(off, deal(1, [26, 0, 26, 26], moon: 'b')),
          RoundIssue.invalidValue);
    });

    test('only one shooter', () {
      final two = RoundData(number: 1, entries: {
        for (final p in ids) p: {'points': 0, 'moon': p == 'a' || p == 'b'},
      });
      expect(rules.validateRound(c, two), RoundIssue.invalidValue);
    });
  });

  test('lowest wins, game ends at the target', () {
    final rounds = [deal(1, [20, 2, 2, 2]), deal(2, [10, 6, 5, 5])];
    expect(rules.totals(c, rounds), {'a': 30, 'b': 8, 'c': 7, 'd': 7});
    expect(rules.winners(c, rounds), ['c', 'd']);
    expect(rules.isFinished(c, rounds), false);
    final end = [for (var i = 1; i <= 4; i++) deal(i, [26, 0, 0, 0])];
    expect(rules.isFinished(c, end), true); // 104 >= 100
    expect(rules.winners(c, end), ['b', 'c', 'd']);
  });

  test('a correction recalculates the totals', () {
    final rounds = [deal(1, [13, 5, 3, 5])];
    expect(rules.totals(c, rounds)['a'], 13);
    rounds[0] = deal(1, [1, 5, 3, 17]);
    expect(rules.totals(c, rounds), {'a': 1, 'b': 5, 'c': 3, 'd': 17});
  });
}
