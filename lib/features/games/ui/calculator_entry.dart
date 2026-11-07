import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/number_pad.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_state.dart';
import '../rules/amounts_rules.dart';
import '../rules/game_rules.dart';

class QuickAmount {
  const QuickAmount(this.label, this.amount);
  final String Function(AppLocalizations l10n) label;
  final int amount;
}

/// Calculator-style entry: several amounts per participant per round, a
/// running subtotal, quick buttons for fixed amounts and undo of the last
/// amount. Type a number on the keypad and press "+" to add it.
class CalculatorEntry extends ConsumerStatefulWidget {
  const CalculatorEntry({
    super.key,
    required this.view,
    required this.existing,
    required this.onSubmit,
    this.quick = const [],
    this.labelOf,
  });

  final GameView view;
  final Entries? existing;
  final void Function(Entries entries) onSubmit;
  final List<QuickAmount> quick;
  final String Function(String participant)? labelOf;

  @override
  ConsumerState<CalculatorEntry> createState() => _CalculatorEntryState();
}

class _CalculatorEntryState extends ConsumerState<CalculatorEntry> {
  late final List<String> _ids = widget.view.config.participants;
  late final Map<String, List<int>> _amounts = {
    for (final p in _ids) p: AmountsRules.amountsOf(widget.existing?[p]),
  };
  int _focus = 0;
  String _typed = '';

  String get _current => _ids[_focus];

  String _label(String p) => widget.labelOf?.call(p) ?? widget.view.nameOf(p);

  int _sum(String p) => _amounts[p]!.fold(0, (a, b) => a + b);

  void _commitTyped() {
    final v = int.tryParse(_typed);
    if (v != null && v != 0) _amounts[_current]!.add(v);
    _typed = '';
  }

  void _add(int amount) {
    haptic(ref);
    setState(() => _amounts[_current]!.add(amount));
  }

  void _undo() {
    haptic(ref);
    setState(() {
      if (_typed.isNotEmpty) {
        _typed = '';
      } else if (_amounts[_current]!.isNotEmpty) {
        _amounts[_current]!.removeLast();
      }
    });
  }

  void _submit() {
    _commitTyped();
    widget.onSubmit({
      for (final p in _ids) p: {'amounts': [..._amounts[p]!]},
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final typed = int.tryParse(_typed) ?? 0;

    return Column(
      children: [
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              for (var i = 0; i < _ids.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: i == _focus,
                    showCheckmark: false,
                    onSelected: (_) => setState(() {
                      _commitTyped();
                      _focus = i;
                    }),
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_label(_ids[i]), overflow: TextOverflow.ellipsis),
                        Text('${_sum(_ids[i]) + (i == _focus ? typed : 0)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Text(_label(_current), style: text.titleMedium),
              Text(
                '${_sum(_current) + typed}',
                style: text.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final a in _amounts[_current]!)
                  Chip(
                    label: Text(a > 0 ? '+$a' : '$a'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (_typed.isNotEmpty)
                  Chip(
                    label: Text(_typed),
                    backgroundColor: scheme.primaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
              ]),
              if (widget.quick.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final q in widget.quick)
                    ActionChip(
                      label: Text('${q.label(l10n)} ${q.amount > 0 ? '+' : ''}${q.amount}'),
                      onPressed: () => _add(q.amount),
                    ),
                ]),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              NumberPad(onKey: (k) {
                haptic(ref);
                setState(() => _typed = applyKey(_typed, k));
              }),
              Row(children: [
                SizedBox(
                  width: 64,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _undo,
                    child: Tooltip(
                      message: l10n.undoLastAmount,
                      child: const Icon(Icons.undo),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  height: 56,
                  child: FilledButton.tonal(
                    onPressed: typed == 0
                        ? null
                        : () {
                            haptic(ref);
                            setState(_commitTyped);
                          },
                    child: const Icon(Icons.add),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.saveRound),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ],
    );
  }
}
