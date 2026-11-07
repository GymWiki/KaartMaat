import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_repository.dart';
import '../data/game_state.dart';
import '../games_registry.dart';
import '../rules/game_rules.dart';

String issueText(AppLocalizations l10n, RoundIssue issue) => switch (issue) {
  RoundIssue.missingEntry || RoundIssue.invalidValue => l10n.invalidEntry,
  RoundIssue.outOfRange => l10n.issueOutOfRange,
  RoundIssue.dealerBid => l10n.issueDealerBid,
  RoundIssue.tricksMismatch => l10n.issueTricksMismatch,
};

/// New round when [number] is past the last round, otherwise a correction.
class RoundEntryScreen extends ConsumerWidget {
  const RoundEntryScreen({
    super.key,
    required this.gameId,
    required this.number,
  });

  final int gameId;
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider(gameId)).value;
    if (state == null) return Scaffold(appBar: AppBar());

    final view = GameView(state);
    final existing = state.rounds.where((r) => r.number == number).firstOrNull;
    final l10n = context.l10n;

    Future<void> submit(Entries entries) async {
      final issue = view.rules.validateRound(
        view.config,
        RoundData(number: number, entries: entries),
      );
      if (issue != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(issueText(l10n, issue))));
        return;
      }
      haptic(ref);
      final repo = ref.read(gameRepositoryProvider);
      if (existing != null) {
        await repo.updateRound(gameId, number, entries);
      } else {
        await repo.addRound(gameId, entries);
      }
      if (context.mounted) context.pop();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          existing != null ? l10n.editRound(number) : l10n.enterRound(number),
        ),
      ),
      body: definitionFor(
        state.type,
      ).entryBuilder(view, number, existing?.entries, submit),
    );
  }
}
