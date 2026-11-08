import 'game_rules.dart';

/// Duizenden: over several rounds everybody collects points, the first to
/// reach the target (default 1000) wins. A round score can be negative.
///
/// Entry per player: `{ 'points': int }`. The app records one number per
/// player per round, nothing about cards or melds.
///
/// The game is only judged at the end of a round: when one or more players
/// have the target or more after a saved round, the game is over and the
/// highest total wins (an exact tie is a shared win). Going past the target
/// is fine; the highest total counts, not "exactly 1000".
class DuizendenRules extends GameRules {
  const DuizendenRules();

  static const typeId = 'duizenden';
  static const targetScoreKey = 'targetScore';

  /// Allowed score per player per round. Anything outside is blocked, to
  /// catch typos.
  static const minEntryKey = 'minEntry';
  static const maxEntryKey = 'maxEntry';

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
      defaultValue: 1000,
      max: 100000,
    ),
    SettingSpec(
      key: minEntryKey,
      kind: SettingKind.integer,
      defaultValue: -999,
      min: -99999,
      max: 0,
    ),
    SettingSpec(
      key: maxEntryKey,
      kind: SettingKind.integer,
      defaultValue: 9999,
      max: 99999,
    ),
  ];

  int minEntry(GameConfig config) =>
      (config.settings[minEntryKey] as num?)?.toInt() ?? -999;

  int maxEntry(GameConfig config) =>
      (config.settings[maxEntryKey] as num?)?.toInt() ?? 9999;

  /// Most characters a typed score can have, so the pad can stop in time.
  int maxDigits(GameConfig config) {
    final hi = maxEntry(config).abs().toString().length;
    final lo = minEntry(config).abs().toString().length;
    return hi > lo ? hi : lo;
  }

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    final lo = minEntry(config), hi = maxEntry(config);
    for (final p in config.participants) {
      final value = round.entries[p]?['points'];
      if (value == null) return RoundIssue.missingEntry;
      if (value is! int) return RoundIssue.invalidValue;
      if (value < lo || value > hi) return RoundIssue.outOfRange;
    }
    return null;
  }

  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) => {
    for (final p in config.participants)
      p: (round.entries[p]?['points'] as num?)?.toInt() ?? 0,
  };

  /// Points still needed to reach the target; 0 when it is reached or when
  /// there is no target.
  int toGo(GameConfig config, int total) {
    final target = config.intSetting(targetScoreKey);
    return target > 0 && total < target ? target - total : 0;
  }

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) {
    final target = config.intSetting(targetScoreKey);
    return rounds.isNotEmpty &&
        target > 0 &&
        totals(config, rounds).values.any((t) => t >= target);
  }
}
