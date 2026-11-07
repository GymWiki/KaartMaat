import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../games/data/game_repository.dart';
import '../games/data/game_state.dart';
import '../purchase/entitlements.dart';
import '../purchase/unlock_sheet.dart';

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
    final unlocked = ref.watch(entitlementsProvider).canViewStats;
    final games = ref.watch(finishedGamesProvider).value ?? const <GameState>[];
    final stats = unlocked ? _compute(games) : const <_Stat>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: !unlocked
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock, size: 48),
                  const SizedBox(height: 16),
                  Text(l10n.statsLocked, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => showUnlockSheet(context, ref),
                    child: Text(l10n.unlockTitle),
                  ),
                ]),
              ),
            )
          : stats.isEmpty
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
