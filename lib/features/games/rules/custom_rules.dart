import 'game_rules.dart';

/// Free-form game: every round each participant gets a number of points.
class CustomRules extends GameRules {
  const CustomRules();

  static const typeId = 'custom';
  static const targetScoreKey = 'targetScore';
  static const lowestWinsKey = 'lowestWins';

  @override
  String get type => typeId;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 8;

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(
          key: targetScoreKey,
          kind: SettingKind.integer,
          defaultValue: 0,
          max: 100000,
        ),
        SettingSpec(
          key: lowestWinsKey,
          kind: SettingKind.boolean,
          defaultValue: false,
        ),
      ];

  @override
  bool higherIsBetter(GameConfig config) => !config.boolSetting(lowestWinsKey);

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    for (final p in config.participants) {
      final value = round.entries[p]?['points'];
      if (value == null) return RoundIssue.missingEntry;
      if (value is! int) return RoundIssue.invalidValue;
    }
    return null;
  }

  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) => {
        for (final p in config.participants)
          p: (round.entries[p]?['points'] as num?)?.toInt() ?? 0,
      };

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) {
    final target = config.intSetting(targetScoreKey);
    if (target <= 0) return false;
    return totals(config, rounds).values.any((t) => t >= target);
  }
}
