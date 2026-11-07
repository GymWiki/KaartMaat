import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../games/data/game_repository.dart';
import '../games/data/game_state.dart';
import '../games/games_registry.dart';
import '../stats/filter_bar.dart';
import '../stats/stats_calculator.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final all = ref.watch(finishedGamesProvider).value ?? const <GameState>[];
    final games = applyFilter(all, ref.watch(historyFilterProvider));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: all.isEmpty
          ? Center(child: Text(l10n.historyEmpty))
          : Column(children: [
              FilterBar(provider: historyFilterProvider, games: all),
              Expanded(
                child: games.isEmpty
                    ? Center(child: Text(l10n.historyNoMatch))
                    : ListView(children: [for (final g in games) _GameTile(state: g)]),
              ),
            ]),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = GameView(state);
    final date = DateFormat('d MMM yyyy', 'nl').format(state.finishedAt!);
    final winners = view.winners.map(view.nameOf).join(', ');
    return ListTile(
      leading: Icon(definitionFor(state.type).icon),
      title: Text(definitionFor(state.type).name(l10n)),
      subtitle: Text('$date · ${l10n.winnerLabel(winners)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/finished/${state.id}'),
    );
  }
}
