import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/touch.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/custom_rules.dart';
import '../rules/game_rules.dart';
import 'panel_context.dart';

/// Algemene teller: one large tile per player. A tap adds the step, a long
/// press (or the visible minus button) takes it off. Every tap is stored at
/// once in the latest round, so continuous counting just works, and "Volgende
/// ronde" starts a new round when the table wants round totals. The step is
/// chosen with quick buttons (1, 5, 10) or a custom value.
class CounterPanel extends ConsumerStatefulWidget {
  const CounterPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<CounterPanel> createState() => _CounterPanelState();
}

class _CounterPanelState extends ConsumerState<CounterPanel> {
  static const _presets = [1, 5, 10];

  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final List<String> ids = config.participants;

  final Map<String, int> points = {};
  late int step;

  /// Taps in this panel, newest last, so "undo" can take them back.
  final List<(String, int)> history = [];

  @override
  void initState() {
    super.initState();
    for (final p in ids) {
      final v = ctx.existing?[p]?['points'];
      points[p] = v is int ? v : 0;
    }
    step = CustomRules.defaultStep(config);
    // The chosen step is remembered with the draft, also across rounds.
    final saved = ctx.initialDraft?['step'];
    if (saved is int && saved >= 1) step = saved;
  }

  // ---- actions ---------------------------------------------------------

  Entries _entries() => {
    for (final p in ids) p: {'points': points[p]},
  };

  void _store() {
    ctx.onSave(_entries(), complete: false);
    ctx.draft.schedule({'round': number, 'editing': ctx.editing, 'step': step});
  }

  void _change(String player, int delta, {bool record = true}) {
    haptic(ref);
    setState(() {
      points[player] = points[player]! + delta;
      if (record) history.add((player, delta));
    });
    _store();
  }

  void _undo() {
    if (history.isEmpty) return;
    final (player, delta) = history.removeLast();
    _change(player, -delta, record: false);
  }

  void _setStep(int value) {
    haptic(ref);
    setState(() => step = value);
    ctx.draft.schedule({'round': number, 'editing': ctx.editing, 'step': step});
  }

  Future<void> _customStep() async {
    final value = await intDialog(
      context,
      title: context.l10n.counterCustomStep,
      initial: step,
      min: 1,
      max: 100000,
    );
    if (value != null && mounted) _setStep(value);
  }

  Future<void> _nextRound() async {
    haptic(ref);
    final next = ctx.onNewRound;
    if (next == null) return;
    await next(CustomRules.zeroEntries(config));
  }

  // ---- build -----------------------------------------------------------

  Widget _stepChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    String? semantics,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: semantics ?? label,
        excludeSemantics: true,
        child: SizedBox(
          height: kTouchTarget,
          child: Material(
            color: selected ? scheme.primary : scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.numeralFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: selected ? AppTheme.ink : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(AppLocalizations l10n, String p, double width) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = ctx.view;
    final total =
        (view.rules.totals(config, [
          for (final r in view.state.rounds)
            if (r.number != number) r,
          RoundData(number: number, entries: _entries()),
        ])[p]) ??
        0;
    final inRound = points[p]!;
    // 7 or 8 players: one line less per tile, so the panel still fits.
    final tight = ids.length > 6;

    return Semantics(
      container: true,
      label: '${view.nameOf(p)}, $total',
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.counterPlus(step)): () =>
            _change(p, step),
        CustomSemanticsAction(label: l10n.counterMinus(step)): () =>
            _change(p, -step),
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: tight ? 60 : (ids.length > 4 ? 76 : 96),
        ),
        child: Material(
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _change(p, step),
                  onLongPress: () => _change(p, -step),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, ids.length > 4 ? 4 : 8, 4, ids.length > 4 ? 4 : 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.nameOf(p),
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
                          child: Text.rich(
                            TextSpan(
                              text: '$total',
                              children: [
                                if (tight && inRound != 0)
                                  TextSpan(
                                    text: '  ${inRound > 0 ? '+' : ''}$inRound',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            style: text.displaySmall?.copyWith(
                              fontSize: ids.length > 4 ? 30 : 34,
                              height: 1.0,
                            ),
                          ),
                        ),
                        if (!tight)
                        Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          l10n.counterThisRound(
                            inRound > 0 ? '+$inRound' : '$inRound',
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.2,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Semantics(
                  button: true,
                  label: l10n.counterMinus(step),
                  excludeSemantics: true,
                  child: SizedBox(
                    width: kTouchTarget,
                    height: kTouchTarget,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(kTouchTarget, kTouchTarget),
                      ),
                      onPressed: () => _change(p, -step),
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
    final custom = !_presets.contains(step);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final preset in _presets) ...[
              _stepChip(
                '+$preset',
                step == preset,
                () => _setStep(preset),
                semantics: l10n.counterStepSemantics(preset),
              ),
              const SizedBox(width: kTouchGap),
            ],
            _stepChip(
              custom ? '+$step' : l10n.counterCustom,
              custom,
              _customStep,
              semantics: l10n.counterCustomStep,
            ),
          ],
        ),
        const SizedBox(height: kTouchGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - kTouchGap) / 2;
            return Wrap(
              spacing: kTouchGap,
              runSpacing: kTouchGap,
              children: [for (final p in ids) _tile(l10n, p, width)],
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
                  onPressed: ctx.editing ? ctx.onCancel : (ctx.onNewRound == null ? null : _nextRound),
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
