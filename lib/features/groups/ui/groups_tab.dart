import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../players/data/player_repository.dart';
import '../data/group_repository.dart';

/// Saved card groups: tap to edit, add with the button.
class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groups = ref.watch(groupsProvider).value ?? const <GroupRef>[];
    final names = {
      for (final p in ref.watch(playersProvider).value ?? const []) p.id: p.name,
    };

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/new'),
        icon: const Icon(Icons.group_add),
        label: Text(l10n.addGroup),
      ),
      body: groups.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.noGroups, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final g in groups)
                  ListTile(
                    leading: const Icon(Icons.groups),
                    title: Text(g.name, style: const TextStyle(fontSize: 18)),
                    subtitle: Text(
                        [for (final id in g.memberIds) names[id] ?? '?'].join(', ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/groups/${g.id}'),
                  ),
              ],
            ),
    );
  }
}
