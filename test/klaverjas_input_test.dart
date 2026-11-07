import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';

const rules = KlaverjasRules();

GameConfig cfg() => GameConfig(
      type: 'klaverjassen',
      participants: const ['wij', 'zij'],
      players: const ['a', 'b', 'c', 'd'],
      settings: rules.defaultSettings,
    );

void main() {
  test('the team of the player left of the dealer is preselected', () {
    // dealer a (Wij) -> forehand b (Zij); dealer b -> c (Wij); and so on
    expect([for (var n = 1; n <= 5; n++) rules.forehandTeam(cfg(), n)],
        ['zij', 'wij', 'zij', 'wij', 'zij']);
  });

  test('card points typed so far stay within 0..162', () {
    for (final ok in ['', '0', '7', '95', '162', '16']) {
      expect(KlaverjasRules.isValidCardsText(ok), true, reason: ok);
    }
    for (final bad in ['163', '999', '-1', 'x', '1620']) {
      expect(KlaverjasRules.isValidCardsText(bad), false, reason: bad);
    }
  });

  test('the other team always gets the rest of the 162', () {
    for (var cards = 0; cards <= 162; cards += 9) {
      final round = RoundData(number: 1, entries: {
        'wij': {'playing': true, 'pit': false, 'cards': cards},
        'zij': {'playing': false, 'pit': false, 'cards': 162 - cards},
      });
      expect(rules.validateRound(cfg(), round), isNull, reason: '$cards');
      final points = rules.outcome(cfg(), round).points;
      expect(points['wij']! + points['zij']!, 162, reason: '$cards');
    }
  });
}
