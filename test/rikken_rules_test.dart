import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/rikken_rules.dart';

const rules = RikkenRules();
const ids = ['1', '2', '3', '4'];

GameConfig cfg([Map<String, Object?> overrides = const {}]) => GameConfig(
      type: 'rikken',
      participants: ids,
      settings: {...rules.defaultSettings, ...overrides},
    );

RoundData deal(
  String contract,
  int tricks, {
  String bidder = '1',
  String? partner,
}) =>
    RoundData(number: 1, entries: {
      for (final p in ids)
        p: {
          'role': p == bidder
              ? 'bidder'
              : p == partner
                  ? 'partner'
                  : 'opp',
          'contract': contract,
          'tricks': tricks,
        },
    });

void main() {
  final c = cfg();

  group('rik with a partner', () {
    test('made with an overtrick: bidder and partner win, opponents pay', () {
      final s = rules.scoreRound(c, deal('rik', 9, partner: '2'));
      // stake 10 + 5 for one overtrick
      expect(s, {'1': 15, '2': 15, '3': -15, '4': -15});
    });

    test('made with exactly 8 tricks', () {
      final s = rules.scoreRound(c, deal('rik', 8, partner: '3'));
      expect(s, {'1': 10, '2': -10, '3': 10, '4': -10});
    });

    test('failed: bidder pays both opponents, partner pays nothing', () {
      final s = rules.scoreRound(c, deal('rik', 6, partner: '2'));
      // stake 10 + 5 * 2 undertricks = 20
      expect(s, {'1': -40, '2': 0, '3': 20, '4': 20});
    });

    test('failed with maatPaysWhenLost: partner shares the loss', () {
      final s = rules.scoreRound(
          cfg({'maatPaysWhenLost': true}), deal('rik', 6, partner: '2'));
      expect(s, {'1': -20, '2': -20, '3': 20, '4': 20});
    });

    test('all 13 tricks earns the slam bonus', () {
      final s = rules.scoreRound(c, deal('rik', 13, partner: '2'));
      // 10 + 5 * 5 + 35
      expect(s['1'], 70);
      expect(s['3'], -70);
    });

    test('a partner contract needs a partner', () {
      final r = deal('rik', 8);
      expect(rules.validateRound(c, r), RoundIssue.missingEntry);
    });
  });

  group('alone and special contracts', () {
    test('alone contract made: bidder wins the stake from each opponent', () {
      final s = rules.scoreRound(c, deal('alone10', 11));
      // 30 + 5 overtrick = 35 per opponent
      expect(s, {'1': 105, '2': -35, '3': -35, '4': -35});
    });

    test('alone contract failed', () {
      final s = rules.scoreRound(c, deal('alone9', 7));
      // 20 + 5 * 2 = 30 per opponent
      expect(s, {'1': -90, '2': 30, '3': 30, '4': 30});
    });

    test('piek needs exactly one trick, no per-trick extras', () {
      expect(rules.scoreRound(c, deal('piek', 1))['1'], 45);
      expect(rules.scoreRound(c, deal('piek', 2))['1'], -45);
      expect(rules.scoreRound(c, deal('piek', 0))['1'], -45);
    });

    test('misère needs zero tricks', () {
      expect(rules.scoreRound(c, deal('misere', 0))['1'], 75);
      expect(rules.scoreRound(c, deal('misere', 1))['1'], -75);
    });

    test('open misère met praatje and dertien alleen', () {
      expect(rules.scoreRound(c, deal('openMisereTalk', 0))['2'], -60);
      expect(rules.scoreRound(c, deal('alone13', 13))['1'], 210);
    });
  });

  test('every contract is zero-sum for every number of tricks', () {
    for (final contract in rikContracts) {
      for (var tricks = 0; tricks <= 13; tricks++) {
        for (final maatPays in [false, true]) {
          final r = deal(contract.id, tricks,
              partner: contract.partner ? '2' : null);
          final o = rules.outcome(cfg({'maatPaysWhenLost': maatPays}), r);
          expect(o.sum, 0, reason: '${contract.id} $tricks maatPays=$maatPays');
        }
      }
    }
  });

  test('the points table is editable', () {
    final custom = cfg({'base.misere': 40, 'perTrick': 10, 'slamBonus': 0});
    expect(rules.scoreRound(custom, deal('misere', 0))['1'], 120);
    expect(rules.scoreRound(custom, deal('alone8', 10))['1'], (10 + 20) * 3);
  });

  group('validation and flow', () {
    test('needs exactly one bidder and a known contract', () {
      final noBidder = RoundData(number: 1, entries: {
        for (final p in ids) p: {'role': 'opp', 'contract': 'rik', 'tricks': 8},
      });
      expect(rules.validateRound(c, noBidder), RoundIssue.missingEntry);
      expect(rules.validateRound(c, deal('nonsense', 8)), RoundIssue.missingEntry);
      expect(rules.validateRound(c, deal('alone8', 14)), RoundIssue.outOfRange);
      expect(rules.validateRound(c, deal('alone8', 8)), isNull);
    });

    test('totals follow the rounds and a correction recalculates', () {
      final rounds = [
        deal('alone8', 8), // bidder +30
        RoundData(number: 2, entries: deal('piek', 0, bidder: '2').entries), // fail
      ];
      expect(rules.totals(c, rounds), {'1': 30 + 15, '2': -10 - 45, '3': -10 + 15, '4': -10 + 15});
      rounds[1] = RoundData(number: 2, entries: deal('piek', 1, bidder: '2').entries);
      expect(rules.totals(c, rounds)['2'], -10 + 45);
      expect(rules.totals(c, rounds).values.reduce((a, b) => a + b), 0);
    });
  });
}
