import '../games/data/game_state.dart';

/// Who gets a crown (first place) and who gets the donkey (last place).
/// The donkey is only given when there is a clear last place that is not
/// also first (so not when everybody tied).
({Set<String> crown, Set<String> donkey}) badgesFor(GameView view) {
  if (view.state.rounds.isEmpty || view.standings.isEmpty) {
    return (crown: <String>{}, donkey: <String>{});
  }
  final crown = {
    for (final s in view.standings)
      if (s.rank == 1) s.participant,
  };
  final lastRank = view.standings.last.rank;
  final donkey = lastRank > 1
      ? {
          for (final s in view.standings)
            if (s.rank == lastRank) s.participant,
        }
      : <String>{};
  return (crown: crown, donkey: donkey);
}
