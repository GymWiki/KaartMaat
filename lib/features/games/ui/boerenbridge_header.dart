import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/game_state.dart';
import '../rules/boerenbridge_rules.dart';

/// Current round, cards this round and dealer, big enough to read at a glance.
class BoerenbridgeHeader extends StatelessWidget {
  const BoerenbridgeHeader({super.key, required this.view});
  final GameView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final rules = view.rules as BoerenbridgeRules;
    final total = rules.totalRounds(view.config);
    final n = view.nextRoundNumber;

    if (!view.canAddRound) {
      return Card(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: ListTile(
          leading: const Icon(Icons.flag),
          title: Text(l10n.gameOver, style: text.titleLarge),
        ),
      );
    }

    final bids = view.openRound?.entries;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(l10n.roundOf(n, total), style: text.titleLarge),
              ),
              Text(l10n.cardsCount(rules.cardsInRound(view.config, n)),
                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Text(l10n.dealerLabel(view.nameOf(rules.dealer(view.config, n))),
                style: text.titleMedium),
            if (bids != null) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.bidsSoFar}: ${[
                  for (final p in view.config.participants)
                    '${view.nameOf(p)} ${bids[p]?['bid']}',
                ].join(' · ')}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
