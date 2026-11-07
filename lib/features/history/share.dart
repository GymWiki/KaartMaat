import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../games/data/game_state.dart';
import '../games/games_registry.dart';

String buildShareText(AppLocalizations l10n, GameView view) {
  final date = DateFormat('d MMM yyyy', 'nl')
      .format(view.state.finishedAt ?? view.state.createdAt);
  final game = definitionFor(view.state.type).name(l10n);
  return [
    l10n.shareHeader(game, date),
    for (final s in view.standings)
      l10n.shareTotalLine(s.rank, view.nameOf(s.participant), s.total),
  ].join('\n');
}

/// Copies the result as text (a native share sheet needs share_plus).
Future<void> copyResult(BuildContext context, WidgetRef ref, GameView view) async {
  final l10n = context.l10n;
  await Clipboard.setData(ClipboardData(text: buildShareText(l10n, view)));
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.copied)));
  }
}
