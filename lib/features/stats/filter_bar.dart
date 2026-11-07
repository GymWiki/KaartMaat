import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../games/data/game_state.dart';
import '../games/games_registry.dart';
import '../groups/data/group_repository.dart';
import 'stats_calculator.dart';

class FilterNotifier extends Notifier<GameFilter> {
  @override
  GameFilter build() => const GameFilter();

  void set(GameFilter filter) => state = filter;
}

final historyFilterProvider =
    NotifierProvider<FilterNotifier, GameFilter>(FilterNotifier.new);
final statsFilterProvider =
    NotifierProvider<FilterNotifier, GameFilter>(FilterNotifier.new);

class _Option<T> {
  const _Option(this.value);
  final T? value;
}

/// Filter chips for game, group and year.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key, required this.provider, required this.games});

  final NotifierProvider<FilterNotifier, GameFilter> provider;

  /// All finished games, used to offer the years that exist.
  final List<GameState> games;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final groups = ref.watch(groupsProvider).value ?? const <GroupRef>[];
    final years = yearsOf(games);

    Widget menu<T>({
      required String label,
      required T? value,
      required String valueLabel,
      required List<(T?, String)> options,
      required void Function(T?) onSelected,
    }) =>
        PopupMenuButton<_Option<T>>(
          onSelected: (o) => onSelected(o.value),
          itemBuilder: (_) => [
            PopupMenuItem(value: _Option<T>(null), child: Text(l10n.filterAll)),
            for (final (v, text) in options)
              PopupMenuItem(value: _Option<T>(v), child: Text(text)),
          ],
          child: Chip(
            avatar: value == null ? null : const Icon(Icons.filter_alt, size: 18),
            label: Text('$label: $valueLabel'),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        menu<String>(
          label: l10n.filterGame,
          value: filter.type,
          valueLabel: filter.type == null
              ? l10n.filterAll
              : definitionFor(filter.type!).name(l10n),
          options: [
            for (final e in gameDefinitions.entries) (e.key, e.value.name(l10n)),
          ],
          onSelected: (v) => notifier.set(filter.copyWith(type: v)),
        ),
        const SizedBox(width: 8),
        if (groups.isNotEmpty) ...[
          menu<int>(
            label: l10n.filterGroup,
            value: filter.groupId,
            valueLabel: filter.groupId == null
                ? l10n.filterAll
                : groups.where((g) => g.id == filter.groupId).firstOrNull?.name ?? '?',
            options: [for (final g in groups) (g.id, g.name)],
            onSelected: (v) => notifier.set(filter.copyWith(groupId: v)),
          ),
          const SizedBox(width: 8),
        ],
        menu<int>(
          label: l10n.filterYear,
          value: filter.year,
          valueLabel: filter.year?.toString() ?? l10n.filterAll,
          options: [for (final y in years) (y, '$y')],
          onSelected: (v) => notifier.set(filter.copyWith(year: v)),
        ),
      ]),
    );
  }
}
