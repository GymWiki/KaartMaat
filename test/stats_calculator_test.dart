import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/stats/stats_calculator.dart';

const anna = PlayerRef(id: 1, name: 'Anna');
const bas = PlayerRef(id: 2, name: 'Bas');
const chris = PlayerRef(id: 3, name: 'Chris');

/// A finished "custom" game; [points] per player id for a single round.
GameState game(
  int id,
  DateTime finished,
  Map<int, int> points, {
  String type = 'custom',
  int? groupId,
  Map<String, Object?> settings = const {},
}) =>
    GameState(
      id: id,
      type: type,
      createdAt: finished,
      finishedAt: finished,
      settings: {'lowestWins': false, ...settings},
      players: [for (final p in [anna, bas, chris]) if (points.containsKey(p.id)) p],
      rounds: [
        RoundData(number: 1, entries: {
          for (final e in points.entries) '${e.key}': {'points': e.value},
        }),
      ],
      groupId: groupId,
    );

void main() {
  final games = [
    game(1, DateTime(2026, 3, 1), {1: 50, 2: 10, 3: 5}, groupId: 7), // Anna
    game(2, DateTime(2026, 4, 1), {1: 5, 2: 40, 3: 20}), // Bas
    game(3, DateTime(2026, 5, 1), {1: 60, 2: 10}, groupId: 7), // Anna
    game(4, DateTime(2025, 12, 1), {2: 30, 3: 10}, groupId: 7), // Bas, 2025
    game(5, DateTime(2026, 6, 1), {1: 0, 2: 10, 3: 30}, type: 'custom'), // Chris
  ];

  test('filters by group, year and type', () {
    expect(applyFilter(games, const GameFilter(groupId: 7)).map((g) => g.id), [1, 3, 4]);
    expect(applyFilter(games, const GameFilter(year: 2026)).map((g) => g.id),
        [1, 2, 3, 5]);
    expect(
        applyFilter(games, const GameFilter(year: 2026, groupId: 7)).map((g) => g.id),
        [1, 3]);
    expect(applyFilter(games, const GameFilter(type: 'boerenbridge')), isEmpty);
  });

  test('only finished games count', () {
    final open = GameState(
      id: 9,
      type: 'custom',
      createdAt: DateTime(2026, 1, 1),
      finishedAt: null,
      settings: const {},
      players: const [anna, bas],
      rounds: const [],
    );
    expect(applyFilter([open], const GameFilter()), isEmpty);
  });

  test('years are listed newest first', () {
    expect(yearsOf(games), [2026, 2025]);
  });

  test('leaderboard: wins, win percentage and best score', () {
    final stats = computeStats(games, withBestScore: true);
    final byName = {for (final s in stats) s.name: s};
    expect(byName['Anna']!.played, 4);
    expect(byName['Anna']!.wins, 2);
    expect(byName['Anna']!.winPct, 50);
    expect(byName['Anna']!.bestScore, 60);
    expect(byName['Bas']!.wins, 2); // games 2 and 4
    expect(byName['Chris']!.wins, 1);
    // Anna and Bas both have 2 wins, Bas played more games (win% lower)
    expect(stats.first.name, 'Anna');
  });

  test('lowest wins games report the lowest total as best score', () {
    final low = [
      game(1, DateTime(2026, 1, 1), {1: 30, 2: 12}, settings: {'lowestWins': true}),
      game(2, DateTime(2026, 1, 2), {1: 5, 2: 25}, settings: {'lowestWins': true}),
    ];
    final stats = computeStats(low, withBestScore: true);
    expect({for (final s in stats) s.name: s.bestScore}, {'Anna': 5, 'Bas': 12});
    expect({for (final s in stats) s.name: s.wins}, {'Anna': 1, 'Bas': 1});
  });

  group('Kaartkoning van het jaar', () {
    test('most wins in the year', () {
      final king = kaartkoning(games, 2026)!;
      expect(king.name, 'Anna'); // 2 wins in 2026 (games 1, 3)
      expect(king.wins, 2);
    });

    test('tie on wins is decided by win percentage', () {
      final tie = [
        game(1, DateTime(2026, 1, 1), {1: 10, 2: 0}), // Anna wins
        game(2, DateTime(2026, 1, 2), {1: 0, 2: 10}), // Bas wins
        game(3, DateTime(2026, 1, 3), {1: 0, 2: 10, 3: 0}), // Bas wins
        game(4, DateTime(2026, 1, 4), {1: 10, 3: 0}), // Anna wins
        game(5, DateTime(2026, 1, 5), {1: 0, 2: 10}), // Bas wins
        game(6, DateTime(2026, 1, 6), {1: 0, 3: 10}), // Chris wins
        game(7, DateTime(2026, 1, 7), {3: 0, 2: 0}), // tie, both win
      ];
      // Bas: wins 4 of 5; Anna: 2 of 4; Chris: 2 of 3
      expect(kaartkoning(tie, 2026)!.name, 'Bas');
    });

    test('respects the group and returns null without wins', () {
      expect(kaartkoning(games, 2026, groupId: 7)!.name, 'Anna');
      expect(kaartkoning(games, 2024), isNull);
    });
  });
}
