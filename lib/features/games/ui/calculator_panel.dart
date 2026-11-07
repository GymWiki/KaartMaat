import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/big_number_pad.dart' show applyKey;
import '../../../core/ui/player_selector.dart';
import '../../../core/ui/touch.dart';
import '../../../core/ui/wide_digit_pad.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/amounts_rules.dart';
import '../rules/game_rules.dart';
import 'calculator_entry.dart' show QuickAmount;
import 'panel_context.dart';

/// Calculator input for games where a round is a sum of amounts (Jokeren,
/// Canasta). Tap a player, type an amount and press "+" to add another; the
/// tape shows what was added and the running sum. "Klaar" (with the next
/// player waiting) jumps on, and for the last player it saves the round.
/// Quick amounts (settings) live on a second page next to the digits.
class CalculatorPanel extends ConsumerStatefulWidget {
  const CalculatorPanel({super.key, required this.ctx, this.quick = const []});

  final PanelContext ctx;
  final List<QuickAmount> quick;

  @override
  ConsumerState<CalculatorPanel> createState() => _CalculatorPanelState();
}

class _CalculatorPanelState extends ConsumerState<CalculatorPanel> {
  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final List<String> ids = config.participants;

  final Map<String, List<int>> amounts = {};
  final Set<String> done = {};
  int focus = 0;
  String typed = '';
  bool quickPage = false;

  @override
  void initState() {
    super.initState();
    for (final p in ids) {
      amounts[p] = [];
    }
    final initial = ctx.initialDraft;
    final usable =
        initial != null &&
        initial['round'] == number &&
        initial['editing'] == ctx.editing;
    if (usable) {
      final saved = initial['amounts'];
      if (saved is Map) {
        for (final p in ids) {
          final list = saved[p];
          if (list is List) {
            amounts[p] = [
              for (final n in list)
                if (n is int) n,
            ];
          }
        }
      }
      final savedDone = initial['done'];
      if (savedDone is List) {
        done.addAll([
          for (final p in savedDone)
            if (p is String) p,
        ]);
      }
      focus = (initial['focus'] as int? ?? 0).clamp(0, ids.length - 1);
      typed = initial['typed'] as String? ?? '';
      quickPage = initial['page'] == 'quick';
    } else if (ctx.existing != null) {
      for (final p in ids) {
        amounts[p] = AmountsRules.amountsOf(ctx.existing![p]);
        done.add(p);
      }
    }
  }

  // ---- derived ---------------------------------------------------------

  String get _current => ids[focus];

  int _sum(String p) => amounts[p]!.fold(0, (a, b) => a + b);

  /// What is typed but not added yet.
  int get _pending => int.tryParse(typed) ?? 0;

  List<String> get _remaining => [
    for (final p in ids)
      if (!done.contains(p)) p,
  ];

  /// The primary button saves the round when this is the last player to do.
  bool get _savesRound {
    final r = _remaining;
    return r.isEmpty || (r.length == 1 && r.first == _current);
  }

  Entries _entries() => {
    for (final p in ids)
      p: {
        'amounts': [
          ...amounts[p]!,
          if (p == _current && _pending != 0) _pending,
        ],
      },
  };

  Map<String, Object?> _draftJson() => {
    'round': number,
    'editing': ctx.editing,
    'amounts': amounts,
    'done': done.toList(),
    'focus': focus,
    'typed': typed,
    'page': quickPage ? 'quick' : 'digits',
  };

  void _update(VoidCallback change) {
    haptic(ref);
    setState(change);
    ctx.draft.schedule(_draftJson());
  }

  void _commitTyped() {
    if (_pending != 0) amounts[_current]!.add(_pending);
    typed = '';
  }

  // ---- actions ---------------------------------------------------------

  void _key(String key) => _update(() => typed = applyKey(typed, key));

  void _add() => _update(_commitTyped);

  void _quick(int amount) => _update(() => amounts[_current]!.add(amount));

  void _undo() => _update(() {
    if (typed.isNotEmpty) {
      typed = '';
    } else if (amounts[_current]!.isNotEmpty) {
      amounts[_current]!.removeLast();
    }
  });

  void _select(int i) => _update(() {
    _commitTyped();
    focus = i;
  });

  void _primary() {
    haptic(ref);
    if (_savesRound) {
      _commitTyped();
      done.add(_current);
      ctx.onSave(
        _entries(),
        complete: true,
        undoDraft: ctx.editing ? null : _draftJson(),
      );
      return;
    }
    setState(() {
      _commitTyped();
      done.add(_current);
      final next = _remaining.first;
      // continue with the next player after this one that still has to go
      final order = [
        for (var s = 1; s <= ids.length; s++) ids[(focus + s) % ids.length],
      ];
      focus = ids.indexOf(
        order.firstWhere((p) => !done.contains(p), orElse: () => next),
      );
    });
    ctx.draft.schedule(_draftJson());
  }

  // ---- build -----------------------------------------------------------

  String _signed(int v) => v < 0 ? '−${-v}' : '$v';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = ctx.view;
    final list = amounts[_current]!;
    final total = _sum(_current) + _pending;

    final tape = Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < list.length; i++)
            TextSpan(
              text: i == 0
                  ? _signed(list[i])
                  : (list[i] < 0 ? ' − ${-list[i]}' : ' + ${list[i]}'),
            ),
          if (typed.isNotEmpty)
            TextSpan(
              text:
                  (list.isEmpty ? '' : ' + ') +
                  (typed == '-' ? '−' : typed.replaceFirst('-', '−')),
              style: TextStyle(
                color: scheme.tertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (list.isEmpty && typed.isEmpty)
            TextSpan(
              text: l10n.calcTapeEmpty,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(fontSize: 18),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ctx.editing)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.editRound(number),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.cancel,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: ctx.onCancel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        PlayerSelector(
          chips: [
            for (final p in ids)
              PlayerChipData(
                label: view.nameOf(p),
                value: (p == _current ? _sum(p) + _pending : _sum(p))
                    .toString(),
                done: done.contains(p),
              ),
          ],
          selectedIndex: focus,
          onSelected: _select,
        ),
        const SizedBox(height: kTouchGap),
        // The tape: everything added for this player, newest at the right.
        Semantics(
          liveRegion: true,
          label: '${view.nameOf(_current)}: ${list.join(', ')} = $total',
          excludeSemantics: true,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ClipRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: tape,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('= ${_signed(total)}', style: text.headlineSmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: kTouchGap),
        if (quickPage && widget.quick.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 3;
              final width =
                  (constraints.maxWidth - kTouchGap * (columns - 1)) / columns;
              return Wrap(
                spacing: kTouchGap,
                runSpacing: kTouchGap,
                children: [
                  for (final q in widget.quick)
                    SizedBox(
                      width: width,
                      height: kTouchTarget,
                      child: Semantics(
                        button: true,
                        label:
                            '${q.label(l10n)} ${q.amount > 0 ? '+' : ''}${q.amount}',
                        excludeSemantics: true,
                        child: Material(
                          color: scheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: scheme.outlineVariant),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _quick(q.amount),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${q.amount > 0 ? '+' : ''}${q.amount}',
                                    style: TextStyle(
                                      fontFamily: AppTheme.numeralFont,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      height: 1.1,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    q.label(l10n),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.1,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        else
          WideDigitPad(onKey: _key, signKey: true),
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
                  onPressed: typed.isNotEmpty || list.isNotEmpty ? _undo : null,
                  child: const Icon(Icons.undo),
                ),
              ),
            ),
            const SizedBox(width: kTouchGap),
            Semantics(
              button: true,
              label: l10n.calcAdd,
              excludeSemantics: true,
              child: SizedBox(
                width: 72,
                height: kTouchTarget,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(72, kTouchTarget),
                  ),
                  onPressed: _pending != 0 ? _add : null,
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ),
            if (widget.quick.isNotEmpty) ...[
              const SizedBox(width: kTouchGap),
              Semantics(
                button: true,
                label: quickPage ? l10n.pageDigits : l10n.pageQuick,
                excludeSemantics: true,
                child: SizedBox(
                  width: 84,
                  height: kTouchTarget,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(84, kTouchTarget),
                    ),
                    onPressed: () => _update(() => quickPage = !quickPage),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(quickPage ? l10n.pageDigits : l10n.pageQuick),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: kTouchGap),
            Expanded(
              child: SizedBox(
                height: kTouchTarget,
                child: FilledButton(
                  onPressed: _primary,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _savesRound ? l10n.saveRoundShort : l10n.calcDone,
                    ),
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
