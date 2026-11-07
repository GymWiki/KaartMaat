import 'amounts_rules.dart';
import 'game_rules.dart';

/// Jokeren (Dutch rummy): per player, per round, amounts are added up.
///
/// nl.wikipedia: the winner of a deal gets 0, the others get penalty points
/// for what is left in their hand, and 10 deals are played. The page mixes
/// card values (joker 25, ace 11, face cards 10) with "number of cards" as
/// the penalty, so what to enter is up to the table: the quick buttons add
/// the card values, any amount can be typed. Lowest wins by default.
class JokerenRules extends AmountsRules {
  const JokerenRules();

  static const typeId = 'jokeren';
  static const lowestWinsKey = 'lowestWins';
  static const targetScoreKey = 'targetScore';
  static const roundsKey = 'rounds';
  static const quickJokerKey = 'quickJoker';
  static const quickAceKey = 'quickAce';
  static const quickFaceKey = 'quickFace';

  @override
  String get type => typeId;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 8;

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(key: lowestWinsKey, kind: SettingKind.boolean, defaultValue: true),
        SettingSpec(key: roundsKey, kind: SettingKind.integer, defaultValue: 10, max: 99),
        SettingSpec(
            key: targetScoreKey, kind: SettingKind.integer, defaultValue: 0, max: 100000),
        SettingSpec(key: quickJokerKey, kind: SettingKind.integer, defaultValue: 25, max: 1000),
        SettingSpec(key: quickAceKey, kind: SettingKind.integer, defaultValue: 11, max: 1000),
        SettingSpec(key: quickFaceKey, kind: SettingKind.integer, defaultValue: 10, max: 1000),
      ];

  @override
  bool higherIsBetter(GameConfig config) => !config.boolSetting(lowestWinsKey);

  @override
  int? plannedRounds(GameConfig config) {
    final n = config.intSetting(roundsKey);
    return n > 0 ? n : null;
  }

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) {
    final planned = plannedRounds(config);
    if (planned != null && rounds.length >= planned) return true;
    final target = config.intSetting(targetScoreKey);
    return target > 0 && totals(config, rounds).values.any((t) => t >= target);
  }
}
