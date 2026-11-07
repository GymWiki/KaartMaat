import 'game_rules.dart';

/// Base for games where a round's score is the sum of several amounts added
/// one by one (calculator style). Entry per participant:
/// `{ 'amounts': [int, ...] }`.
abstract class AmountsRules extends GameRules {
  const AmountsRules();

  static const maxAmount = 1000000;

  static List<int> amountsOf(Entry? entry) => [
        for (final n in (entry?['amounts'] as List?) ?? const [])
          if (n is num) n.toInt(),
      ];

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    for (final p in config.participants) {
      final list = round.entries[p]?['amounts'];
      if (list is! List) return RoundIssue.missingEntry;
      for (final n in list) {
        if (n is! int) return RoundIssue.invalidValue;
        if (n.abs() > maxAmount) return RoundIssue.outOfRange;
      }
    }
    return null;
  }

  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) => {
        for (final p in config.participants)
          p: amountsOf(round.entries[p]).fold(0, (a, b) => a + b),
      };
}
