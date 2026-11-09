import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/duizenden_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';

void main() {
  const r = DuizendenRules();
  final ids = ['a', 'b', 'c'];
  GameConfig cfg([Map<String, Object?> s = const {}]) => GameConfig(
    type: r.type,
    participants: ids,
    settings: {...r.defaultSettings, ...s},
  );
  RoundData round(int n, List<int> p) => RoundData(
    number: n,
    entries: {
      for (var i = 0; i < ids.length; i++) ids[i]: {'points': p[i]},
    },
  );

  test('defaults: target 1000, 2 to 8 players, highest wins', () {
    expect(r.defaultSettings['targetScore'], 1000);
    expect((r.minPlayers, r.maxPlayers), (2, 8));
    expect(r.higherIsBetter(cfg()), isTrue);
  });

  test('totals add up, negative rounds included', () {
    final rounds = [
      round(1, [120, -50, 0]),
      round(2, [-30, 200, 15]),
    ];
    expect(r.totals(cfg(), rounds), {'a': 90, 'b': 150, 'c': 15});
    expect(r.standings(cfg(), rounds).map((s) => s.participant), [
      'b',
      'a',
      'c',
    ]);
  });

  group('end of the game (judged only after a saved round)', () {
    test('nobody at the target yet: the game goes on', () {
      expect(
        r.isFinished(cfg(), [
          round(1, [999, 500, 0]),
        ]),
        isFalse,
      );
      expect(r.isFinished(cfg(), const []), isFalse);
    });

    test('exactly the target counts as reaching it', () {
      final rounds = [
        round(1, [1000, 10, 0]),
      ];
      expect(r.isFinished(cfg(), rounds), isTrue);
      expect(r.winners(cfg(), rounds), ['a']);
    });

    test('going past the target is fine; one winner', () {
      final rounds = [
        round(1, [400, 100, 0]),
        round(2, [700, 100, 0]),
      ];
      expect(r.isFinished(cfg(), rounds), isTrue);
      expect(r.winners(cfg(), rounds), ['a']);
    });

    test(
      'two players above the target in the same round: the highest wins',
      () {
        final rounds = [
          round(1, [900, 950, 0]),
          round(2, [150, 120, 10]),
        ];
        // a 1050, b 1070
        expect(r.isFinished(cfg(), rounds), isTrue);
        expect(r.winners(cfg(), rounds), ['b']);
      },
    );

    test('two players exactly tied above the target share the win', () {
      final rounds = [
        round(1, [1100, 1100, 20]),
      ];
      expect(r.winners(cfg(), rounds), ['a', 'b']);
      expect(r.standings(cfg(), rounds).map((s) => s.rank), [1, 1, 3]);
    });

    test('the target is a setting; 0 means no automatic end', () {
      expect(
        r.isFinished(cfg({'targetScore': 300}), [
          round(1, [300, 0, 0]),
        ]),
        isTrue,
      );
      expect(
        r.isFinished(cfg({'targetScore': 0}), [
          round(1, [99999, 0, 0]),
        ]),
        isFalse,
      );
    });

    test('correcting an earlier round moves the end of the game', () {
      final rounds = [
        round(1, [600, 100, 0]),
        round(2, [450, 0, 0]),
      ]; // a 1050: over
      expect(r.isFinished(cfg(), rounds), isTrue);
      // round 1 corrected to 400: a is at 850 and the game is not over
      final fixed = [
        round(1, [400, 100, 0]),
        round(2, [450, 0, 0]),
      ];
      expect(r.isFinished(cfg(), fixed), isFalse);
      // and the other way: a correction can push somebody over the target
      final over = [
        round(1, [400, 100, 0]),
        round(2, [450, 1000, 0]),
      ];
      expect(r.isFinished(cfg(), over), isTrue);
      expect(r.winners(cfg(), over), ['b']);
    });

    test('undo of the last round takes the game back to running', () {
      final rounds = [
        round(1, [500, 0, 0]),
        round(2, [600, 0, 0]),
      ];
      expect(r.isFinished(cfg(), rounds), isTrue);
      expect(r.isFinished(cfg(), rounds.sublist(0, 1)), isFalse);
    });

    test(
      'negative rounds can push a player below zero and the leader down',
      () {
        final rounds = [
          round(1, [900, 100, 0]),
          round(2, [-500, 200, 0]),
        ];
        expect(r.totals(cfg(), rounds)['a'], 400);
        expect(r.winners(cfg(), rounds), ['a']);
      },
    );
  });

  group('validation: blocked outside the range, missing is missing', () {
    test('-999 to 9999 are accepted, beyond them are blocked', () {
      expect(r.validateRound(cfg(), round(1, [-999, 9999, 0])), isNull);
      expect(
        r.validateRound(cfg(), round(1, [-1000, 0, 0])),
        RoundIssue.outOfRange,
      );
      expect(
        r.validateRound(cfg(), round(1, [0, 10000, 0])),
        RoundIssue.outOfRange,
      );
    });

    test(
      'the limits are fixed constants; saved min/max values are ignored',
      () {
        expect(
          (DuizendenRules.minEntry, DuizendenRules.maxEntry),
          (-999, 9999),
        );
        expect(DuizendenRules.maxDigits, 4);
        // an older saved game that still carries the removed settings
        final old = cfg({'minEntry': -50, 'maxEntry': 200});
        expect(r.validateRound(old, round(1, [-999, 9999, 0])), isNull);
        expect(
          r.validateRound(old, round(1, [-1000, 0, 0])),
          RoundIssue.outOfRange,
        );
        expect(
          r.validateRound(old, round(1, [0, 10000, 0])),
          RoundIssue.outOfRange,
        );
        expect(r.settingSpecs.map((s) => s.key), ['targetScore']);
      },
    );

    test('0 is a value, a missing or non-integer value is not', () {
      expect(r.validateRound(cfg(), round(1, [0, 0, 0])), isNull);
      final missing = RoundData(
        number: 1,
        entries: {
          'a': {'points': 1},
          'b': {'points': 1},
          'c': {},
        },
      );
      expect(r.validateRound(cfg(), missing), RoundIssue.missingEntry);
      final text = RoundData(
        number: 1,
        entries: {
          'a': {'points': 1},
          'b': {'points': 1},
          'c': {'points': '5'},
        },
      );
      expect(r.validateRound(cfg(), text), RoundIssue.invalidValue);
    });
  });

  test(
    'toGo: what is left to the target, 0 once reached or without target',
    () {
      expect(r.toGo(cfg(), 660), 340);
      expect(r.toGo(cfg(), 1000), 0);
      expect(r.toGo(cfg(), 1500), 0);
      expect(r.toGo(cfg({'targetScore': 0}), 10), 0);
    },
  );
}
