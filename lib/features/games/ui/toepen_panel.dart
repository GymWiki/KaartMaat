import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/touch.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/game_rules.dart';
import '../rules/toepen_rules.dart';
import 'panel_context.dart';

/// Toepen input on the game screen: one tile per player. A tap on a name adds
/// one point, the minus button takes one off. Every tap is stored at once in
/// the latest round; "Volgende ronde" starts a new one. A player one point
/// short of the limit is marked "op pelt", a player at the limit "uit" (and
/// can no longer collect points).
class ToepenPanel extends ConsumerStatefulWidget {
  const ToepenPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<ToepenPanel> createState() => _ToepenPanelState();
}

class _ToepenPanelState extends ConsumerState<ToepenPanel> {
  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final List<String> ids = config.participants;
  late final int limit = config.intSetting(ToepenRules.limitKey);
  late final bool povertyOn = config.boolSetting(ToepenRules.povertyKey);

  final Map<String, int> points = {};

  /// Taps in this panel, newest last, so "undo" can take them back.
  final List<(String, int)> history = [];

  @override
  void initState() {
    super.initState();
    for (final p in ids) {
      final v = ctx.existing?[p]?['points'];
      points[p] = v is int ? v : 0;
    }
  }

  Entries _entries() => {
    for (final p in ids) p: {'points': points[p]},
  };

  /// Totals including what is tapped in this round.
  Map<String, int> _totals() => ctx.view.rules.totals(config, [
    for (final r in ctx.view.state.rounds)
      if (r.number != number) r,
    RoundData(number: number, entries: _entries()),
  ]);

  void _change(String player, int delta, {bool record = true}) {
    haptic(ref);
    setState(() {
      points[player] = points[player]! + delta;
      if (record) history.add((player, delta));
    });
    ctx.onSave(_entries(), complete: false);
    ctx.draft.schedule({'round': number, 'editing': ctx.editing});
  }

  void _undo() {
    if (history.isEmpty) return;
    final (player, delta) = history.removeLast();
    _change(player, -delta, record: false);
  }

  Future<void> _nextRound() async {
    haptic(ref);
    final next = ctx.onNewRound;
    if (next == null) return;
    await next(ToepenRules.zeroEntries(config));
  }

  Widget _tile(
    AppLocalizations l10n,
    String p,
    int total,
    double width,
    bool dense,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final out = total >= limit;
    final onPelt = povertyOn && !out && total == limit - 1;
    final inRound = points[p]!;
    final name = ctx.view.nameOf(p);
    final badge = out
        ? l10n.toepenOutBadge
        : onPelt
        ? l10n.toepenPovertyBadge
        : l10n.counterThisRound(inRound > 0 ? '+$inRound' : '$inRound');
    final warn = out || onPelt;

    return Semantics(
      container: true,
      label: '$name, $total, ${out ? l10n.toepenOutBadge : badge}',
      customSemanticsActions: {
        if (!out)
          CustomSemanticsAction(label: l10n.counterPlus(1)): () =>
              _change(p, 1),
        CustomSemanticsAction(label: l10n.counterMinus(1)): () =>
            _change(p, -1),
      },
      child: SizedBox(
        width: width,
        height: dense ? 76 : 96,
        child: Material(
          color: out
              ? scheme.surfaceContainerLow
              : scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: onPelt ? scheme.error : scheme.outlineVariant,
              width: onPelt ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: out ? null : () => _change(p, 1),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, dense ? 4 : 8, 4, dense ? 4 : 8),
                    child: Opacity(
                      opacity: out ? 0.55 : 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$total',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontSize: dense ? 30 : 34,
                                    height: 1.0,
                                  ),
                            ),
                          ),
                          Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.2,
                              fontWeight: warn ? FontWeight.w800 : null,
                              color: warn
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Semantics(
                  button: true,
                  label: l10n.counterMinus(1),
                  excludeSemantics: true,
                  child: SizedBox(
                    width: kTouchTarget,
                    height: kTouchTarget,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(kTouchTarget, kTouchTarget),
                      ),
                      onPressed: inRound > 0 ? () => _change(p, -1) : null,
                      child: const Icon(Icons.remove),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totals = _totals();
    final dense = ids.length > 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - kTouchGap) / 2;
            return Wrap(
              spacing: kTouchGap,
              runSpacing: kTouchGap,
              children: [
                for (final p in ids)
                  _tile(l10n, p, totals[p] ?? 0, width, dense),
              ],
            );
          },
        ),
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Semantics(
              button: true,
              label: l10n.undoLastAmount,
              excludeSemantics: true,
              child: SizedBox(
                width: kTouchTarget,
                height: kTouchTarget,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(kTouchTarget, kTouchTarget),
                  ),
                  onPressed: history.isEmpty ? null : _undo,
                  child: const Icon(Icons.undo),
                ),
              ),
            ),
            const SizedBox(width: kTouchGap),
            Expanded(
              child: SizedBox(
                height: kTouchTarget,
                child: FilledButton(
                  onPressed: ctx.editing
                      ? ctx.onCancel
                      : (ctx.onNewRound == null ? null : _nextRound),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(ctx.editing ? l10n.calcDone : l10n.nextRound),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
