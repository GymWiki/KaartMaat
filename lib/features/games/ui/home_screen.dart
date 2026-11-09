import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/content_width.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/suits.dart';
import '../data/game_repository.dart';
import '../games_registry.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final running = ref.watch(unfinishedIdsProvider).value ?? const <int>[];
    final games = gameDefinitions.values.toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ContentWidth(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (running.isNotEmpty) _ResumeCard(gameId: running.first),
          if (running.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                context.l10n.otherRunningGames,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final id in running.skip(1)) _RunningGameTile(gameId: id),
            const SizedBox(height: 16),
          ],
          GridView.count(
            // two columns on a phone, three from tablet width
            crossAxisCount: MediaQuery.sizeOf(context).width >= kTabletWidth ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              for (var i = 0; i < games.length; i++)
                _GameCard(
                  def: games[i],
                  suit: games[i].suit,
                  onTap: () => context.push('/new/${games[i].id}'),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// The unfinished game, in the accent color so it is the first thing to tap.
class _ResumeCard extends ConsumerWidget {
  const _ResumeCard({required this.gameId});
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(gameStateProvider(gameId)).value;
    if (state == null) return const SizedBox.shrink();
    final name = definitionFor(state.type).name(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: scheme.primary,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.push('/game/$gameId'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.resumeGame,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                      Text(
                        l10n.resumeSubtitle(name, state.rounds.length),
                        style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill, size: 40, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An older unfinished game: open it, or delete it.
class _RunningGameTile extends ConsumerWidget {
  const _RunningGameTile({required this.gameId});
  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(gameStateProvider(gameId)).value;
    if (state == null) return const SizedBox.shrink();
    final name = definitionFor(state.type).name(l10n);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(definitionFor(state.type).icon),
      title: Text(name),
      subtitle: Text(l10n.roundsCount(state.rounds.length)),
      onTap: () => context.push('/game/$gameId'),
      trailing: IconButton(
        tooltip: l10n.deleteGame,
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          if (await confirmDialog(
            context,
            l10n.deleteGameConfirm,
            actionLabel: l10n.delete,
          )) {
            await ref.read(gameRepositoryProvider).deleteGame(gameId);
          }
        },
      ),
    );
  }
}

/// A game as a playing card: suit in the corner, name at the bottom.
class _GameCard extends StatelessWidget {
  const _GameCard({required this.def, required this.suit, required this.onTap});

  final GameDefinition def;
  final Suit suit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final players = def.minPlayers == def.maxPlayers
        ? '${def.minPlayers}'
        : '${def.minPlayers}–${def.maxPlayers}';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SuitPip(suit, size: 24),
                  const Spacer(),
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    players,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(def.name(l10n), style: text.titleLarge),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 34,
                child: Text(
                  def.description(l10n),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
