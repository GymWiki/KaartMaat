import 'game_rules.dart';

/// State before a round: who is out, who is in poverty ("in de armoe").
class ToepenSituation {
  const ToepenSituation({
    required this.totals,
    required this.out,
    required this.poverty,
  });

  final Map<String, int> totals;

  /// Players who reached the limit.
  final Set<String> out;

  /// Players one point short of the limit. Empty when the rule is off.
  final Set<String> poverty;

  List<String> alive(GameConfig config) =>
      [for (final p in config.participants) if (!out.contains(p)) p];
}

/// Toepen scoring (nl.wikipedia and Pagat agree on the core):
/// - the winner of the round gets 0;
/// - someone who folds at knock j gets j points;
/// - everyone else who plays on and loses gets (number of knocks + 1).
///
/// Entry per player: `{ 'winner': bool, 'knocks': k, 'foldAt': int? }`;
/// `knocks` is the same for everybody. A player in poverty counts as an extra
/// knock that is knock number 1 ([povertyKey], on by default as on
/// nl.wikipedia; Pagat treats it as a variant).
///
/// Players are out at [limitKey] points. The sources differ on the default
/// (nl.wikipedia 15, Pagat 10), so it is a setting, default 10. With
/// [playOnKey] the game goes on until one player is left; otherwise it ends
/// when the first player is out.
///
/// Not modelled: vuile was, kans op toep, blind toepen and the other regional
/// variants; enter their penalty points by correcting the round if needed.
class ToepenRules extends GameRules {
  const ToepenRules();

  static const typeId = 'toepen';
  static const limitKey = 'limit';
  static const povertyKey = 'poverty';
  static const playOnKey = 'playOn';

  @override
  String get type => typeId;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 8;

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(
            key: limitKey, kind: SettingKind.integer, defaultValue: 10, min: 2, max: 99),
        SettingSpec(key: povertyKey, kind: SettingKind.boolean, defaultValue: true),
        SettingSpec(key: playOnKey, kind: SettingKind.boolean, defaultValue: true),
      ];

  @override
  bool higherIsBetter(GameConfig config) => false;

  ToepenSituation situation(GameConfig config, List<RoundData> before) {
    final totals = {for (final p in config.participants) p: 0};
    final limit = config.intSetting(limitKey);
    for (final scores in roundScores(config, before)) {
      for (final p in config.participants) {
        totals[p] = totals[p]! + (scores[p] ?? 0);
      }
    }
    final out = {
      for (final p in config.participants)
        if (totals[p]! >= limit) p,
    };
    final poverty = config.boolSetting(povertyKey)
        ? {
            for (final p in config.participants)
              if (!out.contains(p) && totals[p] == limit - 1) p,
          }
        : <String>{};
    return ToepenSituation(totals: totals, out: out, poverty: poverty);
  }

  // ---- Helpers for the input panel -------------------------------------

  /// What a player who plays on and loses gets: the knocks plus one.
  static int stakeFor(int effectiveKnocks) => effectiveKnocks + 1;

  /// The round entries for the panel's state. Folds only count for players
  /// who are still in, are not the winner, and fall within the knocks so far
  /// (the automatic poverty knock counts as knock 1).
  Entries buildEntries(
    GameConfig config,
    ToepenSituation situation, {
    required String? winner,
    required int knocks,
    required Map<String, int?> fold,
  }) {
    final effective = knocks + (situation.poverty.isEmpty ? 0 : 1);
    return {
      for (final p in config.participants)
        p: {
          'winner': p == winner,
          'knocks': knocks,
          if (p != winner &&
              !situation.out.contains(p) &&
              fold[p] != null &&
              fold[p]! >= 1 &&
              fold[p]! <= effective)
            'foldAt': fold[p],
        },
    };
  }

  /// Knocks for the round, including the automatic poverty knock.
  int effectiveKnocks(RoundData round, bool poverty) {
    final k = _knocks(round);
    return k + (poverty ? 1 : 0);
  }

  int _knocks(RoundData round) {
    for (final e in round.entries.values) {
      final k = e['knocks'];
      if (k is int) return k;
    }
    return 0;
  }

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    var winners = 0;
    final k = _knocks(round);
    if (k < 0 || k > 30) return RoundIssue.outOfRange;
    for (final p in config.participants) {
      final e = round.entries[p];
      if (e == null) return RoundIssue.missingEntry;
      final win = e['winner'] == true;
      if (win) winners++;
      final fold = e['foldAt'];
      if (fold != null) {
        if (fold is! int || fold < 1 || fold > k + 1) return RoundIssue.outOfRange;
        if (win) return RoundIssue.invalidValue;
      }
    }
    return winners == 1 ? null : RoundIssue.missingEntry;
  }

  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) =>
      roundScores(config, [round]).first;

  @override
  List<Map<String, int>> roundScores(GameConfig config, List<RoundData> rounds) {
    final limit = config.intSetting(limitKey);
    final povertyOn = config.boolSetting(povertyKey);
    final totals = {for (final p in config.participants) p: 0};
    final result = <Map<String, int>>[];
    for (final round in rounds) {
      final scores = {for (final p in config.participants) p: 0};
      if (validateRound(config, round) == null) {
        final out = {
          for (final p in config.participants)
            if (totals[p]! >= limit) p,
        };
        final poverty = povertyOn &&
            config.participants
                .any((p) => !out.contains(p) && totals[p] == limit - 1);
        final k = effectiveKnocks(round, poverty);
        for (final p in config.participants) {
          if (out.contains(p)) continue;
          final e = round.entries[p]!;
          if (e['winner'] == true) continue;
          final fold = e['foldAt'];
          scores[p] = fold is int ? fold : k + 1;
        }
      }
      for (final p in config.participants) {
        totals[p] = totals[p]! + scores[p]!;
      }
      result.add(scores);
    }
    return result;
  }

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) {
    if (rounds.isEmpty) return false;
    final s = situation(config, rounds);
    return config.boolSetting(playOnKey)
        ? s.alive(config).length <= 1
        : s.out.isNotEmpty;
  }
}
