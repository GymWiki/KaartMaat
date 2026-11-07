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

  GameConfig get config => GameConfig(
        type: type,
        participants: [for (final p in players) p.key],
        settings: settings,
      );
}

/// Derived scores for a [GameState]. Cheap enough to rebuild per frame.
class GameView {
  GameView(this.state)
      : rules = rulesFor(state.type),
        config = state.config {
    standings = rules.standings(config, state.rounds);
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

  bool get targetReached => rules.isFinished(config, state.rounds);

  List<String> get winners => rules.winners(config, state.rounds);

  String nameOf(String participant) => state.players
      .firstWhere((p) => p.key == participant,
          orElse: () => PlayerRef(id: 0, name: '?'))
      .name;

  int rankOf(String participant) =>
      standings.firstWhere((s) => s.participant == participant).rank;
}
