import 'game_rules.dart';

/// Free-form game: every round each participant gets a number of points.
class CustomRules extends GameRules {
  const CustomRules();

  static const typeId = 'custom';
  static const targetScoreKey = 'targetScore';
  static const lowestWinsKey = 'lowestWins';

  /// Amount the plus/minus buttons add per tap (entry UI only).
  static const stepKey = 'step';

  /// How scores are entered: "add" (tap buttons to add points, live) or
  /// "enter" (type every player's score per round on the number pad). Stored
  /// with the game; games saved before it existed count as "add".
  static const inputModeKey = 'inputMode';
  static const inputModeAdd = 'add';
  static const inputModeEnter = 'enter';

  static bool isEnterMode(GameConfig config) =>
      config.settings[inputModeKey] == inputModeEnter;

  @override
  String get type => typeId;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 8;

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(
          key: inputModeKey,
          kind: SettingKind.choice,
          defaultValue: inputModeAdd,
          options: [inputModeAdd, inputModeEnter],
          segmented: true,
        ),
        SettingSpec(
          key: stepKey,
          kind: SettingKind.integer,
          defaultValue: 1,
          min: 1,
          max: 1000,
          visibleIf: (inputModeKey, inputModeAdd),
        ),
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

  /// An empty round (everybody on 0), the start of a new counting round.
  static Entries zeroEntries(GameConfig config) => {
        for (final p in config.participants) p: {'points': 0},
      };

  /// The step the plus button starts with (never below 1).
  static int defaultStep(GameConfig config) {
    final s = config.intSetting(stepKey);
    return s < 1 ? 1 : s;
  }

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
