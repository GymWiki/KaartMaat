import '../games/data/game_state.dart';

/// Which finished games to look at. Null means "all".
class GameFilter {
  const GameFilter({this.type, this.groupId, this.year});

  final String? type;
  final int? groupId;
  final int? year;

  GameFilter copyWith({
    Object? type = _keep,
    Object? groupId = _keep,
    Object? year = _keep,
  }) =>
      GameFilter(
        type: identical(type, _keep) ? this.type : type as String?,
        groupId: identical(groupId, _keep) ? this.groupId : groupId as int?,
        year: identical(year, _keep) ? this.year : year as int?,
      );

  static const _keep = Object();

  bool matches(GameState g) =>
      g.isFinished &&
      (type == null || g.type == type) &&
      (groupId == null || g.groupId == groupId) &&
      (year == null || g.finishedAt!.year == year);
}

List<GameState> applyFilter(List<GameState> games, GameFilter filter) =>
    [for (final g in games) if (filter.matches(g)) g];

/// Years in which games were finished, newest first.
List<int> yearsOf(List<GameState> games) => ({
      for (final g in games)
        if (g.finishedAt != null) g.finishedAt!.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a)));

class PlayerStat {
  PlayerStat(this.id, this.name);

  final int id;
  final String name;
  int played = 0;
  int wins = 0;

  /// Best final total in a single game (highest, or lowest when lower is
  /// better). Only filled in when one game type is selected.
  int? bestScore;

  int get winPct => played == 0 ? 0 : (wins * 100 / played).round();
}

/// Leaderboard rows, best first: most wins, then win percentage, then games.
List<PlayerStat> computeStats(List<GameState> games, {bool withBestScore = false}) {
  final stats = <int, PlayerStat>{};
  for (final g in games) {
    final view = GameView(g);
    final winners = view.winningPlayers;
    final higher = view.rules.higherIsBetter(view.config);
    for (final p in g.players) {
      final s = stats.putIfAbsent(p.id, () => PlayerStat(p.id, p.name));
      s.played++;
      if (winners.contains(p.key)) s.wins++;
      if (withBestScore) {
        final total = view.totalOfPlayer(p.key);
        if (total != null) {
          final best = s.bestScore;
          if (best == null || (higher ? total > best : total < best)) {
            s.bestScore = total;
          }
        }
      }
    }
  }
  return stats.values.toList()
    ..sort((a, b) {
      if (b.wins != a.wins) return b.wins.compareTo(a.wins);
      if (b.winPct != a.winPct) return b.winPct.compareTo(a.winPct);
      return b.played.compareTo(a.played);
    });
}

/// "Kaartkoning van het jaar": the most wins in [year], tie-break on win
/// percentage, then on games played. Needs at least one win.
PlayerStat? kaartkoning(List<GameState> games, int year, {int? groupId}) {
  final inYear = applyFilter(games, GameFilter(year: year, groupId: groupId));
  final stats = computeStats(inYear);
  if (stats.isEmpty || stats.first.wins == 0) return null;
  return stats.first;
}
