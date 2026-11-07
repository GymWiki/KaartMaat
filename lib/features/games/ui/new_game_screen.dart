import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../groups/data/group_repository.dart';
import '../../players/data/player_repository.dart';
import '../../players/ui/players_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/ui/settings_editor.dart';
import '../data/game_repository.dart';
import '../games_registry.dart';

class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key, required this.type});
  final String type;

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  /// Tap order is seat order.
  final List<int> _selected = [];
  int? _groupId;
  late final Map<String, Object?> _options = ref
      .read(prefsProvider)
      .ruleOptions(definitionFor(widget.type).rules);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final def = definitionFor(widget.type);
    final rules = def.rules;
    final players = ref.watch(playersProvider).value ?? const [];
    final groups = ref.watch(groupsProvider).value ?? const <GroupRef>[];
    final count = _selected.length;
    final valid = count >= rules.minPlayers && count <= rules.maxPlayers;

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.newGame}: ${def.name(l10n)}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (groups.isNotEmpty) ...[
                  Text(
                    l10n.startFromGroup,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in groups)
                        ChoiceChip(
                          avatar: const Icon(Icons.groups, size: 18),
                          label: Text(g.name),
                          selected: _groupId == g.id,
                          onSelected: (on) => setState(() {
                            if (on) {
                              _groupId = g.id;
                              _selected
                                ..clear()
                                ..addAll(g.memberIds.take(rules.maxPlayers));
                            } else {
                              _groupId = null;
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.choosePlayers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in players)
                      FilterChip(
                        label: Text(
                          _selected.contains(p.id)
                              ? '${_selected.indexOf(p.id) + 1} · ${p.name}'
                              : p.name,
                        ),
                        selected: _selected.contains(p.id),
                        onSelected: (on) => setState(() {
                          if (on) {
                            if (count < rules.maxPlayers) _selected.add(p.id);
                            final g = groups
                                .where((g) => g.id == _groupId)
                                .firstOrNull;
                            if (g != null && !g.memberIds.contains(p.id)) {
                              _groupId = null;
                            }
                          } else {
                            _selected.remove(p.id);
                          }
                        }),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add),
                      label: Text(l10n.newPlayer),
                      onPressed: () => showNameDialog(
                        context,
                        title: l10n.addPlayer,
                        onSubmit: (n) async {
                          final r = await ref
                              .read(playerRepositoryProvider)
                              .add(n);
                          if (r.id != null &&
                              _selected.length < rules.maxPlayers) {
                            setState(() => _selected.add(r.id!));
                          }
                          return r.error;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.seatOrderHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (def.newGameHint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      def.newGameHint!(l10n),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (rules.settingSpecs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.rulesSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SettingsEditor(
                    rules: rules,
                    values: _options,
                    onChanged: (k, v) => setState(() => _options[k] = v),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: valid
                      ? () async {
                          final id = await ref
                              .read(gameRepositoryProvider)
                              .createGame(
                                widget.type,
                                _selected,
                                _options,
                                groupId: _groupId,
                              );
                          if (context.mounted) {
                            context.pushReplacement('/game/$id');
                          }
                        }
                      : null,
                  child: Text(
                    valid
                        ? l10n.startGame
                        : l10n.needPlayers(rules.minPlayers, rules.maxPlayers),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
