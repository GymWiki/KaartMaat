import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/toepen_rules.dart';

const rules = ToepenRules();
const ids = ['a', 'b', 'c', 'd'];

GameConfig cfg([Map<String, Object?> o = const {}]) => GameConfig(
      type: 'toepen',
      participants: ids,
      settings: {...rules.defaultSettings, ...o},
    );

RoundData won(int n, String winner) => RoundData(number: n, entries: {
      for (final p in ids) p: {'winner': p == winner, 'knocks': 0},
    });

void main() {
  final c = cfg();
  final fresh = rules.situation(c, const []);

  test('the stake is the knocks plus one', () {
    expect(ToepenRules.stakeFor(0), 1);
    expect(ToepenRules.stakeFor(2), 3);
  });

  group('building the entries', () {
    test('the winner and everybody who stays in carry only the knocks', () {
      final e = rules.buildEntries(c, fresh, winner: 'a', knocks: 1, fold: {});
      expect(e['a'], {'winner': true, 'knocks': 1});
      expect(e['b'], {'winner': false, 'knocks': 1});
    });

    test('a fold is kept for a loser within the knocks so far', () {
      final e = rules.buildEntries(c, fresh, winner: 'a', knocks: 2, fold: {'b': 1, 'c': 2});
      expect(e['b']!['foldAt'], 1);
      expect(e['c']!['foldAt'], 2);
      expect(e['d']!.containsKey('foldAt'), false);
    });

    test('a fold of the winner, or beyond the knocks, is dropped', () {
      final e = rules.buildEntries(c, fresh, winner: 'a', knocks: 1, fold: {'a': 1, 'b': 3});
      expect(e['a']!.containsKey('foldAt'), false);
      expect(e['b']!.containsKey('foldAt'), false);
    });

    test('players who are out never get a fold', () {
      final tight = cfg({'limit': 2, 'poverty': false});
      final rounds = [won(1, 'a'), won(2, 'a')]; // b, c, d are out
      final sit = rules.situation(tight, rounds);
      final e = rules.buildEntries(tight, sit, winner: 'a', knocks: 1, fold: {'b': 1});
      expect(e['b']!.containsKey('foldAt'), false);
    });

    test('with poverty the first knock is automatic, so a fold at 1 is allowed', () {
      final tight = cfg({'limit': 4});
      final rounds = [won(1, 'a'), won(2, 'a'), won(3, 'a')]; // b, c, d on 3 = poverty
      final sit = rules.situation(tight, rounds);
      expect(sit.poverty, {'b', 'c', 'd'});
      final e = rules.buildEntries(tight, sit, winner: 'a', knocks: 0, fold: {'b': 1});
      expect(e['b']!['foldAt'], 1);
    });
  });

  test('scores from the panel entries follow the rules, including poverty', () {
    final tight = cfg({'limit': 4});
    final rounds = [won(1, 'a'), won(2, 'a'), won(3, 'a')];
    final sit = rules.situation(tight, rounds);
    // poverty: automatic knock, so losers who stay get 2, a folder 1
    final e = rules.buildEntries(tight, sit, winner: 'a', knocks: 0, fold: {'b': 1});
    final scores =
        rules.roundScores(tight, [...rounds, RoundData(number: 4, entries: e)]).last;
    expect(scores, {'a': 0, 'b': 1, 'c': 2, 'd': 2});
  });
}
