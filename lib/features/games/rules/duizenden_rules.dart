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

  /// Allowed score per player per round, in one place. Anything outside is
  /// blocked, to catch typos. These are not settings: older saved games may
  /// still carry minEntry/maxEntry values, which are simply ignored.
  static const minEntry = -999;
  static const maxEntry = 9999;

  /// Most characters a typed score can have (digits plus a minus sign are
  /// counted by the pad as digits only).
  static final int maxDigits = [
    maxEntry.abs().toString().length,
    minEntry.abs().toString().length,
  ].reduce((a, b) => a > b ? a : b);

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
  ];

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    for (final p in config.participants) {
      final value = round.entries[p]?['points'];
      if (value == null) return RoundIssue.missingEntry;
      if (value is! int) return RoundIssue.invalidValue;
      if (value < minEntry || value > maxEntry) return RoundIssue.outOfRange;
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
