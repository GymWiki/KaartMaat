import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_state.dart';
import '../rules/boerenbridge_rules.dart';
import '../rules/game_rules.dart';

/// Two steps per round: bids first, tricks won after play. Picking a value is
/// one tap on a number chip. Saving is blocked while the rules are violated.
class BoerenbridgeEntry extends ConsumerStatefulWidget {
  const BoerenbridgeEntry({
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
  ConsumerState<BoerenbridgeEntry> createState() => _BoerenbridgeEntryState();
}

class _BoerenbridgeEntryState extends ConsumerState<BoerenbridgeEntry> {
  late final rules = widget.view.rules as BoerenbridgeRules;
  late final config = widget.view.config;
  late final cards = rules.cardsInRound(config, widget.number);
  late final dealer = rules.dealer(config, widget.number);

  late final Map<String, int?> bids = {
    for (final p in config.participants) p: widget.existing?[p]?['bid'] as int?,
  };
  late final Map<String, int?> tricks = {
    for (final p in config.participants)
      p: widget.existing?[p]?['tricks'] as int?,
  };

  /// Starts on the tricks step once all bids are in.
  late bool tricksStep = bids.values.every((b) => b != null);

  Entries _entries({required bool withTricks}) => {
    for (final p in config.participants)
      p: {
        if (bids[p] != null) 'bid': bids[p],
        if (withTricks && tricks[p] != null) 'tricks': tricks[p],
      },
  };

  int get _bidSum => bids.values.fold(0, (a, b) => a + (b ?? 0));
  int get _trickSum => tricks.values.fold(0, (a, b) => a + (b ?? 0));
  bool get _allBids => bids.values.every((b) => b != null);
  bool get _allTricks => tricks.values.every((t) => t != null);

  /// Warning text and whether saving is allowed on the current step.
  (String?, bool) _status(AppLocalizations l10n) {
    if (!tricksStep) {
      if (!_allBids) return (null, false);
      final issue = rules.validateRound(
        config,
        RoundData(number: widget.number, entries: _entries(withTricks: false)),
      );
      if (issue == RoundIssue.dealerBid) {
        final others = _bidSum - (bids[dealer] ?? 0);
        return (
          l10n.dealerWarning(
            rules.forbiddenDealerBid(config, widget.number, others) ?? 0,
            cards,
          ),
          false,
        );
      }
      return (null, issue == null);
    }
    if (!_allBids || !_allTricks) return (null, false);
    final issue = rules.validateRound(
      config,
      RoundData(number: widget.number, entries: _entries(withTricks: true)),
    );
    return (
      issue == RoundIssue.tricksMismatch ? l10n.tricksWarning(cards) : null,
      issue == null,
    );
  }

  void _submit() {
    if (tricksStep) {
      widget.onSubmit(_entries(withTricks: true));
    } else {
      // Keep tricks only when the round was already complete (a correction).
      widget.onSubmit(_entries(withTricks: _allTricks));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final values = tricksStep ? tricks : bids;
    final order = tricksStep
        ? config.participants
        : rules.bidOrder(config, widget.number);
    final (warning, canSave) = _status(l10n);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.roundOf(widget.number, rules.totalRounds(config))} · ${l10n.cardsCount(cards)}',
                      style: text.titleMedium,
                    ),
                  ),
                  Text(
                    l10n.dealerLabel(widget.view.nameOf(dealer)),
                    style: text.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.bidsStep)),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.tricksStep),
                    enabled: _allBids,
                  ),
                ],
                selected: {tricksStep},
                onSelectionChanged: (s) => setState(() => tricksStep = s.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final p in order)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.view.nameOf(p),
                              style: text.titleMedium,
                            ),
                            if (p == dealer) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(l10n.dealerTag),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                            if (tricksStep) ...[
                              const Spacer(),
                              Text('${l10n.bidsStep}: ${bids[p]}'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i <= cards; i++)
                              ChoiceChip(
                                label: Text(
                                  '$i',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: values[p] == i,
                                showCheckmark: false,
                                onSelected: (_) {
                                  haptic(ref);
                                  setState(() => values[p] = i);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tricksStep
                      ? l10n.tricksTotal(_trickSum, cards)
                      : l10n.bidsTotal(_bidSum, cards),
                  style: text.titleMedium,
                ),
                if (warning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      warning,
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: canSave ? _submit : null,
                  child: Text(tricksStep ? l10n.saveTricks : l10n.saveBids),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
