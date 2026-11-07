import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/suits.dart';
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
              for (var i = 0; i < view.config.participants.length; i++)
                _ScoreCard(
                  name: view.nameOf(view.config.participants[i]),
                  rank: totals[view.config.participants[i]]!.rank,
                  total: totals[view.config.participants[i]]!.total,
                  delta: last?[view.config.participants[i]],
                  suit: suitAt(i),
                  leading: view.state.rounds.isNotEmpty &&
                      totals[view.config.participants[i]]!.rank == 1,
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

/// One participant as a playing card: rank and suit in the corner, the total
/// as the biggest thing on it. The leader gets a brass outline.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.name,
    required this.rank,
    required this.total,
    required this.delta,
    required this.suit,
    required this.leading,
  });

  final String name;
  final int rank;
  final int total;

  /// Points from the last round; null before the first round.
  final int? delta;
  final Suit suit;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: leading ? scheme.primary : scheme.outlineVariant,
          width: leading ? 2.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
        child: Row(children: [
          CornerIndex(rank: rank, suit: suit, highlight: leading),
          const SizedBox(width: 14),
          Expanded(
            child: Text(name,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          if (delta != null)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                delta! > 0 ? '+$delta' : '$delta',
                style: text.headlineSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          Text('$total', style: text.displaySmall),
        ]),
      ),
    );
  }
}
