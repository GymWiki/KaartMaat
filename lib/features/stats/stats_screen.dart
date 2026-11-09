import 'package:flutter/material.dart';
import '../../core/ui/content_width.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../games/data/game_repository.dart';
import '../games/data/game_state.dart';
import '../pro/pro_gate.dart';
import '../pro/pro_previews.dart';
import 'filter_bar.dart';
import 'stats_calculator.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final all = ref.watch(finishedGamesProvider).value ?? const <GameState>[];
    final filter = ref.watch(statsFilterProvider);
    final games = applyFilter(all, filter);
    final stats = computeStats(games, withBestScore: filter.type != null);
    final year = filter.year ?? DateTime.now().year;
    final king = kaartkoning(all, year, groupId: filter.groupId);

    final content = all.isEmpty
          ? Center(child: Text(l10n.statsEmpty))
          : Column(children: [
              FilterBar(provider: statsFilterProvider, games: all),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (king != null)
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events, size: 32),
                          title: Text(l10n.kaartkoningTitle(year),
                              style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text(
                            '${king.name} · ${l10n.kaartkoningWins(king.wins, king.played)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (stats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(child: Text(l10n.historyNoMatch)),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            const DataColumn(label: Text('')),
                            DataColumn(label: Text(l10n.statsPlayed), numeric: true),
                            DataColumn(label: Text(l10n.statsWins), numeric: true),
                            DataColumn(label: Text(l10n.statsWinPct), numeric: true),
                            if (filter.type != null)
                              DataColumn(label: Text(l10n.statsBest), numeric: true),
                          ],
                          rows: [
                            for (final s in stats)
                              DataRow(cells: [
                                DataCell(Text(s.name)),
                                DataCell(Text('${s.played}')),
                                DataCell(Text('${s.wins}')),
                                DataCell(Text('${s.winPct}%')),
                                if (filter.type != null)
                                  DataCell(Text('${s.bestScore ?? '–'}')),
                              ]),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ]);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      // Pro: free users see a faded preview of their own data (or a sample)
      body: ContentWidth(
        child: ProGate(
          preview: all.isEmpty ? const SampleStatsPreview() : content,
          child: content,
        ),
      ),
    );
  }
}
