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

void main() {
  final c = cfg();

  test('13 hearts plus the queen make up the 26 points', () {
    expect(rules.heartsTotal(c), 13);
    expect(rules.pointsFor(c, hearts: 4, hasQueen: true), 17);
    expect(rules.pointsFor(c, hearts: 4, hasQueen: false), 4);
    // other variants follow the settings (Dutch piket: 15 points, queen 5)
    expect(rules.heartsTotal(cfg({'totalPoints': 15, 'queenPoints': 5})), 10);
  });

  test('hearts left for a player do not count the last seat', () {
    expect(rules.heartsLeftFor(c, 'a', {'b': 3, 'c': 2}), 8);
    expect(rules.heartsLeftFor(c, 'a', {'b': 3, 'c': 2, 'd': 9}), 8);
    expect(rules.heartsLeftFor(c, 'b', {'a': 13}), 0);
  });

  group('the last seat is filled in', () {
    test('with the hearts nobody took, and the queen by default', () {
      final r = rules.autoLast(c, {'a': 3, 'b': 2, 'c': 1}, null)!;
      expect(r.hearts, 7);
      expect(r.hasQueen, true);
    });

    test('without the queen when somebody else holds it', () {
      final r = rules.autoLast(c, {'a': 3, 'b': 2, 'c': 1}, 'b')!;
      expect(r.hearts, 7);
      expect(r.hasQueen, false);
    });

    test('nothing until the others are in, nothing when they took too many', () {
      expect(rules.autoLast(c, {'a': 3, 'b': 2}, null), isNull);
      expect(rules.autoLast(c, {'a': 8, 'b': 4, 'c': 2}, null), isNull);
    });
  });

  test('every distribution the panel can build is a valid round', () {
    for (var a = 0; a <= 13; a++) {
      for (var b = 0; b <= 13 - a; b++) {
        for (final holder in [null, 'a', 'b', 'c', 'd']) {
          final entries = rules.buildEntries(
            c,
            hearts: {'a': a, 'b': b, 'c': 1},
            queenHolder: holder,
            moon: null,
          );
          if (a + b + 1 > 13) {
            expect(entries, isNull);
            continue;
          }
          expect(entries, isNotNull);
          final round = RoundData(number: 1, entries: entries!);
          expect(rules.validateRound(c, round), isNull, reason: '$a $b $holder');
          expect(rules.totals(c, [round]).values.reduce((x, y) => x + y), 26);
        }
      }
    }
  });

  test('the moon replaces everything, in both modes', () {
    final others = rules.buildEntries(c, hearts: {}, queenHolder: null, moon: 'b')!;
    expect([for (final p in ids) others[p]!['points']], [26, 0, 26, 26]);
    expect(rules.validateRound(c, RoundData(number: 1, entries: others)), isNull);

    final alt = cfg({'moonMode': 'shooter'});
    final shooter = rules.buildEntries(alt, hearts: {}, queenHolder: null, moon: 'b')!;
    expect([for (final p in ids) shooter[p]!['points']], [0, -26, 0, 0]);
    expect(rules.validateRound(alt, RoundData(number: 1, entries: shooter)), isNull);
  });

  test('the stored entry remembers who had the queen', () {
    final entries = rules.buildEntries(c,
        hearts: {'a': 1, 'b': 1, 'c': 1}, queenHolder: 'c', moon: null)!;
    expect(entries['c']!['queen'], true);
    expect(entries['a']!['queen'], false);
    expect(entries['d']!['queen'], false);
  });
}
