import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';

/// What Statistieken looks like, with made-up players, for people who have no
/// finished games yet.
class SampleStatsPreview extends StatelessWidget {
  const SampleStatsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    const rows = [
      ('Anna', 12, 7, 58),
      ('Bas', 12, 4, 33),
      ('Chris', 9, 3, 33),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: scheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.emoji_events, size: 32),
              title: Text(l10n.kaartkoningTitle(DateTime.now().year)),
              subtitle: Text(
                'Anna · ${l10n.kaartkoningWins(7, 12)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          DataTable(
            columns: [
              const DataColumn(label: Text('')),
              DataColumn(label: Text(l10n.statsPlayed), numeric: true),
              DataColumn(label: Text(l10n.statsWins), numeric: true),
              DataColumn(label: Text(l10n.statsWinPct), numeric: true),
            ],
            rows: [
              for (final r in rows)
                DataRow(cells: [
                  DataCell(Text(r.$1)),
                  DataCell(Text('${r.$2}')),
                  DataCell(Text('${r.$3}')),
                  DataCell(Text('${r.$4}%')),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}

/// What Historie looks like, with made-up games.
class SampleHistoryPreview extends StatelessWidget {
  const SampleHistoryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const games = [
      (Icons.groups, 'Klaverjassen', '12 mei 2026', 'Anna & Chris'),
      (Icons.style, 'Boerenbridge', '5 mei 2026', 'Bas'),
      (Icons.favorite, 'Hartenjagen', '28 apr 2026', 'Dora'),
    ];
    return Column(
      children: [
        for (final g in games)
          ListTile(
            leading: Icon(g.$1),
            title: Text(g.$2),
            subtitle: Text('${g.$3} · ${l10n.winnerLabel(g.$4)}'),
            trailing: const Icon(Icons.chevron_right),
          ),
      ],
    );
  }
}
