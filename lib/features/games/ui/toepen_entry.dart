import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_state.dart';
import '../rules/game_rules.dart';
import '../rules/toepen_rules.dart';

/// One round of Toepen: who won, how often was knocked ("kloppen"), and for
/// everybody else whether they played on or folded at which knock.
class ToepenEntry extends ConsumerStatefulWidget {
  const ToepenEntry({
    super.key,
    required this.view,
    required this.number,
    required this.existing,
    required this.onSubmit,
  });

  final GameView view;
  final int number;
  final Entries? existing;
  final void Function(Entries entries) onSubmit;

  @override
  ConsumerState<ToepenEntry> createState() => _ToepenEntryState();
}

class _ToepenEntryState extends ConsumerState<ToepenEntry> {
  static const _rules = ToepenRules();
  late final GameConfig _config = widget.view.config;
  late final List<RoundData> _before = [
    for (final r in widget.view.state.rounds)
      if (r.number < widget.number) r,
  ];
  late final ToepenSituation _sit = _rules.situation(_config, _before);

  String? _winner;
  int _knocks = 0;
  final Map<String, int?> _fold = {};

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    for (final p in _config.participants) {
      if (e[p]?['winner'] == true) _winner = p;
      _knocks = (e[p]?['knocks'] as int?) ?? _knocks;
      _fold[p] = e[p]?['foldAt'] as int?;
    }
  }

  int get _effective => _knocks + (_sit.poverty.isEmpty ? 0 : 1);

  Entries _entries() => {
        for (final p in _config.participants)
          p: {
            'winner': p == _winner,
            'knocks': _knocks,
            if (p != _winner && !_sit.out.contains(p) && _fold[p] != null)
              'foldAt': _fold[p],
          },
      };

  void _setKnocks(int k) {
    haptic(ref);
    setState(() {
      _knocks = k.clamp(0, 30);
      _fold.updateAll((p, f) => f != null && f > _effective ? null : f);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final alive = _sit.alive(_config);
    final entries = _entries();
    final round = RoundData(number: widget.number, entries: entries);
    final issue = _rules.validateRound(_config, round);
    final scores = _rules.roundScores(_config, [..._before, round]).last;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_sit.poverty.isNotEmpty)
                Card(
                  color: scheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text(l10n.toepenInPoverty(
                        _sit.poverty.map(widget.view.nameOf).join(', '))),
                    subtitle: Text(l10n.toepenPovertyKnock),
                  ),
                ),
              Text(l10n.toepenWinner, style: text.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in alive)
                  ChoiceChip(
                    label: Text(widget.view.nameOf(p)),
                    selected: _winner == p,
                    onSelected: (_) {
                      haptic(ref);
                      setState(() {
                        _winner = p;
                        _fold[p] = null;
                      });
                    },
                  ),
              ]),
              const SizedBox(height: 20),
              Text(l10n.toepenKnocks, style: text.titleMedium),
              const SizedBox(height: 8),
              Row(children: [
                SizedBox(
                  width: 72,
                  height: 56,
                  child: FilledButton.tonal(
                    onPressed: _knocks > 0 ? () => _setKnocks(_knocks - 1) : null,
                    child: const Icon(Icons.remove),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('$_knocks',
                        style: text.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(
                  width: 72,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => _setKnocks(_knocks + 1),
                    child: const Icon(Icons.add),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              for (final p in alive)
                if (p != _winner)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.view.nameOf(p), style: text.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            ChoiceChip(
                              label: Text(l10n.toepenStay),
                              selected: _fold[p] == null,
                              onSelected: (_) =>
                                  setState(() => _fold[p] = null),
                            ),
                            for (var j = 1; j <= _effective; j++)
                              ChoiceChip(
                                label: Text(l10n.toepenFoldAt(j)),
                                selected: _fold[p] == j,
                                onSelected: (_) {
                                  haptic(ref);
                                  setState(() => _fold[p] = j);
                                },
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
              if (issue == null)
                Card(
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      for (final p in _config.participants)
                        Row(children: [
                          Expanded(child: Text(widget.view.nameOf(p))),
                          Text('+${scores[p]}  →  ${_sit.totals[p]! + scores[p]!}',
                              style: text.titleMedium),
                          if (_sit.totals[p]! + scores[p]! >=
                              _config.intSetting(ToepenRules.limitKey))
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(l10n.toepenOutBadge,
                                  style: TextStyle(
                                      color: scheme.error,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ]),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_winner == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(l10n.toepenChooseWinner,
                      style: TextStyle(color: scheme.error)),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: issue == null ? () => widget.onSubmit(entries) : null,
                  child: Text(l10n.saveRound),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
