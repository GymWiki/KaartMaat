import '../../games/data/game_state.dart';
import '../../groups/data/group_repository.dart';

/// Players for the "Spelers" block: the ones who played most recently first,
/// then everybody who never played (or whose games are unknown) alphabetically.
List<PlayerRef> sortByRecent(
  List<PlayerRef> players,
  Map<int, DateTime> lastPlayed,
) {
  int byName(PlayerRef a, PlayerRef b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  final played = [
    for (final p in players)
      if (lastPlayed.containsKey(p.id)) p,
  ]..sort((a, b) {
      final c = lastPlayed[b.id]!.compareTo(lastPlayed[a.id]!);
      return c != 0 ? c : byName(a, b);
    });
  final rest = [
    for (final p in players)
      if (!lastPlayed.containsKey(p.id)) p,
  ]..sort(byName);
  return [...played, ...rest];
}

/// The seats a group fills for a game that takes at most [max] players: its
/// members in their saved order, cut off at [max]. [group] already leaves out
/// players that were deleted, so a group with a deleted member shows the rest.
({List<int> ids, int dropped}) seatsForGroup(GroupRef group, int max) {
  final ids = group.memberIds.take(max).toList();
  return (ids: ids, dropped: group.memberIds.length - ids.length);
}

/// Case-insensitive "contains" filter for the search field.
List<PlayerRef> filterByName(List<PlayerRef> players, String query) {
  final q = query.trim().toLowerCase();
  return q.isEmpty
      ? players
      : [for (final p in players) if (p.name.toLowerCase().contains(q)) p];
}
