import '../rules/game_rules.dart';
import '../rules/rules_registry.dart';

class PlayerRef {
  const PlayerRef({required this.id, required this.name});
  final int id;
  final String name;
  String get key => '$id';
}

/// Everything about one game, as stored. Totals are derived via [GameView].
class GameState {
  const GameState({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.finishedAt,
    required this.settings,
    required this.players,
    required this.rounds,
  });

  final int id;
  final String type;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final Map<String, Object?> settings;
  final List<PlayerRef> players;
  final List<RoundData> rounds;

  bool get isFinished => finishedAt != null;

  GameConfig get config {
    final keys = [for (final p in players) p.key];
    return GameConfig(
      type: type,
      participants: rulesFor(type).participantsFor(keys),
      players: keys,
      settings: settings,
    );
  }
}

/// Derived scores for a [GameState]. Cheap enough to rebuild per frame.
class GameView {
  GameView(this.state)
      : rules = rulesFor(state.type),
        config = state.config {
    standings = rules.standings(config, state.rounds);
    roundComplete = [
      for (final r in state.rounds) rules.isRoundComplete(config, r),
    ];
    roundScores = [for (final r in state.rounds) rules.scoreRound(config, r)];
    final running = {for (final p in config.participants) p: 0};
    cumulative = [
      for (final scores in roundScores)
        {
          for (final p in config.participants)
            p: running[p] = running[p]! + (scores[p] ?? 0),
        },
    ];
  }

  final GameState state;
  final GameRules rules;
  final GameConfig config;
  late final List<Standing> standings;
  late final List<Map<String, int>> roundScores;

  /// Running total per participant after each round.
  late final List<Map<String, int>> cumulative;

  /// Per round: false while it still waits for input (e.g. tricks).
  late final List<bool> roundComplete;

  /// The stored round that is not complete yet, if any.
  RoundData? get openRound {
    for (var i = 0; i < state.rounds.length; i++) {
      if (!roundComplete[i]) return state.rounds[i];
    }
    return null;
  }

  /// The round the primary button works on: the open one, else a new one.
  int get nextRoundNumber => openRound?.number ?? state.rounds.length + 1;

  /// False once a fixed-length game has all its rounds.
  bool get canAddRound {
    final planned = rules.plannedRounds(config);
    return planned == null || nextRoundNumber <= planned;
  }

  /// The game's own end condition is met (target score, all rounds played).
  bool get isOver => rules.isFinished(config, state.rounds);

  List<String> get winners => rules.winners(config, state.rounds);

  String _playerName(String key) => state.players
      .firstWhere((p) => p.key == key, orElse: () => PlayerRef(id: 0, name: '?'))
      .name;

  /// A player's name, or for a team the names of its members ("Anna & Bas").
  String nameOf(String participant) =>
      rules.membersOf(config, participant).map(_playerName).join(' & ');

  /// Winning participants expanded to player ids (for statistics).
  List<String> get winningPlayers => [
        for (final w in winners) ...rules.membersOf(config, w),
      ];

  int rankOf(String participant) =>
      standings.firstWhere((s) => s.participant == participant).rank;
}
