import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../rulebook/rulebook_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../groups/data/group_repository.dart';
import '../../players/data/player_order.dart';
import '../../players/data/player_repository.dart';
import '../../players/ui/players_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/ui/settings_editor.dart';
import '../data/game_repository.dart';
import '../data/game_state.dart';
import '../games_registry.dart';

/// "Nieuw spel": saved groups on top, the players at the table (in seat
/// order, drag to reorder, tap to remove), then all saved players. With many
/// saved players the list stays short: the most recent ones first, the rest
/// behind "Toon alle", and a search field from 8 players on.
class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key, required this.type});
  final String type;

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  /// How many saved players show before "Toon alle", and when search appears.
  static const _shortList = 8;

  /// Seat order: index 0 is seat 1.
  final List<int> _selected = [];
  int? _groupId;
  bool _showAll = false;
  bool _starting = false;
  String _query = '';
  ScaffoldMessengerState? _messenger;
  late final Map<String, Object?> _options = ref
      .read(prefsProvider)
      .ruleOptions(definitionFor(widget.type).rules);

  @override
  void dispose() {
    final m = _messenger;
    if (m != null && m.mounted) m.hideCurrentSnackBar();
    super.dispose();
  }

  void _say(String text, {SnackBarAction? action}) {
    final m = _messenger = ScaffoldMessenger.of(context);
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  // ---- selection -------------------------------------------------------

  void _add(int id, String gameName, int max) {
    if (_selected.contains(id)) return;
    if (_selected.length >= max) {
      _say(context.l10n.maxPlayersMsg(gameName, max));
      return;
    }
    setState(() => _selected.add(id));
  }

  void _remove(int id) => setState(() => _selected.remove(id));

  void _reorder(int from, int to) => setState(() {
    if (to > from) to--;
    _selected.insert(to, _selected.removeAt(from));
  });

  /// One tap: the group replaces the selection, in its saved seat order.
  void _applyGroup(GroupRef group, String gameName, int max) {
    final l10n = context.l10n;
    final before = [..._selected];
    final beforeGroup = _groupId;
    final seats = seatsForGroup(group, max);
    setState(() {
      _selected
        ..clear()
        ..addAll(seats.ids);
      _groupId = group.id;
    });
    _say(
      seats.dropped > 0
          ? l10n.groupTruncatedMsg(gameName, max, group.name)
          : l10n.groupSelectedMsg(group.name),
      action: SnackBarAction(
        label: l10n.undoAction,
        onPressed: () => setState(() {
          _selected
            ..clear()
            ..addAll(before);
          _groupId = beforeGroup;
        }),
      ),
    );
  }

  Future<void> _saveAsGroup() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setDialog) => AlertDialog(
          title: Text(l10n.saveAsGroup),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.groupName),
            onChanged: (_) => setDialog(() {}),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) Navigator.pop(dialog, v.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialog, controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    final id = await ref
        .read(groupRepositoryProvider)
        .save(name: name, memberIds: [..._selected]);
    if (!mounted) return;
    setState(() => _groupId = id);
    _say(l10n.groupSavedMsg(name));
  }

  // ---- build -----------------------------------------------------------

  Widget _groupRow(
    AppLocalizations l10n,
    List<GroupRef> groups,
    String gameName,
    int max,
  ) {
    final height = MediaQuery.textScalerOf(context).scale(48).clamp(48.0, 96.0);
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final g in groups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                // long press: manage the group (rename, reorder, delete)
                onLongPress: () => context.push('/groups/${g.id}'),
                child: ChoiceChip(
                  avatar: const Icon(Icons.groups, size: 18),
                  label: Text(l10n.groupChipLabel(g.name, g.memberIds.length)),
                  selected:
                      _groupId == g.id &&
                      setEquals(_selected.toSet(), g.memberIds.toSet()),
                  onSelected: (_) => _applyGroup(g, gameName, max),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.add),
              label: Text(l10n.groupChipAdd),
              onPressed: () => context.push('/groups/new'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableBlock(
    AppLocalizations l10n,
    Map<int, PlayerRef> byId,
    String gameName,
    int max,
    GameDefinition def,
  ) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.atTableTitle(_selected.length), style: text.titleMedium),
        const SizedBox(height: 8),
        if (_selected.isEmpty)
          Text(l10n.atTableHint, style: text.bodySmall)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _selected.length,
            onReorder: _reorder,
            itemBuilder: (context, i) {
              final id = _selected[i];
              final name = byId[id]?.name ?? '?';
              return Padding(
                key: ValueKey(id),
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _remove(id),
                    child: Semantics(
                      label: '${i + 1}. $name, ${l10n.removeFromTable}',
                      excludeSemantics: true,
                      button: true,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                child: Text(
                                  '${i + 1}',
                                  textScaler: TextScaler.noScaling,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleMedium,
                                ),
                              ),
                              Icon(
                                Icons.close,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: Semantics(
                                  label: l10n.moveSeat(name),
                                  child: const SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: Icon(Icons.drag_handle),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        if (def.newGameHint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(def.newGameHint!(l10n), style: text.bodySmall),
          ),
        if (_selected.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saveAsGroup,
              icon: const Icon(Icons.group_add),
              label: Text(l10n.saveAsGroup),
            ),
          ),
      ],
    );
  }

  Widget _playersBlock(
    AppLocalizations l10n,
    List<PlayerRef> everyone,
    Map<int, DateTime> last,
    String gameName,
    int max,
  ) {
    final text = Theme.of(context).textTheme;
    final sorted = sortByRecent(everyone, last);
    final free = [
      for (final p in sorted)
        if (!_selected.contains(p.id)) p,
    ];
    final searching = _query.trim().isNotEmpty;
    final matches = filterByName(free, _query);
    final shown = (_showAll || searching)
        ? matches
        : matches.take(_shortList).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.playersTitle, style: text.titleMedium),
        const SizedBox(height: 8),
        if (everyone.length >= _shortList) ...[
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.searchPlayer,
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in shown)
              ActionChip(
                label: Text(p.name),
                onPressed: () => _add(p.id, gameName, max),
              ),
            ActionChip(
              avatar: const Icon(Icons.add),
              label: Text(l10n.newPlayer),
              onPressed: () => showNameDialog(
                context,
                title: l10n.addPlayer,
                onSubmit: (n) async {
                  final r = await ref.read(playerRepositoryProvider).add(n);
                  if (r.id != null && _selected.length < max) {
                    setState(() => _selected.add(r.id!));
                  }
                  return r.error;
                },
              ),
            ),
          ],
        ),
        if (searching && matches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.noPlayerMatch, style: text.bodySmall),
          ),
        if (!searching && matches.length > _shortList)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll
                    ? l10n.showFewerPlayers
                    : l10n.showAllPlayers(matches.length),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _start(List<GroupRef> groups) async {
    if (_starting) return;
    _starting = true;
    setState(() {});
    // the group only counts when the table is still exactly that group
    final group = groups.where((g) => g.id == _groupId).firstOrNull;
    final groupId =
        group != null && setEquals(group.memberIds.toSet(), _selected.toSet())
        ? group.id
        : null;
    final id = await ref
        .read(gameRepositoryProvider)
        .createGame(widget.type, _selected, _options, groupId: groupId);
    if (mounted) context.pushReplacement('/game/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final def = definitionFor(widget.type);
    final rules = def.rules;
    final gameName = def.name(l10n);
    final players = ref.watch(playersProvider).value ?? const <PlayerRef>[];
    final groups = ref.watch(groupsProvider).value ?? const <GroupRef>[];
    final last = ref.watch(lastPlayedProvider).value ?? const {};
    final byId = {for (final p in players) p.id: p};
    // a player deleted while this screen is open leaves the table
    _selected.removeWhere((id) => !byId.containsKey(id));
    final count = _selected.length;
    final valid = count >= rules.minPlayers && count <= rules.maxPlayers;

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.newGame}: $gameName')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _groupRow(l10n, groups, gameName, rules.maxPlayers),
          const SizedBox(height: 16),
          _tableBlock(l10n, byId, gameName, rules.maxPlayers, def),
          const SizedBox(height: 16),
          _playersBlock(l10n, players, last, gameName, rules.maxPlayers),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                showRulebook(context, type: widget.type, settings: _options),
            icon: const Icon(Icons.help_outline),
            label: Text(l10n.rulebookTitle),
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
      // in the bottom bar, so snackbars show above the button instead of on it
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: valid && !_starting ? () => _start(groups) : null,
              child: Text(
                valid
                    ? l10n.startGame
                    : l10n.needPlayers(rules.minPlayers, rules.maxPlayers),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
