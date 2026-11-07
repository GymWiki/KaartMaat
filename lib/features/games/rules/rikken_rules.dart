import 'game_rules.dart';

enum RikType {
  /// Needs at least [RikContract.target] tricks; over/under tricks count.
  atLeast,

  /// Needs exactly [RikContract.target] tricks (piek 1, misère 0).
  exact,
}

class RikContract {
  const RikContract(
    this.id,
    this.type,
    this.target,
    this.base, {
    this.partner = false,
  });

  final String id;
  final RikType type;
  final int target;

  /// Default base points (editable in settings).
  final int base;

  /// Played with a partner (maat); otherwise alone against the other three.
  final bool partner;
}

/// Contracts in bidding order. Points follow the CardgamesHub table (the only
/// source with a complete points model); Wikibooks only has stakes in euro
/// cents and says amounts vary per region, so everything is editable.
const rikContracts = <RikContract>[
  RikContract('rik', RikType.atLeast, 8, 10, partner: true),
  RikContract('troela', RikType.atLeast, 8, 10, partner: true),
  RikContract('alone8', RikType.atLeast, 8, 10),
  RikContract('piek', RikType.exact, 1, 15),
  RikContract('alone9', RikType.atLeast, 9, 20),
  RikContract('misere', RikType.exact, 0, 25),
  RikContract('alone10', RikType.atLeast, 10, 30),
  RikContract('openPiek', RikType.exact, 1, 40),
  RikContract('alone11', RikType.atLeast, 11, 40),
  RikContract('openMisere', RikType.exact, 0, 50),
  RikContract('openPiekTalk', RikType.exact, 1, 55),
  RikContract('alone12', RikType.atLeast, 12, 50),
  RikContract('openMisereTalk', RikType.exact, 0, 60),
  RikContract('alone13', RikType.atLeast, 13, 70),
];

class RikOutcome {
  const RikOutcome({required this.success, required this.stake, required this.points});

  /// Whether the bidding side made the contract.
  final bool success;

  /// Points per opponent (base plus over/under tricks).
  final int stake;
  final Map<String, int> points;

  int get sum => points.values.fold(0, (a, b) => a + b);
}

/// Rikken for 4 players. Entry per player:
/// `{ 'role': 'bidder'|'partner'|'opp', 'contract': id, 'tricks': n }`,
/// where `tricks` is what the bidding side (bidder + partner) won.
///
/// Distribution is zero-sum: with a partner, the bidder and partner each win
/// the stake from an opponent (or the bidder pays both opponents when it
/// fails; the partner pays nothing unless [maatPaysKey]). Alone, the bidder
/// wins or pays the stake to each of the three opponents.
class RikkenRules extends GameRules {
  const RikkenRules();

  static const typeId = 'rikken';
  static const basePrefix = 'base.';
  static const perTrickKey = 'perTrick';
  static const slamBonusKey = 'slamBonus';
  static const maatPaysKey = 'maatPaysWhenLost';

  static String baseKey(String contractId) => '$basePrefix$contractId';

  static RikContract? contractOf(String id) {
    for (final c in rikContracts) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  String get type => typeId;

  @override
  int get minPlayers => 4;

  @override
  int get maxPlayers => 4;

  @override
  List<SettingSpec> get settingSpecs => [
        const SettingSpec(
            key: perTrickKey, kind: SettingKind.integer, defaultValue: 5, max: 100),
        const SettingSpec(
            key: slamBonusKey, kind: SettingKind.integer, defaultValue: 35, max: 500),
        const SettingSpec(
            key: maatPaysKey, kind: SettingKind.boolean, defaultValue: false),
        for (final c in rikContracts)
          SettingSpec(
            key: baseKey(c.id),
            kind: SettingKind.integer,
            defaultValue: c.base,
            max: 500,
          ),
      ];

  static String? _role(RoundData r, String p) => r.entries[p]?['role'] as String?;

  static String? bidderOf(GameConfig config, RoundData round) {
    for (final p in config.participants) {
      if (_role(round, p) == 'bidder') return p;
    }
    return null;
  }

  @override
  RoundIssue? validateRound(GameConfig config, RoundData round) {
    var bidders = 0, partners = 0;
    for (final p in config.participants) {
      final role = _role(round, p);
      if (role == null) return RoundIssue.missingEntry;
      if (role == 'bidder') bidders++;
      if (role == 'partner') partners++;
    }
    if (bidders != 1) return RoundIssue.missingEntry;
    final bidder = bidderOf(config, round)!;
    final contract = contractOf('${round.entries[bidder]!['contract']}');
    if (contract == null) return RoundIssue.missingEntry;
    final tricks = round.entries[bidder]!['tricks'];
    if (tricks is! int) return RoundIssue.missingEntry;
    if (tricks < 0 || tricks > 13) return RoundIssue.outOfRange;
    if (partners != (contract.partner ? 1 : 0)) return RoundIssue.missingEntry;
    return null;
  }

  /// Result of one deal. Returns zeros for an incomplete entry.
  RikOutcome outcome(GameConfig config, RoundData round) {
    final zero = {for (final p in config.participants) p: 0};
    if (validateRound(config, round) != null) {
      return RikOutcome(success: false, stake: 0, points: zero);
    }
    final bidder = bidderOf(config, round)!;
    final contract = contractOf('${round.entries[bidder]!['contract']}')!;
    final tricks = round.entries[bidder]!['tricks'] as int;

    final success = contract.type == RikType.atLeast
        ? tricks >= contract.target
        : tricks == contract.target;
    final diff = contract.type == RikType.atLeast ? (tricks - contract.target).abs() : 0;

    var stake = config.intSetting(baseKey(contract.id)) +
        config.intSetting(perTrickKey) * diff;
    // All 13 tricks with a partner ("kapot spelen") earns a bonus.
    if (contract.partner && success && tricks == 13) {
      stake += config.intSetting(slamBonusKey);
    }

    final partner = config.participants
        .where((p) => _role(round, p) == 'partner')
        .firstOrNull;
    final opponents =
        config.participants.where((p) => _role(round, p) == 'opp').toList();
    final points = {...zero};

    if (contract.partner) {
      final maatPays = config.boolSetting(maatPaysKey);
      if (success) {
        points[bidder] = stake;
        points[partner!] = stake;
        for (final o in opponents) {
          points[o] = -stake;
        }
      } else {
        points[bidder] = maatPays ? -stake : -2 * stake;
        points[partner!] = maatPays ? -stake : 0;
        for (final o in opponents) {
          points[o] = stake;
        }
      }
    } else {
      points[bidder] = (success ? 1 : -1) * stake * opponents.length;
      for (final o in opponents) {
        points[o] = (success ? -1 : 1) * stake;
      }
    }
    return RikOutcome(success: success, stake: stake, points: points);
  }

  @override
  Map<String, int> scoreRound(GameConfig config, RoundData round) =>
      outcome(config, round).points;
}
