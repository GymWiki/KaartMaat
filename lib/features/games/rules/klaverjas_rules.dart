import 'game_rules.dart';

/// Klaverjassen: two teams, 8 tricks, 162 card points plus roem per deal.
///
/// Sources (checked online): Pagat, Wikipedia, rulespal and the NKF
/// Amsterdams wedstrijdreglement. They agree on card values, roem values,
/// "nat" and "pit". They describe Amsterdams vs Rotterdams only as a
/// difference in play (trumping), not in scoring, so [variantKey] is stored
/// with the game but both variants score the same.
///
/// Participants are the teams [wij] (seats 1 and 3) and [zij] (seats 2 and 4).
/// Entry per team: `{ 'playing': bool, 'pit': bool, 'cards': int,
/// 'three': n, 'four': n, 'stuk': n, 'equal': n, 'jacks': n }`.
/// A "drie op rij met stuk" is entered as a three plus a stuk (20 + 20 = 40).
class KlaverjasRules extends GameRules {
  const KlaverjasRules();

  static const typeId = 'klaverjassen';
  static const wij = 'wij';
  static const zij = 'zij';

  static const amsterdams = 'amsterdams';
  static const rotterdams = 'rotterdams';

  /// Gronings: every hand starts with bidding. The playing team has to make
  /// the bid (card points plus roem), else it is nat.
  static const gronings = 'gronings';

  static const minBidKey = 'minBid';
  static const maxBidKey = 'maxBid';

  /// Trump suits as stored in a Gronings hand.
  static const suits = ['hearts', 'diamonds', 'spades', 'clubs'];

  static const variantKey = 'variant';
  static const tieIsNatKey = 'tieIsNat';
  static const pitBonusKey = 'pitBonus';
  static const roemThreeKey = 'roemThree';
  static const roemFourKey = 'roemFour';
  static const roemStukKey = 'roemStuk';
  static const roemFourEqualKey = 'roemFourEqual';
  static const roemFourJacksKey = 'roemFourJacks';
  static const roundsKey = 'rounds';
  static const targetScoreKey = 'targetScore';

  /// How the game ends: after a number of hands, or at a target score.
  static const endModeKey = 'endMode';
  static const endModeHands = 'hands';
  static const endModeTarget = 'target';

  /// Card points in a deal (152 + 10 for the last trick).
  static const totalCardPoints = 162;

  /// Roem counters stored per team, in display order.
  static const roemFields = ['three', 'four', 'stuk', 'equal', 'jacks'];

  @override
  String get type => typeId;

  @override
  int get minPlayers => 4;

  @override
  int get maxPlayers => 4;

  @override
  List<SettingSpec> get settingSpecs => const [
        SettingSpec(
          key: variantKey,
          kind: SettingKind.choice,
          defaultValue: amsterdams,
          options: [amsterdams, rotterdams, gronings],
        ),
        // Gronings bidding: lowest opening bid (also what the player left of
        // the dealer must bid when everybody passes) and the highest bid.
        SettingSpec(
          key: minBidKey,
          kind: SettingKind.integer,
          defaultValue: 70,
          min: 10,
          max: 160,
          visibleIf: (variantKey, gronings),
        ),
        SettingSpec(
          key: maxBidKey,
          kind: SettingKind.integer,
          defaultValue: 260,
          min: 70,
          max: 500,
          visibleIf: (variantKey, gronings),
        ),
        SettingSpec(
          key: endModeKey,
          kind: SettingKind.choice,
          defaultValue: endModeHands,
          options: [endModeHands, endModeTarget],
        ),
        SettingSpec(
          key: roundsKey,
          kind: SettingKind.integer,
          defaultValue: 16,
          max: 99,
        ),
        SettingSpec(
          key: targetScoreKey,
          kind: SettingKind.integer,
          defaultValue: 1500,
          max: 100000,
        ),
        SettingSpec(
          key: tieIsNatKey,
          kind: SettingKind.boolean,
          defaultValue: true,
        ),
        SettingSpec(
          key: pitBonusKey,
          kind: SettingKind.integer,
          defaultValue: 100,
          max: 1000,
        ),
        SettingSpec(
          key: roemThreeKey,
          kind: SettingKind.integer,
          defaultValue: 20,
          max: 1000,
        ),
        SettingSpec(
          key: roemFourKey,
          kind: SettingKind.integer,
          defaultValue: 50,
          max: 1000,
        ),
        SettingSpec(
          key: roemStukKey,
          kind: SettingKind.integer,
          defaultValue: 20,
          max: 1000,
        ),
        SettingSpec(
          key: roemFourEqualKey,
          kind: SettingKind.integer,
          defaultValue: 100,
          max: 1000,
        ),
        // The NKF text lists 100 for four of a kind; Pagat, Wikipedia and
        // rulespal give 200 for four jacks. Club rules differ, so: a setting.
        SettingSpec(
          key: roemFourJacksKey,
          kind: SettingKind.integer,
          defaultValue: 200,
          max: 1000,
        ),
      ];

  // ---- Teams and dealer ------------------------------------------------

  @override
  List<String> participantsFor(List<String> playerKeys) => const [wij, zij];

  @override
  List<String> membersOf(GameConfig config, String participant) {
    if (participant != wij && participant != zij) return [participant];
    final start = participant == wij ? 0 : 1;
    return [
      for (var i = start; i < config.players.length; i += 2) config.players[i],
    ];
  }

  /// The dealer passes to the left after each deal; round 1 is dealt by seat 1.
  int dealerSeat(GameConfig config, int roundNumber) =>
      (roundNumber - 1) % config.players.length;

  String dealer(GameConfig config, int roundNumber) =>
      config.players[dealerSeat(config, roundNumber)];

  /// The team of the player left of the dealer. That player may choose trump
  /// first, so it is the most likely team to have played; the input panel
  /// preselects it (one tap to change).
  String forehandTeam(GameConfig config, int roundNumber) {
    final seat = (dealerSeat(config, roundNumber) + 1) % config.players.length;
    return seat.isEven ? wij : zij;
  }

  /// Whether [text] (card points typed so far) can still become a valid value.
  static bool isValidCardsText(String text) {
    if (text.isEmpty) return true;
    final v = int.tryParse(text);
    return v != null && v >= 0 && v <= totalCardPoints;
  }

  // ---- Gronings bidding --------------------------------------------------

  bool isGronings(GameConfig config) => config.settings[variantKey] == gronings;

  int minBid(GameConfig config) =>
      (config.settings[minBidKey] as num?)?.toInt() ?? 70;

  int maxBid(GameConfig config) =>
      (config.settings[maxBidKey] as num?)?.toInt() ?? 260;

  /// The player left of the dealer: bids first, and has to bid the minimum
  /// when everybody else passes.
  String bidStarter(GameConfig config, int roundNumber) =>
      config.players[(dealerSeat(config, roundNumber) + 1) % config.players.length];

  /// Bidding order: starts left of the dealer, the dealer bids last.
  List<String> bidOrder(GameConfig config, int roundNumber) {
    final n = config.players.length;
    final start = (dealerSeat(config, roundNumber) + 1) % n;
    return [for (var i = 0; i < n; i++) config.players[(start + i) % n]];
  }

  /// A first bid: a multiple of 10 between the lowest and highest bid.
  bool isValidOpening(GameConfig config, int bid) =>
      bid % 10 == 0 && bid >= minBid(config) && bid <= maxBid(config);

  /// A raise is +10, +20 or +30 on the current bid, within the highest bid.
  bool isValidRaise(GameConfig config, int current, int next) {
    final d = next - current;
    return (d == 10 || d == 20 || d == 30) && next <= maxBid(config);
  }

  /// Opening bids the panel offers as quick buttons.
  List<int> openingBids(GameConfig config) => [
    for (var b = minBid(config); b <= maxBid(config) && b <= 160; b += 10) b,
  ];

  /// The raises (+10/+20/+30) that are still allowed on [current].
  List<int> raisesFor(GameConfig config, int current) => [
    for (final d in const [10, 20, 30])
      if (current + d <= maxBid(config)) d,
  ];

  /// Who won the bidding. [bids] is the bidding in order (passes are left
  /// out); every bid must be a valid opening or raise, the last one is the
  /// highest. When nobody bid, the starter plays at the lowest bid.
  ({String bidder, int bid}) resolveBidding(
    GameConfig config,
    int roundNumber,
    List<({String player, int bid})> bids,
  ) {
    if (bids.isEmpty) {
      return (bidder: bidStarter(config, roundNumber), bid: minBid(config));
    }
    return (bidder: bids.last.player, bid: bids.last.bid);
  }

  /// Whether a whole bidding is legal: a valid opening, then only raises.
  bool isValidBidding(GameConfig config, List<({String player, int bid})> bids) {
    for (var i = 0; i < bids.length; i++) {
      final ok = i == 0
          ? isValidOpening(config, bids[i].bid)
          : isValidRaise(config, bids[i - 1].bid, bids[i].bid);
      if (!ok) return false;
    }
    return true;
  }

  // ---- Scoring ---------------------------------------------------------

  int _int(Entry? e, String key) => e?[key] is int ? e![key] as int : 0;

  /// Roem points of one team in one deal, from the counters and settings.
  int roemOf(GameConfig config, Entry? entry) =>
      _int(entry, 'three') * config.intSetting(roemThreeKey) +
      _int(entry, 'four') * config.intSetting(roemFourKey) +
      _int(entry, 'stuk') * config.intSetting(roemStukKey) +
      _int(entry, 'equal') * config.intSetting(roemFourEqualKey) +
      _int(entry, 'jacks') * config.intSetting(roemFourJacksKey);

  static String? playingTeam(RoundData round) {
    for (final t in const [wij, zij]) {
      if (round.entries[t]?['playing'] == true) return t;
    }
    return null;
  }

  static String other(String team) => team == wij ? zij : wij;

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    for (final t in const [wij, zij]) {
      final e = round.entries[t];
      if (e == null) return RoundIssue.missingEntry;
      final cards = e['cards'];
      if (cards is! int) return RoundIssue.missingEntry;
      if (cards < 0 || cards > totalCardPoints) return RoundIssue.outOfRange;
      for (final f in roemFields) {
        final n = e[f] ?? 0;
        if (n is! int || n < 0 || n > 8) return RoundIssue.outOfRange;
      }
    }
    final playing = round.entries[wij]!['playing'] == true;
    final opposing = round.entries[zij]!['playing'] == true;
    if (playing == opposing) return RoundIssue.missingEntry; // none or both
    if (_int(round.entries[wij], 'cards') + _int(round.entries[zij], 'cards') !=
        totalCardPoints) {
      return RoundIssue.invalidValue;
    }
    final team = playingTeam(round)!;
    if (isGronings(config)) {
      final e = round.entries[team]!;
      final bid = e['bid'];
      if (bid is! int) return RoundIssue.missingEntry;
      if (bid % 10 != 0) return RoundIssue.invalidValue;
      if (bid < minBid(config) || bid > maxBid(config)) {
        return RoundIssue.outOfRange;
      }
      if (!suits.contains(e['suit'])) return RoundIssue.missingEntry;
      if (!membersOf(config, team).contains(e['bidder'])) {
        return RoundIssue.invalidValue;
      }
    }
    if (round.entries[team]!['pit'] == true) {
      // A pit means all tricks: nothing for the other team, not even roem.
      final o = round.entries[other(team)]!;
      if (_int(round.entries[team], 'cards') != totalCardPoints ||
          roemFields.any((f) => _int(o, f) > 0)) {
        return RoundIssue.invalidValue;
      }
    }
    return null;
  }

  /// Points per team for one deal, with the flags the UI shows.
  KlaverjasOutcome outcome(GameConfig config, RoundData round) {
    final team = playingTeam(round);
    if (team == null || validateRound(config, round) != null) {
      return const KlaverjasOutcome(
        playing: null,
        nat: false,
        pit: false,
        points: {wij: 0, zij: 0},
      );
    }
    final opp = other(team);
    final cardsP = _int(round.entries[team], 'cards');
    final cardsO = _int(round.entries[opp], 'cards');
    final roemP = roemOf(config, round.entries[team]);
    final roemO = roemOf(config, round.entries[opp]);

    if (round.entries[team]!['pit'] == true) {
      return KlaverjasOutcome(
        playing: team,
        nat: false,
        pit: true,
        bid: isGronings(config) ? round.entries[team]!['bid'] as int? : null,
        points: {
          team: cardsP + roemP + config.intSetting(pitBonusKey),
          opp: 0,
        },
      );
    }

    final totalP = cardsP + roemP;
    final totalO = cardsO + roemO;
    // Gronings: the bid decides (made with exactly the bid is made). The
    // other variants need more than the opponents.
    final bid = isGronings(config) ? round.entries[team]!['bid'] as int : null;
    final nat = bid != null
        ? totalP < bid
        : (config.boolSetting(tieIsNatKey) ? totalP <= totalO : totalP < totalO);
    return KlaverjasOutcome(
      playing: team,
      nat: nat,
      pit: false,
      bid: bid,
      points: nat
          // The team that failed gets nothing; the other team gets all card
          // points and the roem of both teams.
          ? {team: 0, opp: cardsP + cardsO + roemP + roemO}
          : {team: totalP, opp: totalO},
    );
  }

  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) =>
      outcome(config, round).points;

  /// Games saved before [endModeKey] existed have no mode: they end on
  /// whichever of hands or target score comes first.
  String? _mode(GameConfig config) => config.settings[endModeKey] as String?;

  @override
  int? plannedRounds(GameConfig config) {
    if (_mode(config) == endModeTarget) return null;
    final n = config.intSetting(roundsKey);
    return n > 0 ? n : null;
  }

  @override
  bool isFinished(GameConfig config, List<RoundData> rounds) {
    final mode = _mode(config);
    final planned = plannedRounds(config);
    if (planned != null && rounds.length >= planned) return true;
    if (mode == endModeHands) return false;
    final target = config.intSetting(targetScoreKey);
    return target > 0 && totals(config, rounds).values.any((t) => t >= target);
  }
}

class KlaverjasOutcome {
  const KlaverjasOutcome({
    required this.playing,
    required this.nat,
    required this.pit,
    required this.points,
    this.bid,
  });

  /// The team that chose trump; null while the entry is incomplete.
  final String? playing;
  final bool nat;
  final bool pit;
  final Map<String, int> points;

  /// Gronings: the bid of the playing team; null in the other variants.
  final int? bid;
}
