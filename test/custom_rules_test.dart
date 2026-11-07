import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';

void main() {
  const rules = CustomRules();
  GameConfig cfg({int target = 0, bool lowest = false}) => GameConfig(
        type: 'custom',
        participants: const ['1', '2', '3'],
        settings: {'targetScore': target, 'lowestWins': lowest},
      );
  RoundData round(int n, int a, int b, int c) => RoundData(number: n, entries: {
        '1': {'points': a},
        '2': {'points': b},
        '3': {'points': c},
      });

  test('totals are derived and a corrected round changes them', () {
    final rounds = [round(1, 10, 5, 0), round(2, 0, 20, 5)];
    expect(rules.totals(cfg(), rounds), {'1': 10, '2': 25, '3': 5});
    rounds[0] = round(1, 40, 5, 0);
    expect(rules.totals(cfg(), rounds), {'1': 40, '2': 25, '3': 5});
  });

  test('ties share a rank and all tied leaders win', () {
    final rounds = [round(1, 10, 10, 3)];
    final s = rules.standings(cfg(), rounds);
    expect(s.map((e) => e.rank), [1, 1, 3]);
    expect(rules.winners(cfg(), rounds), ['1', '2']);
  });

  test('lowestWins reverses ranking', () {
    final rounds = [round(1, 10, 2, 7)];
    expect(rules.winners(cfg(lowest: true), rounds), ['2']);
  });

  test('target score ends the game', () {
    expect(rules.isFinished(cfg(target: 50), [round(1, 49, 0, 0)]), false);
    expect(rules.isFinished(cfg(target: 50), [round(1, 49, 0, 0), round(2, 1, 0, 0)]), true);
    expect(rules.isFinished(cfg(), [round(1, 999, 0, 0)]), false);
  });

  test('step defaults to 1 and does not change scoring', () {
    expect(rules.defaultSettings['step'], 1);
    final withStep = GameConfig(
      type: 'custom',
      participants: const ['1', '2', '3'],
      settings: const {'step': 25},
    );
    expect(rules.totals(withStep, [round(1, 10, -5, 0)]),
        {'1': 10, '2': -5, '3': 0});
  });

  test('lowestWins with a target ends when someone reaches it', () {
    final c = cfg(target: 30, lowest: true);
    expect(rules.isFinished(c, [round(1, 29, 2, 5)]), false);
    expect(rules.isFinished(c, [round(1, 29, 2, 5), round(2, 1, 0, 0)]), true);
    expect(rules.winners(c, [round(1, 29, 2, 5), round(2, 1, 0, 0)]), ['2']);
  });

  test('validation', () {
    expect(rules.validateRound(cfg(), round(1, 1, 2, 3)), isNull);
    expect(
      rules.validateRound(cfg(), const RoundData(number: 1, entries: {'1': {'points': 1}})),
      RoundIssue.missingEntry,
    );
  });
}
