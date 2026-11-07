import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_state.dart';
import '../rules/game_rules.dart';
import '../rules/rikken_rules.dart';
import 'rikken_labels.dart';

/// Bidding screen: who bids, which contract, partner (if the contract has
/// one), tricks won by the bidding side. The preview shows the zero-sum split.
class RikkenEntry extends ConsumerStatefulWidget {
  const RikkenEntry({
    super.key,
    required this.view,
    required this.existing,
    required this.onSubmit,
  });

  final GameView view;
  final Entries? existing;
  final void Function(Entries entries) onSubmit;

  @override
  ConsumerState<RikkenEntry> createState() => _RikkenEntryState();
}

class _RikkenEntryState extends ConsumerState<RikkenEntry> {
  static const _rules = RikkenRules();
  late final GameConfig _config = widget.view.config;

  String? _bidder;
  String? _partner;
  String? _contract;
  int? _tricks;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    for (final p in _config.participants) {
      if (e[p]?['role'] == 'bidder') {
        _bidder = p;
        _contract = e[p]?['contract'] as String?;
        _tricks = e[p]?['tricks'] as int?;
      }
      if (e[p]?['role'] == 'partner') _partner = p;
    }
  }

  RikContract? get _def =>
      _contract == null ? null : RikkenRules.contractOf(_contract!);

  Entries _entries() => {
    for (final p in _config.participants)
      p: {
        'role': p == _bidder
            ? 'bidder'
            : p == _partner
            ? 'partner'
            : 'opp',
        'contract': _contract,
        'tricks': _tricks,
      },
  };

  void _pick(VoidCallback change) {
    haptic(ref);
    setState(change);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final ids = _config.participants;
    final entries = _entries();
    final round = RoundData(number: 1, entries: entries);
    final issue = _rules.validateRound(_config, round);
    final outcome = _rules.outcome(_config, round);
    final needsPartner = _def?.partner ?? false;

    final hint = _bidder == null
        ? l10n.rikChooseBidder
        : _contract == null
        ? l10n.rikChooseContract
        : (needsPartner && _partner == null)
        ? l10n.rikChoosePartner
        : _tricks == null
        ? l10n.rikChooseTricks
        : null;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              section(
                l10n.rikBidder,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in ids)
                      ChoiceChip(
                        label: Text(widget.view.nameOf(p)),
                        selected: _bidder == p,
                        onSelected: (_) => _pick(() {
                          _bidder = p;
                          if (_partner == p) _partner = null;
                        }),
                      ),
                  ],
                ),
              ),
              section(
                l10n.rikContract,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in rikContracts)
                      ChoiceChip(
                        label: Text(rikContractName(l10n, c.id)),
                        selected: _contract == c.id,
                        onSelected: (_) => _pick(() {
                          _contract = c.id;
                          if (!c.partner) _partner = null;
                          // Preselect the tricks the contract needs.
                          _tricks ??= c.target;
                        }),
                      ),
                  ],
                ),
              ),
              if (needsPartner)
                section(
                  l10n.rikPartner,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in ids)
                        if (p != _bidder)
                          ChoiceChip(
                            label: Text(widget.view.nameOf(p)),
                            selected: _partner == p,
                            onSelected: (_) => _pick(() => _partner = p),
                          ),
                    ],
                  ),
                ),
              section(
                l10n.rikTricks,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i <= 13; i++)
                      ChoiceChip(
                        label: Text(
                          '$i',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        showCheckmark: false,
                        selected: _tricks == i,
                        onSelected: (_) => _pick(() => _tricks = i),
                      ),
                  ],
                ),
              ),
              if (issue == null)
                Card(
                  color: scheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outcome.success ? l10n.rikMade : l10n.rikFailed,
                          style: text.titleMedium?.copyWith(
                            color: outcome.success ? null : scheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final p in ids)
                          Row(
                            children: [
                              Expanded(child: Text(widget.view.nameOf(p))),
                              Text(
                                outcome.points[p]! > 0
                                    ? '+${outcome.points[p]}'
                                    : '${outcome.points[p]}',
                                style: text.titleMedium,
                              ),
                            ],
                          ),
                        const Divider(),
                        Text(l10n.zeroSum(outcome.sum), style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(hint, style: TextStyle(color: scheme.error)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: issue == null
                        ? () => widget.onSubmit(entries)
                        : null,
                    child: Text(l10n.saveRound),
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
