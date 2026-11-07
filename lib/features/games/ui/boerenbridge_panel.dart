import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/live_score_preview.dart';
import '../../../core/ui/player_selector.dart';
import '../../../core/ui/quick_button_row.dart';
import '../../../core/ui/touch.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/boerenbridge_rules.dart';
import '../rules/game_rules.dart';
import 'panel_context.dart';

/// Boerenbridge input on the game screen: pick a player, tap a number.
///
/// Bidding: one tap per player, in bidding order (dealer last). The bid the
/// dealer may not make is greyed out. After the last bid the panel moves on to
/// the tricks and the bids are stored as an open round.
/// Tricks: one tap per player, the last player is filled in automatically, and
/// one tap confirms. Everything is kept as a draft while the panel is open.
class BoerenbridgePanel extends ConsumerStatefulWidget {
  const BoerenbridgePanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<BoerenbridgePanel> createState() => _BoerenbridgePanelState();
}

class _BoerenbridgePanelState extends ConsumerState<BoerenbridgePanel> {
  PanelContext get ctx => widget.ctx;
  late final BoerenbridgeRules rules = ctx.view.rules as BoerenbridgeRules;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final int cards = rules.cardsInRound(config, number);
  late final List<String> order = rules.bidOrder(config, number);
  late final String dealer = rules.dealer(config, number);

  /// A finished round that is being corrected: do not drop its tricks when
  /// the bids change, and do not jump to the tricks by itself.
  late final bool existingComplete =
      ctx.existing != null &&
      rules.isRoundComplete(
        config,
        RoundData(number: number, entries: ctx.existing!),
      );

  final Map<String, int?> bids = {};
  final Map<String, int?> tricks = {};
  bool tricksStep = false;
  int focus = 0;

  @override
  void initState() {
    super.initState();
    final initial = ctx.initialDraft;
    // Only a draft of this very round (and mode) is restored.
    final draft =
        initial != null &&
            initial['round'] == number &&
            initial['editing'] == ctx.editing
        ? initial
        : null;
    final draftBids = draft?['bids'] as Map?;
    final draftTricks = draft?['tricks'] as Map?;
    for (final p in order) {
      Object? bid;
      Object? won;
      if (draft != null) {
        bid = draftBids == null ? null : draftBids[p];
        won = draftTricks == null ? null : draftTricks[p];
      } else {
        final entry = ctx.existing == null ? null : ctx.existing![p];
        bid = entry == null ? null : entry['bid'];
        won = entry == null ? null : entry['tricks'];
      }
      bids[p] = bid is int ? bid : null;
      tricks[p] = won is int ? won : null;
    }
    tricksStep = draft != null ? draft['step'] == 'tricks' : _allBids;
    focus = draft != null
        ? (draft['focus'] as int? ?? 0)
        : (_firstUnfilled() ?? order.length - 1);
  }

  // ---- derived values --------------------------------------------------

  bool get _allBids => order.every((p) => bids[p] != null);

  /// Tricks with the last player filled in automatically.
  Map<String, int?> get _effTricks => {
    ...tricks,
    order.last: rules.autoLastTricks(config, number, tricks),
  };

  List<bool> get _filled => [
    for (final p in order) (tricksStep ? _effTricks[p] : bids[p]) != null,
  ];

  int? _firstUnfilled() {
    final filled = _filled;
    for (var i = 0; i < filled.length; i++) {
      if (!filled[i]) return i;
    }
    return null;
  }

  int? get _forbiddenDealerBid =>
      rules.forbiddenBidForDealer(config, number, bids);

  bool get _bidsValid => _allBids && bids[dealer] != _forbiddenDealerBid;

  Entries _entries({required bool withTricks}) {
    final eff = _effTricks;
    return {
      for (final p in order)
        p: {
          if (bids[p] != null) 'bid': bids[p],
          if (withTricks && eff[p] != null) 'tricks': eff[p],
        },
    };
  }

  RoundIssue? get _issue => rules.validateRound(
    config,
    RoundData(
      number: number,
      entries: _entries(withTricks: tricksStep),
    ),
  );

  Map<String, Object?> _draftJson() => {
    'round': number,
    'editing': ctx.editing,
    'step': tricksStep ? 'tricks' : 'bids',
    'bids': bids,
    'tricks': tricks,
    'focus': focus,
  };

  void _saveDraft() => ctx.draft.schedule(_draftJson());

  // ---- actions ---------------------------------------------------------

  void _setValue(int value) {
    haptic(ref);
    final wasAllBids = _allBids;
    final player = order[focus];
    setState(() {
      if (tricksStep) {
        tricks[player] = value;
      } else {
        bids[player] = value;
      }
    });
    if (!tricksStep && !wasAllBids && _bidsValid && !existingComplete) {
      _goToTricks();
      return;
    }
    final next = PlayerSelector.nextUnfilled(_filled, focus);
    if (next != null) setState(() => focus = next);
    _saveDraft();
  }

  /// Bids are done: keep them as an open round and show the tricks.
  void _goToTricks() {
    if (!existingComplete) {
      ctx.onSave(_entries(withTricks: false), complete: false);
    }
    setState(() {
      tricksStep = true;
      focus = _firstUnfilled() ?? order.length - 1;
    });
    _saveDraft();
  }

  void _showBids() {
    haptic(ref);
    setState(() {
      tricksStep = false;
      focus = _firstUnfilled() ?? 0;
    });
    _saveDraft();
  }

  void _confirm() {
    haptic(ref);
    ctx.onSave(
      _entries(withTricks: true),
      complete: true,
      undoDraft: ctx.editing ? null : {..._draftJson(), 'step': 'tricks'},
    );
  }

  // ---- build -----------------------------------------------------------

  String _preview(AppLocalizations l10n, {required bool tricksReady}) {
    if (!tricksStep) {
      final forbidden = _forbiddenDealerBid;
      if (_allBids && bids[dealer] == forbidden) {
        return l10n.dealerWarning(forbidden!, cards);
      }
      final sum = order.fold<int>(0, (a, p) => a + (bids[p] ?? 0));
      return l10n.bidsTotal(sum, cards);
    }
    final sum = order.fold<int>(0, (a, p) => a + (_effTricks[p] ?? 0));
    return l10n.tricksTotal(sum, cards);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = ctx.view;
    final player = order[focus];
    final eff = _effTricks;

    final disabled = tricksStep
        ? rules.disabledTricks(config, number, player, tricks)
        : rules.disabledBids(config, number, player, bids);
    final currentValue = tricksStep ? eff[player] : bids[player];

    // A round without all tricks would validate as 'bids only': require them.
    final tricksReady =
        tricksStep && order.every((p) => eff[p] != null) && _issue == null;
    final canConfirm = tricksReady;
    final canGoToTricks = !tricksStep && _bidsValid;

    final scores = tricksReady
        ? rules.scoreRound(
            config,
            RoundData(number: number, entries: _entries(withTricks: true)),
          )
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(value: false, label: Text(l10n.bidsStep)),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.tricksStep),
                      enabled: _bidsValid,
                    ),
                  ],
                  selected: {tricksStep},
                  onSelectionChanged: (s) {
                    if (s.first) {
                      _goToTricks();
                    } else {
                      _showBids();
                    }
                  },
                ),
              ),
            ),
            if (ctx.editing)
              IconButton(
                tooltip: l10n.cancel,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: ctx.onCancel,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: kTouchGap),
        PlayerSelector(
          chips: [
            for (final p in order)
              PlayerChipData(
                label: p == dealer
                    ? '${view.nameOf(p)} · ${l10n.dealerTag}'
                    : view.nameOf(p),
                value: (tricksStep ? eff[p] : bids[p])?.toString(),
                done: (tricksStep ? eff[p] : bids[p]) != null,
              ),
          ],
          selectedIndex: focus,
          onSelected: (i) {
            haptic(ref);
            setState(() => focus = i);
            _saveDraft();
          },
        ),
        const SizedBox(height: kTouchGap),
        QuickButtonRow(
          // many values: smaller buttons (still 48) so they fit two rows
          buttonSize: cards > 9 ? 48 : kTouchTarget,
          gap: cards > 9 ? 6 : kTouchGap,
          values: [for (var i = 0; i <= cards; i++) i],
          selected: currentValue,
          disabled: disabled,
          onSelected: _setValue,
        ),
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Expanded(
              child: scores != null
                  ? LiveScorePreview(
                      scores: [
                        for (final p in order)
                          PreviewScore(view.nameOf(p), scores[p] ?? 0),
                      ],
                    )
                  : LiveScorePreview(
                      scores: const [],
                      message: _preview(l10n, tricksReady: tricksReady),
                      messageIsError:
                          !tricksStep &&
                          _allBids &&
                          bids[dealer] == _forbiddenDealerBid,
                    ),
            ),
            const SizedBox(width: kTouchGap),
            SizedBox(
              width: 156,
              height: kTouchTarget,
              child: FilledButton(
                onPressed: tricksStep
                    ? (canConfirm ? _confirm : null)
                    : (canGoToTricks ? _goToTricks : null),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tricksStep ? l10n.saveTricks : l10n.toTricks),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
