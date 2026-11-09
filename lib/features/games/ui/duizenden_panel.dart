import 'package:flutter/material.dart';

import '../rules/duizenden_rules.dart';
import 'panel_context.dart';
import 'score_entry_panel.dart';

/// Duizenden input: the shared score entry panel with the new total under
/// every tile and the player(s) who would reach the target marked.
class DuizendenPanel extends StatelessWidget {
  const DuizendenPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  Widget build(BuildContext context) => ScoreEntryPanel(
    ctx: ctx,
    rules: const DuizendenRules(),
    minScore: DuizendenRules.minEntry,
    maxScore: DuizendenRules.maxEntry,
    maxDigits: DuizendenRules.maxDigits,
    target: ctx.view.config.intSetting(DuizendenRules.targetScoreKey),
    showProjection: true,
  );
}
