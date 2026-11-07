import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/suits.dart';
import '../../../core/ui/touch.dart';
import '../../../core/ui/undo_snackbar.dart';
import '../../history/share.dart';
import '../../settings/data/settings_repository.dart';
import '../data/draft_store.dart';
import '../data/game_repository.dart';
import '../data/game_state.dart';
import '../games_registry.dart';
import '../rules/game_rules.dart';
import 'game_screen_scaffold.dart';
import 'panel_context.dart';
import 'progress_chart.dart';
import 'round_table.dart';
import 'standings_view.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.gameId});
  final int gameId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  late final DraftSaver _saver =
      DraftSaver(ref.read(draftStoreProvider), widget.gameId);
  final _panelInset = ValueNotifier<double>(0);

  Map<String, Object?>? _draft;
  bool _draftLoaded = false;

  /// An earlier round that is loaded in the panel for correction.
  int? _editingRound;

  /// Bumped to rebuild the panel from [_draft] (after an undo).
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _keepAwake(true);
    ref.read(draftStoreProvider).load(widget.gameId).then((d) {
      if (!mounted) return;
      setState(() {
        _draft = d;
        _draftLoaded = true;
        if (d != null && d['editing'] == true && d['round'] is int) {
          _editingRound = d['round'] as int;
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_saver.flush());
    _saver.dispose();
    _panelInset.dispose();
    _keepAwake(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Never lose a half-filled panel: write it out when the app leaves the screen.
    if (state != AppLifecycleState.resumed) unawaited(_saver.flush());
  }

  void _keepAwake(bool on) {
    try {
      unawaited((on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((_) {}));
    } catch (_) {
      // no wakelock support (tests, desktop): the game still works
    }
  }

  GameRepository get _repo => ref.read(gameRepositoryProvider);

  // ---- classic (separate input screen) ---------------------------------

  Future<void> _undoWithDialog(GameState state) async {
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
    await _saver.discard();
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

  // ---- one-screen games (input panel) ----------------------------------

  void _startEditing(int number) {
    haptic(ref);
    unawaited(_saver.discard());
    setState(() {
      _editingRound = number;
      _draft = null;
      _generation++;
    });
  }

  void _stopEditing() {
    haptic(ref);
    unawaited(_saver.discard());
    setState(() {
      _editingRound = null;
      _draft = null;
      _generation++;
    });
  }

  /// Shows the undo snackbar once the (possibly new) panel has been laid out
  /// and measured, so it floats above the panel instead of covering it.
  void _showUndo(String message, Future<void> Function() onUndo) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The scaffold measures the panel in this same phase: wait one more frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        UndoSnackbar.show(
          context,
          message: message,
          bottomInset: _panelInset.value,
          onFeedback: () => haptic(ref),
          onUndo: onUndo,
        );
      });
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  /// Removes the last round without a dialog; the snackbar can bring it back.
  Future<void> _undoLastRound(GameState state) async {
    if (state.rounds.isEmpty) return;
    final last = state.rounds.last;
    final l10n = context.l10n;
    haptic(ref);
    await _repo.deleteLastRound(state.id);
    if (!mounted) return;
    _showUndo(l10n.roundDeleted(last.number), () => _repo.addRound(state.id, last.entries));
  }

  Future<void> _savePanelRound(
    int number,
    Entries entries, {
    required bool complete,
    Map<String, Object?>? undoDraft,
  }) async {
    final l10n = context.l10n;
    final current = ref.read(gameStateProvider(widget.gameId)).value;
    final previous =
        current?.rounds.where((r) => r.number == number).firstOrNull?.entries;
    if (previous != null) {
      await _repo.updateRound(widget.gameId, number, entries);
    } else {
      await _repo.addRound(widget.gameId, entries);
    }
    if (!complete || !mounted) return;

    await _saver.discard();
    setState(() {
      _editingRound = null;
      _draft = null;
      _generation++;
    });
    if (!mounted) return;
    _showUndo(l10n.roundSaved(number), () async {
      if (previous == null) {
        await _repo.deleteLastRound(widget.gameId);
      } else {
        await _repo.updateRound(widget.gameId, number, previous);
      }
      if (!mounted) return;
      // Bring the panel back as it was before saving.
      if (undoDraft != null) _saver.schedule(undoDraft);
      setState(() {
        _draft = undoDraft;
        _generation++;
      });
    });
  }

  void _showProgress(GameView view) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(context.l10n.progressTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ProgressChart(view: view),
          ]),
        ),
      ),
    );
  }

  Widget _panelScreen(GameState state, GameView view, GameDefinition def) {
    final l10n = context.l10n;
    final editing = _editingRound != null;
    final number = _editingRound ?? view.nextRoundNumber;
    final existing =
        state.rounds.where((r) => r.number == number).firstOrNull?.entries;

    Widget? panel;
    if (!_draftLoaded) {
      panel = null;
    } else if (!editing && !view.canAddRound) {
      panel = SizedBox(
        height: kTouchTarget,
        child: FilledButton(
          onPressed: () => _finish(state),
          child: Text(l10n.finishGame),
        ),
      );
    } else {
      panel = KeyedSubtree(
        key: ValueKey('panel-$number-$editing-$_generation'),
        child: def.panelBuilder!(PanelContext(
          view: view,
          roundNumber: number,
          existing: existing,
          editing: editing,
          draft: _saver,
          initialDraft: _draft,
          onSave: (entries, {required complete, undoDraft}) =>
              _savePanelRound(number, entries, complete: complete, undoDraft: undoDraft),
          onCancel: _stopEditing,
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(def.name(l10n)),
        actions: [
          IconButton(
            tooltip: l10n.showProgress,
            icon: const Icon(Icons.show_chart),
            onPressed: () => _showProgress(view),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'undo' => _undoLastRound(state),
              'share' => showShareResult(context, view),
              'finish' => _finish(state),
              _ => _delete(state),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'undo',
                enabled: state.rounds.isNotEmpty,
                child: Text(l10n.undoLast),
              ),
              PopupMenuItem(value: 'share', child: Text(l10n.shareResult)),
              PopupMenuItem(value: 'finish', child: Text(l10n.finishGame)),
              PopupMenuItem(value: 'delete', child: Text(l10n.deleteGame)),
            ],
          ),
        ],
      ),
      body: GameScreenScaffold(
        panelInset: _panelInset,
        top: RoundTable(
          view: view,
          currentRound: view.canAddRound ? view.nextRoundNumber : null,
          editingRound: _editingRound,
          onTapRound: (n) => n == view.nextRoundNumber && view.canAddRound
              ? _stopEditing()
              : _startEditing(n),
          cellDetail: def.cellDetail == null
              ? null
              : (i, p) => def.cellDetail!(l10n, view, i, p),
          cellHighlight: def.cellHighlight == null
              ? null
              : (i, p) => def.cellHighlight!(view, i, p),
        ),
        panel: panel,
      ),
    );
  }

  // ---- build -----------------------------------------------------------

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
    if (def.panelBuilder != null) return _panelScreen(state, view, def);

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
              onUndo: state.rounds.isEmpty ? null : () => _undoWithDialog(state),
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
