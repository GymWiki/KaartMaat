import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/games/ui/game_screen.dart';
import '../../features/games/ui/home_screen.dart';
import '../../features/games/ui/new_game_screen.dart';
import '../../features/games/ui/round_entry_screen.dart';
import '../../features/groups/ui/group_edit_screen.dart';
import '../../features/history/finished_game_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/players/ui/players_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../l10n/l10n.dart';

int _id(GoRouterState s, String name) => int.parse(s.pathParameters[name]!);

final appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _NavShell(shell: shell),
      branches: [
        for (final (path, page) in <(String, Widget)>[
          ('/', const HomeScreen()),
          ('/players', const PlayersScreen()),
          ('/history', const HistoryScreen()),
          ('/stats', const StatsScreen()),
          ('/settings', const SettingsScreen()),
        ])
          StatefulShellBranch(routes: [
            GoRoute(path: path, builder: (_, _) => page),
          ]),
      ],
    ),
    GoRoute(
      path: '/new/:type',
      builder: (_, s) => NewGameScreen(type: s.pathParameters['type']!),
    ),
    GoRoute(
      path: '/game/:id',
      builder: (_, s) => GameScreen(gameId: _id(s, 'id')),
      routes: [
        GoRoute(
          path: 'round/:number',
          builder: (_, s) => RoundEntryScreen(
              gameId: _id(s, 'id'), number: _id(s, 'number')),
        ),
      ],
    ),
    GoRoute(path: '/groups/new', builder: (_, _) => const GroupEditScreen()),
    GoRoute(
      path: '/groups/:id',
      builder: (_, s) => GroupEditScreen(groupId: _id(s, 'id')),
    ),
    GoRoute(
      path: '/finished/:id',
      builder: (_, s) => FinishedGameScreen(
        gameId: _id(s, 'id'),
        celebrate: s.uri.queryParameters['celebrate'] == '1',
      ),
    ),
  ],
);

class _NavShell extends StatelessWidget {
  const _NavShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.casino), label: l10n.navGames),
          NavigationDestination(icon: const Icon(Icons.people), label: l10n.navPlayers),
          NavigationDestination(icon: const Icon(Icons.history), label: l10n.navHistory),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: l10n.navStats),
          NavigationDestination(icon: const Icon(Icons.settings), label: l10n.navSettings),
        ],
      ),
    );
  }
}
