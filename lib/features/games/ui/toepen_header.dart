import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/game_state.dart';
import '../rules/toepen_rules.dart';

/// Shows who is in poverty ("in de armoe") and who is out.
class ToepenHeader extends StatelessWidget {
  const ToepenHeader({super.key, required this.view});
  final GameView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sit = const ToepenRules().situation(view.config, view.state.rounds);
    if (sit.poverty.isEmpty && sit.out.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sit.poverty.isNotEmpty)
              Text(
                l10n.toepenInPoverty(sit.poverty.map(view.nameOf).join(', ')),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            if (sit.out.isNotEmpty)
              Text(l10n.toepenOut(sit.out.map(view.nameOf).join(', '))),
          ],
        ),
      ),
    );
  }
}
