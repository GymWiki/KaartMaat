import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/big_number_pad.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_state.dart';
import '../rules/custom_rules.dart';
import '../rules/game_rules.dart';

/// Generic entry: one signed whole number per participant, typed on the
/// custom keypad. The big bottom button moves to the next player, and saves
/// on the last one.
class PointsEntry extends ConsumerStatefulWidget {
  const PointsEntry({
    super.key,
    required this.view,
    required this.existing,
    required this.onSubmit,
  });

  final GameView view;
  final Entries? existing;
  final void Function(Entries entries) onSubmit;

  @override
  ConsumerState<PointsEntry> createState() => _PointsEntryState();
}

class _PointsEntryState extends ConsumerState<PointsEntry> {
  late final List<String> _ids = widget.view.config.participants;
  late final Map<String, String> _text = {
    for (final p in _ids) p: widget.existing?[p]?['points']?.toString() ?? '',
  };
  int _focus = 0;

  bool get _last => _focus == _ids.length - 1;

  late final int _step = () {
    final s = widget.view.config.intSetting(CustomRules.stepKey);
    return s < 1 ? 1 : s;
  }();

  void _adjust(int sign) {
    haptic(ref);
    final p = _ids[_focus];
    final current = int.tryParse(_text[p]!) ?? 0;
    setState(() => _text[p] = '${current + sign * _step}');
  }

  void _key(String key) {
    haptic(ref);
    final p = _ids[_focus];
    setState(() => _text[p] = applyKey(_text[p]!, key));
  }

  void _submit() {
    final entries = <String, Entry>{};
    for (final e in _text.entries) {
      final v = int.tryParse(e.value);
      if (v != null) entries[e.key] = {'points': v};
    }
    widget.onSubmit(entries);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (var i = 0; i < _ids.length; i++)
                Card(
                  color: i == _focus ? scheme.primaryContainer : null,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => _focus = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Expanded(
                          child: Text(widget.view.nameOf(_ids[i]),
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          _text[_ids[i]]!.isEmpty ? '–' : _text[_ids[i]]!,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  for (final sign in [-1, 1])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: () => _adjust(sign),
                            child: Text(sign < 0 ? '−$_step' : '+$_step'),
                          ),
                        ),
                      ),
                    ),
                ]),
                BigNumberPad(onKey: _key),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _last
                        ? _submit
                        : () => setState(() => _focus++),
                    child: Text(_last ? l10n.saveRound : l10n.next),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
