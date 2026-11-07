import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/ui/avatars.dart';
import '../games/data/game_state.dart';
import '../games/games_registry.dart';

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

/// The picture that is shared: final standings on a felt-green background.
/// Fixed colors and size so it looks the same on every phone and theme.
class ResultImageCard extends StatelessWidget {
  const ResultImageCard({super.key, required this.view});

  static const width = 360.0;
  final GameView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badges = badgesFor(view);
    final date = DateFormat('d MMMM yyyy', 'nl')
        .format(view.state.finishedAt ?? view.state.createdAt);
    final players = {for (final p in view.state.players) p.key: p};

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F6B45), Color(0xFF0F3D26)],
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(definitionFor(view.state.type).name(l10n),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(date, style: const TextStyle(color: Color(0xFFB9D8C6))),
            const SizedBox(height: 16),
            for (final s in view.standings)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 26,
                    child: Text('${s.rank}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  _Avatars(
                    members: view.rules
                        .membersOf(view.config, s.participant)
                        .map((k) => players[k]?.avatar ?? 0)
                        .toList(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(view.nameOf(s.participant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  if (badges.crown.contains(s.participant)) const CrownBadge(),
                  if (badges.donkey.contains(s.participant)) const DonkeyBadge(),
                  const SizedBox(width: 10),
                  Text('${s.total}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ]),
              ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                l10n.shareWatermark,
                style: const TextStyle(fontSize: 11, color: Color(0xAAFFFFFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars({required this.members});
  final List<int> members;

  @override
  Widget build(BuildContext context) {
    if (members.length <= 1) {
      return PlayerAvatar(index: members.isEmpty ? 0 : members.first, size: 40);
    }
    // Team: two avatars, slightly overlapping.
    return SizedBox(
      width: 60,
      height: 40,
      child: Stack(children: [
        Positioned(left: 0, child: PlayerAvatar(index: members[0], size: 40)),
        Positioned(left: 20, child: PlayerAvatar(index: members[1], size: 40)),
      ]),
    );
  }
}
