import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/touch.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/game_rules.dart';
import '../rules/toepen_rules.dart';
import 'panel_context.dart';

/// Toepen input on the game screen.
///
/// The bar on top shows the stake (what someone who plays on and loses gets)
/// and a "Kloppen" button that raises it. Tap the tile of the player who won
/// the round; everybody else loses by default. Someone who folds after a knock
/// gets a "Past" button on their tile, which records the knock they folded at
/// (the stake they pay). One tap on "Opslaan" confirms.
class ToepenPanel extends ConsumerStatefulWidget {
  const ToepenPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<ToepenPanel> createState() => _ToepenPanelState();
}

class _ToepenPanelState extends ConsumerState<ToepenPanel> {
  static const _rules = ToepenRules();

  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final List<RoundData> before = [
    for (final r in ctx.view.state.rounds)
      if (r.number < number) r,
  ];
  late final ToepenSituation situation = _rules.situation(config, before);
  late final int limit = config.intSetting(ToepenRules.limitKey);

  String? winner;
  int knocks = 0;
  final Map<String, int?> fold = {};

  @override
  void initState() {
    super.initState();
    final initial = ctx.initialDraft;
    final usable = initial != null &&
        initial['round'] == number &&
        initial['editing'] == ctx.editing;
    if (usable) {
      winner = initial['winner'] as String?;
      knocks = initial['knocks'] as int? ?? 0;
      final saved = initial['fold'];
      if (saved is Map) {
        for (final p in config.participants) {
          final f = saved[p];
          fold[p] = f is int ? f : null;
        }
      }
    } else if (ctx.existing != null) {
      for (final p in config.participants) {
        final e = ctx.existing![p];
        if (e?['winner'] == true) winner = p;
        knocks = (e?['knocks'] as int?) ?? knocks;
        final f = e?['foldAt'];
        fold[p] = f is int ? f : null;
      }
    }
  }

  // ---- derived ---------------------------------------------------------

  int get _effective => knocks + (situation.poverty.isEmpty ? 0 : 1);

  Entries get _entries => _rules.buildEntries(config, situation,
      winner: winner, knocks: knocks, fold: fold);

  RoundData get _round => RoundData(number: number, entries: _entries);

  bool get _canConfirm =>
      winner != null &&
      !situation.out.contains(winner) &&
      _rules.validateRound(config, _round) == null;

  /// Points per player for this round, with the effect of poverty.
  Map<String, int> get _scores => _rules.roundScores(config, [...before, _round]).last;

  Map<String, Object?> _draftJson() => {
        'round': number,
        'editing': ctx.editing,
        'winner': winner,
        'knocks': knocks,
        'fold': fold,
      };

  void _update(VoidCallback change) {
    haptic(ref);
    setState(change);
    ctx.draft.schedule(_draftJson());
  }

  // ---- actions ---------------------------------------------------------

  void _setWinner(String p) => _update(() {
        winner = p;
        fold[p] = null;
      });

  void _knock(int delta) => _update(() {
        knocks = (knocks + delta).clamp(0, 30);
        // a fold at a knock that no longer exists makes no sense
        fold.updateAll((_, f) => f != null && f > _effective ? null : f);
      });

  void _toggleFold(String p) => _update(() {
        fold[p] = fold[p] == null ? _effective : null;
        if (winner == p) winner = null;
      });

  void _confirm() {
    haptic(ref);
    ctx.onSave(_entries, complete: true, undoDraft: ctx.editing ? null : _draftJson());
  }

  // ---- build -----------------------------------------------------------

  Widget _tile(AppLocalizations l10n, String p, double width) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = ctx.view;
    final out = situation.out.contains(p);
    final isWinner = winner == p;
    final folded = fold[p];
    final poverty = situation.poverty.contains(p);
    final gain = _scores[p] ?? 0;
    final after = (situation.totals[p] ?? 0) + gain;
    final dead = !out && after >= limit;

    final background = out
        ? scheme.surfaceContainer
        : isWinner
            ? scheme.primary
            : scheme.surfaceContainerHighest;
    final fg = out
        ? scheme.onSurface.withValues(alpha: 0.38)
        : isWinner
            ? AppTheme.ink
            : scheme.onSurface;
    final sub = isWinner ? AppTheme.ink : scheme.onSurfaceVariant;

    return Semantics(
      container: true,
      selected: isWinner,
      label: [
        view.nameOf(p),
        if (out) l10n.toepenOutBadge,
        if (isWinner) l10n.toepenWinnerTile,
        if (folded != null) l10n.toepenFolded(folded),
        if (poverty) l10n.toepenPovertyBadge,
      ].join(', '),
      child: SizedBox(
        width: width,
        height: 76,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: poverty && !isWinner ? scheme.tertiary : scheme.outlineVariant,
              width: poverty ? 2 : 1,
            ),
          ),
          child: Row(children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: out ? null : () => _setWinner(p),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.nameOf(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: fg),
                      ),
                      if (out)
                        Text(l10n.toepenOutBadge, style: TextStyle(fontSize: 12, color: fg))
                      else
                        Row(children: [
                          if (isWinner)
                            Icon(Icons.check_circle, size: 16, color: AppTheme.ink)
                          else
                            Text(
                              '+$gain',
                              style: text.titleMedium?.copyWith(
                                  color: fg, fontWeight: FontWeight.w800, height: 1.1),
                            ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${situation.totals[p]} → $after',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: dead ? scheme.error : sub),
                            ),
                          ),
                        ]),
                      if (poverty && !out)
                        Text(l10n.toepenPovertyBadge,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isWinner ? AppTheme.ink : scheme.tertiary)),
                    ],
                  ),
                ),
              ),
            ),
            if (!out && !isWinner && _effective > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Semantics(
                  button: true,
                  selected: folded != null,
                  label: folded == null ? l10n.toepenFold : l10n.toepenFolded(folded),
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 60,
                    height: kTouchTarget,
                    child: Material(
                      color: folded != null ? scheme.secondary : scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: scheme.outline),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _toggleFold(p),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.toepenFold,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: folded != null ? scheme.onSecondary : scheme.onSurface,
                                ),
                              ),
                              if (folded != null)
                                Text('$folded',
                                    style: TextStyle(fontSize: 12, color: scheme.onSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ids = config.participants;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ctx.editing ? l10n.editRound(number) : l10n.roundTitle(number),
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                Text(l10n.toepenStake(ToepenRules.stakeFor(_effective)),
                    style: text.headlineSmall),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.toepenLessKnock,
            excludeSemantics: true,
            child: SizedBox(
              width: kTouchTarget,
              height: kTouchTarget,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(kTouchTarget, kTouchTarget)),
                onPressed: knocks > 0 ? () => _knock(-1) : null,
                child: const Icon(Icons.remove),
              ),
            ),
          ),
          const SizedBox(width: kTouchGap),
          SizedBox(
            height: kTouchTarget,
            child: FilledButton.icon(
              onPressed: () => _knock(1),
              icon: const Icon(Icons.add),
              label: Text(l10n.toepenKnock),
            ),
          ),
          if (ctx.editing)
            IconButton(
              tooltip: l10n.cancel,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: ctx.onCancel,
              icon: const Icon(Icons.close),
            ),
        ]),
        const SizedBox(height: kTouchGap),
        LayoutBuilder(builder: (context, constraints) {
          final width = (constraints.maxWidth - kTouchGap) / 2;
          return Wrap(
            spacing: kTouchGap,
            runSpacing: kTouchGap,
            children: [for (final p in ids) _tile(l10n, p, width)],
          );
        }),
        const SizedBox(height: kTouchGap),
        Row(children: [
          Expanded(
            child: Text(
              winner == null
                  ? l10n.toepenTapWinner
                  : (situation.poverty.isNotEmpty ? l10n.toepenPovertyKnock : ''),
              style: TextStyle(
                  fontSize: 13,
                  color: winner == null ? scheme.onSurfaceVariant : scheme.tertiary),
            ),
          ),
          SizedBox(
            width: 148,
            height: kTouchTarget,
            child: FilledButton(
              onPressed: _canConfirm ? _confirm : null,
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.saveRound)),
            ),
          ),
        ]),
      ],
    );
  }
}
