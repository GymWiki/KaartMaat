import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../core/ui/dialogs.dart';
import '../games/data/game_repository.dart';
import '../games/data/game_state.dart';
import '../settings/data/settings_repository.dart';
import 'result_export.dart';
import 'share_result_card.dart';

/// Setting that remembers which result screen is open, so a killed app comes
/// back to it.
const lastResultKey = 'ui.lastResult';

/// The result of a finished game: the share card fills the screen (what you
/// see is the picture that gets shared), with the actions below it.
class FinishedGameScreen extends ConsumerStatefulWidget {
  const FinishedGameScreen({
    super.key,
    required this.gameId,
    this.celebrate = false,
  });

  final int gameId;

  /// True right after the game ended: the crown settles on the winner.
  /// Visits from History do not celebrate again.
  final bool celebrate;

  @override
  ConsumerState<FinishedGameScreen> createState() => _FinishedGameScreenState();
}

enum _Busy { none, sharing, saving }

class _FinishedGameScreenState extends ConsumerState<FinishedGameScreen>
    with SingleTickerProviderStateMixin {
  final _cardKey = GlobalKey();
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final SettingsRepository _settings = ref.read(
    settingsRepositoryProvider,
  );
  bool _celebrated = false;
  _Busy _busy = _Busy.none;

  @override
  void initState() {
    super.initState();
    _settings.set(lastResultKey, '${widget.gameId}');
    _anim.addStatusListener((s) {
      if (s == AnimationStatus.completed &&
          widget.celebrate &&
          ref.read(prefsProvider).haptics) {
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _settings.remove(lastResultKey);
    _anim.dispose();
    super.dispose();
  }

  void _maybeCelebrate() {
    if (_celebrated) return;
    _celebrated = true;
    if (!widget.celebrate) {
      _anim.value = 1;
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.value = 1; // reduce motion: no animation
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _anim.forward();
    });
  }

  Future<Uint8List> _png() async {
    if (_anim.value < 1 && widget.celebrate) await _anim.forward();
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return renderCardPng(boundary);
  }

  Future<void> _share(GameView view) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = _Busy.sharing);
    try {
      final bytes = await _png();
      await shareCardPng(bytes, shareCaption(l10n, view));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = _Busy.saving);
    try {
      final result = await saveCardPng(await _png());
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            SaveResult.saved => l10n.imageSaved,
            SaveResult.denied => l10n.imageSaveDenied,
            SaveResult.failed => l10n.imageSaveFailed,
          }),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _resume(GameState state) async {
    final l10n = context.l10n;
    if (!await confirmDialog(
      context,
      l10n.resumeFinishedConfirm,
      actionLabel: l10n.resumeFinished,
    )) {
      return;
    }
    await ref.read(gameRepositoryProvider).reopen(state.id);
    if (mounted) context.pushReplacement('/game/${state.id}');
  }

  void _newGame(GameState state) {
    context.go('/');
    context.push('/new/${state.type}');
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    if (await confirmDialog(
      context,
      l10n.deleteGameConfirm,
      actionLabel: l10n.delete,
    )) {
      await ref.read(gameRepositoryProvider).deleteGame(widget.gameId);
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(gameStateProvider(widget.gameId)).value;
    if (state == null) return Scaffold(appBar: AppBar());
    _maybeCelebrate();
    final view = GameView(state);
    final busy = _busy != _Busy.none;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.closeResult,
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        title: Text(resultTitle(l10n, state)),
        actions: [
          IconButton(
            tooltip: l10n.deleteGame,
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Center(
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: ShareResultCard(
                      view: view,
                      crownProgress: widget.celebrate ? _anim : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: busy ? null : () => _share(view),
                      icon: _busy == _Busy.sharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share),
                      label: Text(l10n.shareAction),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _save,
                      icon: _busy == _Busy.saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(l10n.saveImage),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _newGame(state),
                          child: Text(l10n.newGameAgain),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => _resume(state),
                          child: Text(l10n.resumeFinished),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
