import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/game_state.dart';
import '../rules/canasta_rules.dart';

/// Shows the minimum first meld per team, which depends on its score.
class CanastaHeader extends StatelessWidget {
  const CanastaHeader({super.key, required this.view});
  final GameView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totals = view.rules.totals(view.config, view.state.rounds);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.canastaMeldTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final p in view.config.participants)
              Text(
                '${view.nameOf(p)}: ${CanastaRules.initialMeldMinimum(totals[p]!)}',
              ),
          ],
        ),
      ),
    );
  }
}
