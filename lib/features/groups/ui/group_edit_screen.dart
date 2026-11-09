import '../../../core/ui/content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../players/data/player_repository.dart';
import '../data/group_repository.dart';

/// Create or edit a group ([groupId] null = new). Selection order is kept.
class GroupEditScreen extends ConsumerStatefulWidget {
  const GroupEditScreen({super.key, this.groupId});
  final int? groupId;

  @override
  ConsumerState<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends ConsumerState<GroupEditScreen> {
  final _name = TextEditingController();
  final List<int> _members = [];
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final players = ref.watch(playersProvider).value ?? const [];
    final groups = ref.watch(groupsProvider).value;
    final existing = widget.groupId == null
        ? null
        : groups?.where((g) => g.id == widget.groupId).firstOrNull;

    if (!_loaded && (widget.groupId == null || existing != null)) {
      _loaded = true;
      if (existing != null) {
        _name.text = existing.name;
        _members.addAll(existing.memberIds);
      }
    }

    final canSave = _name.text.trim().isNotEmpty && _members.length >= 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? l10n.addGroup : l10n.editGroup),
        actions: [
          if (existing != null)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirmDialog(context, l10n.deleteGroupConfirm(existing.name),
                    actionLabel: l10n.delete)) {
                  await ref.read(groupRepositoryProvider).delete(existing.id);
                  if (context.mounted) context.pop();
                }
              },
            ),
        ],
      ),
      body: ContentWidth(
        child: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _name,
                maxLength: 30,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.groupName),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text(l10n.groupMembers, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in players)
                  FilterChip(
                    label: Text(p.name),
                    selected: _members.contains(p.id),
                    onSelected: (on) => setState(() {
                      on ? _members.add(p.id) : _members.remove(p.id);
                    }),
                  ),
              ]),
              if (players.isEmpty) Text(l10n.noPlayers),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSave
                    ? () async {
                        await ref.read(groupRepositoryProvider).save(
                              id: widget.groupId,
                              name: _name.text,
                              memberIds: _members,
                            );
                        if (context.mounted) context.pop();
                      }
                    : null,
                child: Text(l10n.save),
              ),
            ),
          ),
        ),
      ]),
      ),
    );
  }
}
