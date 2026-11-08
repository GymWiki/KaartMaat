import 'amounts_rules.dart';
import 'game_rules.dart';

/// Classic Canasta with 4 players in two partnerships (Pagat): per hand a team
/// scores its bonuses plus the cards it melded minus the cards left in hand,
/// added up as amounts. The game ends when a team has the target (5000) or
/// more at the end of a hand; the highest total wins.
///
/// Only the Classic numbers were read literally from the source. The American
/// variant (target 8500, other meld minimums) is reachable via the settings.
class CanastaRules extends AmountsRules {
  const CanastaRules();

  static const typeId = 'canasta';
  static const wij = 'wij';
  static const zij = 'zij';

  static const targetScoreKey = 'targetScore';
  static const targetInclusiveKey = 'targetInclusive';
  static const naturalCanastaKey = 'naturalCanasta';
  static const mixedCanastaKey = 'mixedCanasta';
  static const goOutKey = 'goOut';
  static const goOutConcealedKey = 'goOutConcealed';
  static const redThreeKey = 'redThree';
  static const allRedThreesKey = 'allRedThrees';

  @override
  String get type => typeId;

  @override
  int get minPlayers => 4;

  @override
  int get maxPlayers => 4;

  @override
  List<String> participantsFor(List<String> playerKeys) => const [wij, zij];

  @override
  List<String> membersOf(GameConfig config, String participant) {
    if (participant != wij && participant != zij) return [participant];
    final start = participant == wij ? 0 : 1;
    return [for (var i = start; i < config.players.length; i += 2) config.players[i]];
  }

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(
            key: targetScoreKey, kind: SettingKind.integer, defaultValue: 5000, max: 100000),
        // true: "5000 or more" ends the game, false: "more than 5000".
        SettingSpec(
            key: targetInclusiveKey, kind: SettingKind.boolean, defaultValue: true),
        SettingSpec(key: naturalCanastaKey, kind: SettingKind.integer, defaultValue: 500, max: 5000),
        SettingSpec(key: mixedCanastaKey, kind: SettingKind.integer, defaultValue: 300, max: 5000),
        SettingSpec(key: goOutKey, kind: SettingKind.integer, defaultValue: 100, max: 5000),
        SettingSpec(
            key: goOutConcealedKey, kind: SettingKind.integer, defaultValue: 200, max: 5000),
        SettingSpec(key: redThreeKey, kind: SettingKind.integer, defaultValue: 100, max: 5000),
        SettingSpec(key: allRedThreesKey, kind: SettingKind.integer, defaultValue: 800, max: 5000),
      ];

  /// Minimum value of the first meld, by the team's score before the hand
  /// (Classic: negative 15, 0-1495 50, 1500-2995 90, 3000 or more 120).
  static int initialMeldMinimum(int score) {
    if (score < 0) return 15;
    if (score < 1500) return 50;
    if (score < 3000) return 90;
    return 120;
  }

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) {
    final target = config.intSetting(targetScoreKey);
    final inclusive = config.settings[targetInclusiveKey] != false;
    return target > 0 &&
        totals(config, rounds).values.any((t) => inclusive ? t >= target : t > target);
  }
}
