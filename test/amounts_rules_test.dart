import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/canasta_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/jokeren_rules.dart';

RoundData amounts(int n, Map<String, List<int>> byPlayer) => RoundData(
      number: n,
      entries: {for (final e in byPlayer.entries) e.key: {'amounts': e.value}},
    );

void main() {
  group('Jokeren', () {
    const rules = JokerenRules();
    GameConfig cfg([Map<String, Object?> o = const {}]) => GameConfig(
          type: 'jokeren',
          participants: const ['a', 'b', 'c'],
          settings: {...rules.defaultSettings, ...o},
        );

    test('amounts are added up per player', () {
      final r = amounts(1, {
        'a': [25, 11, 10],
        'b': [],
        'c': [7, 8],
      });
      expect(rules.scoreRound(cfg(), r), {'a': 46, 'b': 0, 'c': 15});
    });

    test('lowest wins by default, and can be switched', () {
      final rounds = [
        amounts(1, {'a': [10], 'b': [0], 'c': [30]}),
      ];
      expect(rules.winners(cfg(), rounds), ['b']);
      expect(rules.winners(cfg({'lowestWins': false}), rounds), ['c']);
    });

    test('ends after 10 rounds, 0 means unlimited, target score ends it too', () {
      final one = amounts(1, {'a': [1], 'b': [2], 'c': [3]});
      final ten = [for (var i = 1; i <= 10; i++) one];
      expect(rules.isFinished(cfg(), ten.take(9).toList()), false);
      expect(rules.isFinished(cfg(), ten), true);
      expect(rules.isFinished(cfg({'rounds': 0}), ten), false);
      expect(rules.isFinished(cfg({'rounds': 0, 'targetScore': 40}), ten), false);
      expect(rules.isFinished(cfg({'rounds': 0, 'targetScore': 30}), ten), true);
    });

    test('validation', () {
      expect(rules.validateRound(cfg(), amounts(1, {'a': [1], 'b': [], 'c': [2]})),
          isNull);
      expect(rules.validateRound(cfg(), amounts(1, {'a': [1], 'b': []})),
          RoundIssue.missingEntry);
      expect(rules.validateRound(cfg(), amounts(1, {'a': [9999999], 'b': [], 'c': []})),
          RoundIssue.outOfRange);
    });

    test('correcting a round recalculates the totals', () {
      final rounds = [amounts(1, {'a': [5], 'b': [5], 'c': [5]})];
      rounds[0] = amounts(1, {'a': [5, 5], 'b': [1], 'c': []});
      expect(rules.totals(cfg(), rounds), {'a': 10, 'b': 1, 'c': 0});
    });
  });

  group('Canasta', () {
    const rules = CanastaRules();
    final cfg = GameConfig(
      type: 'canasta',
      participants: const ['wij', 'zij'],
      players: const ['a', 'b', 'c', 'd'],
      settings: rules.defaultSettings,
    );

    test('teams: seats 1+3 against 2+4', () {
      expect(rules.participantsFor(const ['a', 'b', 'c', 'd']), ['wij', 'zij']);
      expect(rules.membersOf(cfg, 'wij'), ['a', 'c']);
      expect(rules.membersOf(cfg, 'zij'), ['b', 'd']);
    });

    test('a hand adds bonuses and cards and subtracts the cards in hand', () {
      // natural canasta 500 + 70 card points + going out 100 - 15 in hand
      final r = amounts(1, {
        'wij': [500, 70, 100, -15],
        'zij': [-300, 200],
      });
      expect(rules.scoreRound(cfg, r), {'wij': 655, 'zij': -100});
    });

    test('the game ends when a team reaches 5000', () {
      final big = amounts(1, {'wij': [4999], 'zij': [0]});
      expect(rules.isFinished(cfg, [big]), false);
      expect(rules.isFinished(cfg, [big, amounts(2, {'wij': [1], 'zij': [0]})]), true);
      expect(rules.winners(cfg, [big, amounts(2, {'wij': [1], 'zij': [0]})]), ['wij']);
    });

    test('initial meld minimum depends on the score (Classic)', () {
      expect(CanastaRules.initialMeldMinimum(-50), 15);
      expect(CanastaRules.initialMeldMinimum(0), 50);
      expect(CanastaRules.initialMeldMinimum(1495), 50);
      expect(CanastaRules.initialMeldMinimum(1500), 90);
      expect(CanastaRules.initialMeldMinimum(2995), 90);
      expect(CanastaRules.initialMeldMinimum(3000), 120);
    });
  });
}
