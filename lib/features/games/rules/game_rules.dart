// Pure Dart: no Flutter or UI imports allowed in this folder.

/// Values for one participant (player or team) in one round.
typedef Entry = Map<String, Object?>;

/// Participant id -> entry. Participant ids are player ids as strings.
typedef Entries = Map<String, Entry>;

class GameConfig {
  const GameConfig({
    required this.type,
    required this.participants,
    required this.settings,
  });

  final String type;

  /// Participant ids in seat order.
  final List<String> participants;
  final Map<String, Object?> settings;

  int intSetting(String key) => (settings[key] as num?)?.toInt() ?? 0;
  bool boolSetting(String key) => settings[key] == true;
}

class RoundData {
  const RoundData({required this.number, required this.entries});

  /// 1-based.
  final int number;
  final Entries entries;
}

class Standing {
  const Standing({
    required this.participant,
    required this.total,
    required this.rank,
  });

  final String participant;
  final int total;

  /// 1-based; ties share a rank (1, 1, 3).
  final int rank;
}

/// Why a round cannot be saved. The UI maps these to Dutch text.
enum RoundIssue {
  missingEntry,
  invalidValue,
  outOfRange,
  dealerBid,
  tricksMismatch,
}

enum SettingKind { boolean, integer }

/// Describes one rule option so the UI can render an editor for it.
class SettingSpec {
  const SettingSpec({
    required this.key,
    required this.kind,
    required this.defaultValue,
    this.min = 0,
    this.max = 9999,
  });

  final String key;
  final SettingKind kind;
  final Object defaultValue;
  final int min;
  final int max;
}

abstract class GameRules {
  const GameRules();

  String get type;
  int get minPlayers;
  int get maxPlayers;

  List<SettingSpec> get settingSpecs => const [];

  Map<String, Object?> get defaultSettings => {
        for (final s in settingSpecs) s.key: s.defaultValue,
      };

  /// null when the round may be saved.
  RoundIssue? validateRound(GameConfig config, RoundData round);

  /// Points each participant gets for this single round.
  Map<String, int> scoreRound(GameConfig config, RoundData round);

  bool higherIsBetter(GameConfig config) => true;

  /// False for a stored round that still waits for input (e.g. tricks).
  bool isRoundComplete(GameConfig config, RoundData round) => true;

  /// Fixed number of rounds, or null when the game is open-ended.
  int? plannedRounds(GameConfig config) => null;

  /// True when the game's own end condition is met (e.g. target score).
  bool isFinished(GameConfig config, List<RoundData> rounds) => false;

  /// Totals, always derived from the rounds.
  Map<String, int> totals(GameConfig config, List<RoundData> rounds) {
    final result = {for (final p in config.participants) p: 0};
    for (final round in rounds) {
      final scores = scoreRound(config, round);
      for (final p in config.participants) {
        result[p] = result[p]! + (scores[p] ?? 0);
      }
    }
    return result;
  }

  /// Sorted best first.
  List<Standing> standings(GameConfig config, List<RoundData> rounds) {
    final t = totals(config, rounds);
    final better = higherIsBetter(config);
    final ids = [...config.participants]..sort((a, b) {
        final c = better ? t[b]!.compareTo(t[a]!) : t[a]!.compareTo(t[b]!);
        return c != 0 ? c : config.participants.indexOf(a) - config.participants.indexOf(b);
      });
    final result = <Standing>[];
    for (var i = 0; i < ids.length; i++) {
      final tied = i > 0 && t[ids[i]] == t[ids[i - 1]];
      result.add(Standing(
        participant: ids[i],
        total: t[ids[i]]!,
        rank: tied ? result[i - 1].rank : i + 1,
      ));
    }
    return result;
  }

  /// Participants sharing first place. Empty when no round was played.
  List<String> winners(GameConfig config, List<RoundData> rounds) {
    if (rounds.isEmpty) return const [];
    return [
      for (final s in standings(config, rounds))
        if (s.rank == 1) s.participant,
    ];
  }
}
