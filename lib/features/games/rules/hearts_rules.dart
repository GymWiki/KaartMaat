import 'game_rules.dart';

/// Hartenjagen (Hearts, Black Lady). Every deal 26 penalty points are
/// handed out (13 hearts at 1 point, the queen of spades at 13); the lowest
/// total wins and the game ends when someone reaches the target (100).
///
/// Entry per player: `{ 'points': int, 'moon': bool }`.
///
/// "De maan schieten" (one player takes every penalty card): by default the
/// shooter gets 0 and everybody else the full total ([moonOthers]); the
/// alternative is that the shooter gets minus the total ([moonShooter]).
/// Pagat lists both, nl.wikipedia only the first, so it is a setting.
/// Other variants (Dutch piket with 15 points, Argentinian 45, ...) work by
/// changing [totalPointsKey] and [queenPointsKey].
class HeartsRules extends GameRules {
  const HeartsRules();

  static const typeId = 'hartenjagen';
  static const totalPointsKey = 'totalPoints';
  static const queenPointsKey = 'queenPoints';
  static const targetScoreKey = 'targetScore';
  static const moonEnabledKey = 'moonEnabled';
  static const moonModeKey = 'moonMode';

  static const moonOthers = 'others';
  static const moonShooter = 'shooter';

  @override
  String get type => typeId;

  @override
  int get minPlayers => 3;

  @override
  int get maxPlayers => 6;

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(
          key: totalPointsKey,
          kind: SettingKind.integer,
          defaultValue: 26,
          min: 1,
          max: 100,
        ),
        SettingSpec(
          key: queenPointsKey,
          kind: SettingKind.integer,
          defaultValue: 13,
          min: 1,
          max: 100,
        ),
        SettingSpec(
          key: targetScoreKey,
          kind: SettingKind.integer,
          defaultValue: 100,
          max: 10000,
        ),
        SettingSpec(
          key: moonEnabledKey,
          kind: SettingKind.boolean,
          defaultValue: true,
        ),
        SettingSpec(
          key: moonModeKey,
          kind: SettingKind.choice,
          defaultValue: moonOthers,
          options: [moonOthers, moonShooter],
        ),
      ];

  @override
  bool higherIsBetter(GameConfig config) => false;

  /// What each player gets when [shooter] shoots the moon.
  Map<String, int> moonPoints(GameConfig config, String shooter) {
    final total = config.intSetting(totalPointsKey);
    final others = config.settings[moonModeKey] != moonShooter;
    return {
      for (final p in config.participants)
        p: p == shooter ? (others ? 0 : -total) : (others ? total : 0),
    };
  }

  static String? shooterOf(GameConfig config, RoundData round) {
    for (final p in config.participants) {
      if (round.entries[p]?['moon'] == true) return p;
    }
    return null;
  }

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    for (final p in config.participants) {
      final points = round.entries[p]?['points'];
      if (points is! int) return RoundIssue.missingEntry;
    }
    final shooters = config.participants
        .where((p) => round.entries[p]?['moon'] == true)
        .toList();
    if (shooters.length > 1) return RoundIssue.invalidValue;
    if (shooters.isNotEmpty) {
      if (!config.boolSetting(moonEnabledKey)) return RoundIssue.invalidValue;
      final expected = moonPoints(config, shooters.first);
      for (final p in config.participants) {
        if (round.entries[p]!['points'] != expected[p]) {
          return RoundIssue.invalidValue;
        }
      }
      return null;
    }
    var sum = 0;
    for (final p in config.participants) {
      final points = round.entries[p]!['points'] as int;
      if (points < 0) return RoundIssue.outOfRange;
      sum += points;
    }
    return sum == config.intSetting(totalPointsKey) ? null : RoundIssue.tricksMismatch;
  }

  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) => {
        for (final p in config.participants)
          p: (round.entries[p]?['points'] as num?)?.toInt() ?? 0,
      };

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) {
    final target = config.intSetting(targetScoreKey);
    return target > 0 && totals(config, rounds).values.any((t) => t >= target);
  }
}
