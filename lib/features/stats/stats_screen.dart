import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../games/data/game_repository.dart';
import '../games/data/game_state.dart';

class _Stat {
  _Stat(this.name);
  final String name;
  int played = 0;
  int wins = 0;
  int get winPct => played == 0 ? 0 : (wins * 100 / played).round();
}

List<_Stat> _compute(List<GameState> games) {
  final stats = <int, _Stat>{};
  for (final g in games) {
    final winners = GameView(g).winners;
    for (final p in g.players) {
      final s = stats.putIfAbsent(p.id, () => _Stat(p.name));
      s.played++;
      if (winners.contains(p.key)) s.wins++;
    }
  }
  return stats.values.toList()
    ..sort((a, b) =>
        b.wins != a.wins ? b.wins.compareTo(a.wins) : b.played.compareTo(a.played));
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final games = ref.watch(finishedGamesProvider).value ?? const <GameState>[];
    final stats = _compute(games);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: stats.isEmpty
          ? Center(child: Text(l10n.statsEmpty))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DataTable(
                  columns: [
                    const DataColumn(label: Text('')),
                    DataColumn(label: Text(l10n.statsPlayed), numeric: true),
                    DataColumn(label: Text(l10n.statsWins), numeric: true),
                    DataColumn(label: Text(l10n.statsWinPct), numeric: true),
                  ],
                  rows: [
                    for (final s in stats)
                      DataRow(cells: [
                        DataCell(Text(s.name)),
                        DataCell(Text('${s.played}')),
                        DataCell(Text('${s.wins}')),
                        DataCell(Text('${s.winPct}%')),
                      ]),
                  ],
                ),
              ],
            ),
    );
  }
}
