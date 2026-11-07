import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../history/share.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_repository.dart';
import '../data/game_state.dart';
import '../games_registry.dart';
import 'standings_view.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.gameId});
  final int gameId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  GameRepository get _repo => ref.read(gameRepositoryProvider);

  Future<void> _undo(GameState state) async {
    final l10n = context.l10n;
    final last = state.rounds.last.number;
    if (await confirmDialog(context, l10n.undoConfirm(last),
        actionLabel: l10n.delete)) {
      haptic(ref);
      await _repo.deleteLastRound(state.id);
    }
  }

  Future<void> _finish(GameState state) async {
    final l10n = context.l10n;
    if (!await confirmDialog(context, l10n.finishConfirm,
        actionLabel: l10n.finishGame)) {
      return;
    }
    await _repo.finish(state.id);
    if (mounted) context.pushReplacement('/finished/${state.id}');
  }

  Future<void> _delete(GameState state) async {
    final l10n = context.l10n;
    if (!await confirmDialog(context, l10n.deleteGameConfirm,
        actionLabel: l10n.delete)) {
      return;
    }
    await _repo.deleteGame(state.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(gameStateProvider(widget.gameId));
    final state = async.value;
    if (state == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: async.isLoading ? const CircularProgressIndicator() : null),
      );
    }

    final view = GameView(state);
    final def = definitionFor(state.type);
    final next = view.nextRoundNumber;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(def.name(l10n)),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'copy' => showShareResult(context, view),
                'finish' => _finish(state),
                _ => _delete(state),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'copy', child: Text(l10n.shareResult)),
                PopupMenuItem(value: 'finish', child: Text(l10n.finishGame)),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteGame)),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [Tab(text: l10n.tabGame), Tab(text: l10n.tabStanding)],
          ),
        ),
        body: TabBarView(
          children: [
            _ScoreTab(
              view: view,
              header: def.headerBuilder?.call(view),
              primaryLabel:
                  def.primaryLabel?.call(l10n, view) ?? l10n.enterRound(next),
              onFinish: () => _finish(state),
              onUndo: state.rounds.isEmpty ? null : () => _undo(state),
              onNewRound: () => context.push('/game/${state.id}/round/$next'),
            ),
            StandingsView(
              view: view,
              onTapRound: (n) => context.push('/game/${state.id}/round/$n'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTab extends StatelessWidget {
  const _ScoreTab({
    required this.view,
    required this.header,
    required this.primaryLabel,
    required this.onFinish,
    required this.onUndo,
    required this.onNewRound,
  });

  final GameView view;
  final Widget? header;
  final String primaryLabel;
  final VoidCallback onFinish;
  final VoidCallback? onUndo;
  final VoidCallback onNewRound;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final last = view.roundScores.isEmpty ? null : view.roundScores.last;
    final totals = {for (final s in view.standings) s.participant: s};

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ?header,
              if (view.isOver && header == null)
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.flag),
                    title: Text(l10n.gameOver),
                    trailing: TextButton(
                        onPressed: onFinish, child: Text(l10n.finishGame)),
                  ),
                ),
              for (final p in view.config.participants)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      CircleAvatar(child: Text('${totals[p]!.rank}')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(view.nameOf(p),
                            style: text.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (last != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            last[p]! > 0 ? '+${last[p]}' : '${last[p]}',
                            style: text.titleMedium,
                          ),
                        ),
                      Text('${totals[p]!.total}',
                          style: text.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              SizedBox(
                width: 64,
                height: 60,
                child: OutlinedButton(
                  onPressed: onUndo,
                  child: Tooltip(
                    message: l10n.undoLast,
                    child: const Icon(Icons.undo),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: view.canAddRound
                    ? FilledButton(
                        onPressed: onNewRound,
                        child: Text(primaryLabel),
                      )
                    : FilledButton(
                        onPressed: onFinish,
                        child: Text(l10n.finishGame),
                      ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
