import 'dart:math' as math;

import 'game_rules.dart';

/// Boerenbridge: every round each player bids how many tricks they will win,
/// then the tricks won are entered. Cards per round go 1..N..1.
///
/// Entry per participant: `{ 'bid': int, 'tricks': int? }`. A round with bids
/// but no tricks is "open": it is stored (so the game survives a restart) but
/// scores nothing until the tricks are entered.
class BoerenbridgeRules extends GameRules {
  const BoerenbridgeRules();

  static const typeId = 'boerenbridge';
  static const dealerRestrictionKey = 'dealerRestriction';
  static const exactBaseKey = 'exactBase';
  static const exactPerTrickKey = 'exactPerTrick';
  static const wrongPerTrickKey = 'wrongPerTrick';
  static const maxCardsKey = 'maxCards';
  static const deckSize = 52;

  @override
  String get type => typeId;

  @override
  int get minPlayers => 3;

  @override
  int get maxPlayers => 7;

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(
          key: dealerRestrictionKey,
          kind: SettingKind.boolean,
          defaultValue: true,
        ),
        SettingSpec(
          key: exactBaseKey,
          kind: SettingKind.integer,
          defaultValue: 10,
          max: 1000,
        ),
        SettingSpec(
          key: exactPerTrickKey,
          kind: SettingKind.integer,
          defaultValue: 5,
          max: 1000,
        ),
        SettingSpec(
          key: wrongPerTrickKey,
          kind: SettingKind.integer,
          defaultValue: 5,
          max: 1000,
        ),
        // 0 = automatic: floor(52 / players).
        SettingSpec(
          key: maxCardsKey,
          kind: SettingKind.integer,
          defaultValue: 0,
          max: 17,
        ),
      ];

  // ---- Round sequence --------------------------------------------------

  /// Highest number of cards dealt in one round.
  int maxCards(GameConfig config) {
    final auto = deckSize ~/ config.participants.length;
    final override = config.intSetting(maxCardsKey);
    return override > 0 ? math.min(override, auto) : auto;
  }

  /// 1..N..1, so the peak is played once.
  int totalRounds(GameConfig config) => 2 * maxCards(config) - 1;

  /// Cards dealt in [roundNumber] (1-based).
  int cardsInRound(GameConfig config, int roundNumber) {
    final n = maxCards(config);
    return n - (n - roundNumber).abs();
  }

  /// Seat index of the dealer. Round 1 is dealt by seat 0, then it rotates.
  int dealerIndex(GameConfig config, int roundNumber) =>
      (roundNumber - 1) % config.participants.length;

  String dealer(GameConfig config, int roundNumber) =>
      config.participants[dealerIndex(config, roundNumber)];

  /// Bidding order: starts left of the dealer, the dealer bids last.
  List<String> bidOrder(GameConfig config, int roundNumber) {
    final d = dealerIndex(config, roundNumber);
    final n = config.participants.length;
    return [for (var i = 1; i <= n; i++) config.participants[(d + i) % n]];
  }

  /// The bid the dealer may not make, given the other players' bids. Null when
  /// the restriction is off or no bid would reach the number of tricks.
  int? forbiddenDealerBid(GameConfig config, int roundNumber, int othersBidSum) {
    if (!config.boolSetting(dealerRestrictionKey)) return null;
    final forbidden = cardsInRound(config, roundNumber) - othersBidSum;
    return forbidden >= 0 ? forbidden : null;
  }

  // ---- Validation and scoring ------------------------------------------

  static int? _int(Entry? e, String key) => e?[key] is int ? e![key] as int : null;

  @override
  bool isRoundComplete(GameConfig config, RoundData round) => config.participants
      .every((p) => round.entries[p]?['tricks'] != null);

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    if (round.number < 1 || round.number > totalRounds(config)) {
      return RoundIssue.outOfRange;
    }
    final cards = cardsInRound(config, round.number);
    final ids = config.participants;

    var bidSum = 0;
    for (final p in ids) {
      final bid = _int(round.entries[p], 'bid');
      if (bid == null) return RoundIssue.missingEntry;
      if (bid < 0 || bid > cards) return RoundIssue.outOfRange;
      bidSum += bid;
    }
    if (config.boolSetting(dealerRestrictionKey) && bidSum == cards) {
      return RoundIssue.dealerBid;
    }

    final withTricks = ids.where((p) => round.entries[p]?['tricks'] != null);
    if (withTricks.isEmpty) return null; // bidding step only
    if (withTricks.length != ids.length) return RoundIssue.missingEntry;

    var trickSum = 0;
    for (final p in ids) {
      final tricks = _int(round.entries[p], 'tricks');
      if (tricks == null) return RoundIssue.missingEntry;
      if (tricks < 0 || tricks > cards) return RoundIssue.outOfRange;
      trickSum += tricks;
    }
    return trickSum == cards ? null : RoundIssue.tricksMismatch;
  }

  /// Exact bid: base + perTrick * tricks. Wrong: -perTrick * difference.
  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) {
    if (!isRoundComplete(config, round)) {
      return {for (final p in config.participants) p: 0};
    }
    final base = config.intSetting(exactBaseKey);
    final perTrick = config.intSetting(exactPerTrickKey);
    final penalty = config.intSetting(wrongPerTrickKey);
    return {
      for (final p in config.participants)
        p: () {
          final bid = _int(round.entries[p], 'bid') ?? 0;
          final tricks = _int(round.entries[p], 'tricks') ?? 0;
          return bid == tricks
              ? base + perTrick * tricks
              : -penalty * (bid - tricks).abs();
        }(),
    };
  }

  @override
  int? plannedRounds(GameConfig config) => totalRounds(config);

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) =>
      rounds.length >= totalRounds(config) &&
      rounds.every((r) => isRoundComplete(config, r));
}
