import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/ui/suits.dart';
import 'package:kaartmaat/features/games/games_registry.dart';

void main() {
  test('every game has a fixed suit; the three named games are set', () {
    expect(gameDefinitions['hartenjagen']!.suit, Suit.hearts);
    expect(gameDefinitions['klaverjassen']!.suit, Suit.clubs);
    expect(gameDefinitions['rikken']!.suit, Suit.diamonds);
  });

  test('the other games keep the suit they had on the home screen', () {
    expect(gameDefinitions['boerenbridge']!.suit, Suit.spades);
    expect(gameDefinitions['toepen']!.suit, Suit.spades);
    expect(gameDefinitions['jokeren']!.suit, Suit.hearts);
    expect(gameDefinitions['canasta']!.suit, Suit.clubs);
    expect(gameDefinitions['duizenden']!.suit, Suit.diamonds);
    expect(gameDefinitions['custom']!.suit, Suit.spades);
  });

  test('the four suits are spread evenly (counts differ by at most one)', () {
    final counts = {for (final s in Suit.values) s: 0};
    for (final d in gameDefinitions.values) {
      counts[d.suit] = counts[d.suit]! + 1;
    }
    final values = counts.values.toList()..sort();
    expect(values.last - values.first, lessThanOrEqualTo(1), reason: '$counts');
  });
}
