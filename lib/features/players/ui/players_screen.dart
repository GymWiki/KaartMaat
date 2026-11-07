import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../data/player_repository.dart';

String nameErrorText(AppLocalizations l10n, PlayerNameError e) => switch (e) {
      PlayerNameError.empty => l10n.nameEmpty,
      PlayerNameError.exists => l10n.nameExists,
    };

/// Asks for a name; [onSubmit] returns an error to keep the dialog open.
Future<void> showNameDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  required Future<PlayerNameError?> Function(String name) onSubmit,
}) {
  final controller = TextEditingController(text: initial);
  String? error;
  return showDialog<void>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) {
        Future<void> submit() async {
          final e = await onSubmit(controller.text);
          if (!dialog.mounted) return;
          if (e == null) {
            Navigator.pop(dialog);
          } else {
            setState(() => error = nameErrorText(dialog.l10n, e));
          }
        }

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: dialog.l10n.playerName, errorText: error),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(dialog.l10n.cancel),
            ),
            TextButton(onPressed: submit, child: Text(dialog.l10n.save)),
          ],
        );
      },
    ),
  );
}

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final players = ref.watch(playersProvider).value ?? const [];
    final repo = ref.read(playerRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.playersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNameDialog(
          context,
          title: l10n.addPlayer,
          onSubmit: (n) async => (await repo.add(n)).error,
        ),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addPlayer),
      ),
      body: players.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.noPlayers, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final p in players)
                  ListTile(
                    title: Text(p.name, style: const TextStyle(fontSize: 18)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        tooltip: l10n.renamePlayer,
                        icon: const Icon(Icons.edit),
                        onPressed: () => showNameDialog(
                          context,
                          title: l10n.renamePlayer,
                          initial: p.name,
                          onSubmit: (n) => repo.rename(p.id, n),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (await confirmDialog(
                              context, l10n.deletePlayerConfirm(p.name),
                              actionLabel: l10n.delete)) {
                            await repo.delete(p.id);
                          }
                        },
                      ),
                    ]),
                  ),
              ],
            ),
    );
  }
}
