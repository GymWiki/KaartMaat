import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/game_state.dart';
import 'progress_chart.dart';

/// Ranking, round-by-round table and progression chart.
class StandingsView extends StatelessWidget {
  const StandingsView({super.key, required this.view, this.onTapRound});

  final GameView view;

  /// When set, rows in the table are tappable to correct that round.
  final void Function(int number)? onTapRound;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in view.standings)
          ListTile(
            leading: CircleAvatar(child: Text('${s.rank}')),
            title: Text(view.nameOf(s.participant), style: text.titleMedium),
            trailing: Text('${s.total}',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
        const Divider(height: 32),
        if (view.state.rounds.isEmpty)
          Text(l10n.noRoundsYet)
        else ...[
          _RoundsTable(view: view, onTapRound: onTapRound),
          if (onTapRound != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.tapRoundHint, style: text.bodySmall),
            ),
          const SizedBox(height: 24),
          Text(l10n.progressTitle, style: text.titleMedium),
          const SizedBox(height: 12),
          ProgressChart(view: view),
        ],
      ],
    );
  }
}

class _RoundsTable extends StatelessWidget {
  const _RoundsTable({required this.view, this.onTapRound});
  final GameView view;
  final void Function(int number)? onTapRound;

  @override
  Widget build(BuildContext context) {
    final ids = view.config.participants;
    final totals = {for (final s in view.standings) s.participant: s.total};

    Widget cell(String text, {bool bold = false}) => Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 16, fontWeight: bold ? FontWeight.bold : null)),
          ),
        );

    Widget row(String first, List<String> cells,
            {bool bold = false, VoidCallback? onTap}) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              SizedBox(
                width: 44,
                child: Text(first,
                    style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
              ),
              for (final c in cells) cell(c, bold: bold),
            ]),
          ),
        );

    return Column(
      children: [
        row('#', [
          for (final p in ids) view.nameOf(p),
        ], bold: true),
        const Divider(height: 1),
        for (var i = 0; i < view.state.rounds.length; i++)
          row(
            '${view.state.rounds[i].number}',
            [for (final p in ids) '${view.roundScores[i][p]}'],
            onTap: onTapRound == null
                ? null
                : () => onTapRound!(view.state.rounds[i].number),
          ),
        const Divider(height: 1),
        row(context.l10n.total, [for (final p in ids) '${totals[p]}'], bold: true),
      ],
    );
  }
}
