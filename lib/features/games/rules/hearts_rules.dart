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
  static const roundsKey = 'rounds';
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
        // 0 = no fixed number of rounds: the target score decides.
        SettingSpec(
          key: roundsKey,
          kind: SettingKind.integer,
          defaultValue: 0,
          max: 99,
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

  // ---- Helpers for the input panel -------------------------------------

  /// Penalty points that come from hearts (the total minus the queen).
  int heartsTotal(GameConfig config) =>
      config.intSetting(totalPointsKey) - config.intSetting(queenPointsKey);

  /// The player whose points are filled in automatically: the last seat.
  String lastParticipant(GameConfig config) => config.participants.last;

  /// Points for [hearts] hearts, with or without the queen of spades.
  int pointsFor(GameConfig config, {required int hearts, required bool hasQueen}) =>
      hearts + (hasQueen ? config.intSetting(queenPointsKey) : 0);

  /// Hearts [player] can still take, given what the others (not counting
  /// the last seat, who gets the rest) already have.
  int heartsLeftFor(GameConfig config, String player, Map<String, int?> hearts) {
    final last = lastParticipant(config);
    var others = 0;
    for (final p in config.participants) {
      if (p == player || p == last) continue;
      others += hearts[p] ?? 0;
    }
    return heartsTotal(config) - others;
  }

  /// What the last seat gets: the hearts nobody else took, and the queen when
  /// no other player holds it. Null until everybody else has a value, or when
  /// the others already took more than there is.
  ({int hearts, bool hasQueen})? autoLast(
      GameConfig config, Map<String, int?> hearts, String? queenHolder) {
    final last = lastParticipant(config);
    var others = 0;
    for (final p in config.participants) {
      if (p == last) continue;
      final h = hearts[p];
      if (h == null) return null;
      others += h;
    }
    final left = heartsTotal(config) - others;
    if (left < 0) return null;
    final hasQueen = queenHolder == null || queenHolder == last;
    return (hearts: left, hasQueen: hasQueen);
  }

  /// The round entries for the panel's state, or null while incomplete.
  /// [queenHolder] null means the last seat holds the queen.
  Entries? buildEntries(
    GameConfig config, {
    required Map<String, int?> hearts,
    required String? queenHolder,
    required String? moon,
  }) {
    if (moon != null) {
      final points = moonPoints(config, moon);
      return {
        for (final p in config.participants)
          p: {'points': points[p], 'moon': p == moon, 'queen': false},
      };
    }
    final last = lastParticipant(config);
    final rest = autoLast(config, hearts, queenHolder);
    if (rest == null) return null;
    return {
      for (final p in config.participants)
        p: {
          'points': p == last
              ? pointsFor(config, hearts: rest.hearts, hasQueen: rest.hasQueen)
              : pointsFor(config, hearts: hearts[p]!, hasQueen: queenHolder == p),
          'moon': false,
          'queen': p == last ? rest.hasQueen : queenHolder == p,
        },
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
