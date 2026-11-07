import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/rikken_rules.dart';

const rules = RikkenRules();
const ids = ['1', '2', '3', '4'];

GameConfig cfg() => GameConfig(
      type: 'rikken',
      participants: ids,
      settings: rules.defaultSettings,
    );

RoundData deal(String contract, int tricks, {String bidder = '1', String? partner}) =>
    RoundData(number: 1, entries: {
      for (final p in ids)
        p: {
          'role': p == bidder ? 'bidder' : (p == partner ? 'partner' : 'opp'),
          'contract': contract,
          'tricks': tricks,
        },
    });

void main() {
  RikContract c(String id) => RikkenRules.contractOf(id)!;

  test('tricks follow from made / not made and the over- or undertricks', () {
    expect(RikkenRules.tricksFor(c('rik'), success: true, diff: 0), 8);
    expect(RikkenRules.tricksFor(c('rik'), success: true, diff: 3), 11);
    expect(RikkenRules.tricksFor(c('rik'), success: false, diff: 1), 7);
    expect(RikkenRules.tricksFor(c('alone10'), success: false, diff: 4), 6);
    // piek and misère: only the outcome matters
    expect(RikkenRules.tricksFor(c('piek'), success: true, diff: 0), 1);
    expect(RikkenRules.tricksFor(c('misere'), success: true, diff: 0), 0);
    expect(RikkenRules.madeWith(c('piek'), RikkenRules.tricksFor(c('piek'), success: false, diff: 0)), false);
    expect(RikkenRules.madeWith(c('misere'), RikkenRules.tricksFor(c('misere'), success: false, diff: 0)), false);
  });

  test('the steppers stay within what is possible', () {
    expect(RikkenRules.maxDiff(c('rik'), success: true), 5); // 13 - 8
    expect(RikkenRules.maxDiff(c('rik'), success: false), 8); // 8 - 0
    expect(RikkenRules.maxDiff(c('alone13'), success: true), 0);
    expect(RikkenRules.maxDiff(c('misere'), success: false), 0);
    expect(RikkenRules.minDiff(success: true), 0);
    expect(RikkenRules.minDiff(success: false), 1);
  });

  test('every number of tricks survives a round trip through the panel model', () {
    for (final contract in rikContracts) {
      for (var tricks = 0; tricks <= 13; tricks++) {
        final success = RikkenRules.madeWith(contract, tricks);
        final diff = RikkenRules.diffFor(contract, tricks);
        final back = RikkenRules.tricksFor(contract, success: success, diff: diff);
        if (contract.type == RikType.atLeast) {
          expect(back, tricks, reason: '${contract.id} $tricks');
        } else {
          expect(RikkenRules.madeWith(contract, back), success, reason: '${contract.id} $tricks');
        }
      }
    }
  });

  test('points from the panel model equal the points of the stored tricks', () {
    for (final contract in rikContracts) {
      for (final success in [true, false]) {
        for (var diff = RikkenRules.minDiff(success: success);
            diff <= RikkenRules.maxDiff(contract, success: success);
            diff++) {
          final tricks = RikkenRules.tricksFor(contract, success: success, diff: diff);
          final outcome =
              rules.outcome(cfg(), deal(contract.id, tricks, partner: contract.partner ? '2' : null));
          expect(outcome.success, success, reason: '${contract.id} $success $diff');
          expect(outcome.sum, 0);
        }
      }
    }
  });

  test('the latest contract is preselected, a plain rik at the start', () {
    expect(rules.defaultContract(cfg(), const []), 'rik');
    final rounds = [deal('piek', 1), deal('alone9', 9)];
    expect(rules.defaultContract(cfg(), rounds), 'alone9');
    expect(rules.defaultContract(cfg(), [rounds.first]), 'piek');
  });
}
