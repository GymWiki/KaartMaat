import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/game_state.dart';
import '../rules/klaverjas_rules.dart';

/// Current deal and dealer.
class KlaverjasHeader extends StatelessWidget {
  const KlaverjasHeader({super.key, required this.view});
  final GameView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final rules = view.rules as KlaverjasRules;
    final planned = rules.plannedRounds(view.config);
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
    final dealer = rules.dealer(view.config, n);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: Text(
              planned == null ? l10n.roundTitle(n) : l10n.roundOf(n, planned),
              style: text.titleLarge,
            ),
          ),
          Text(l10n.dealerLabel(view.nameOf(dealer)), style: text.titleMedium),
        ]),
      ),
    );
  }
}
