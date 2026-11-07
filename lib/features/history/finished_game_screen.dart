import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/ui/dialogs.dart';
import '../games/data/game_repository.dart';
import '../games/data/game_state.dart';
import '../games/games_registry.dart';
import '../games/ui/standings_view.dart';
import 'share.dart';

class FinishedGameScreen extends ConsumerWidget {
  const FinishedGameScreen({super.key, required this.gameId});
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(gameStateProvider(gameId)).value;
    if (state == null) return Scaffold(appBar: AppBar());
    final view = GameView(state);

    return Scaffold(
      appBar: AppBar(
        title: Text(definitionFor(state.type).name(l10n)),
        actions: [
          IconButton(
            tooltip: l10n.shareResult,
            icon: const Icon(Icons.ios_share),
            onPressed: () => showShareResult(context, view),
          ),
          IconButton(
            tooltip: l10n.deleteGame,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirmDialog(context, l10n.deleteGameConfirm,
                  actionLabel: l10n.delete)) {
                await ref.read(gameRepositoryProvider).deleteGame(gameId);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.emoji_events, size: 32),
              title: Text(l10n.winnerLabel(view.winners.map(view.nameOf).join(', ')),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.gameFinished),
            ),
          ),
          Expanded(child: StandingsView(view: view)),
        ],
      ),
    );
  }
}
