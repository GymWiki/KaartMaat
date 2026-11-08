import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/l10n/gen/app_localizations.dart';
import 'package:kaartmaat/core/router/startup.dart';
import 'package:kaartmaat/core/theme/app_theme.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/ui/game_screen.dart';
import 'package:kaartmaat/features/history/finished_game_screen.dart';
import 'package:kaartmaat/features/history/share_result_card.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../helpers.dart';

/// In-memory game, pushed to the screens like the real database stream.
class _FakeRepo extends GameRepository {
  _FakeRepo(super.db, this.state);

  GameState state;
  final changes = StreamController<GameState?>.broadcast();
  int finishCalls = 0;
  int reopenCalls = 0;

  Stream<GameState?> stream() async* {
    yield state;
    yield* changes.stream;
  }

  void _set({
    List<RoundData>? rounds,
    DateTime? finishedAt,
    bool clear = false,
  }) {
    state = GameState(
      id: state.id,
      type: state.type,
      createdAt: state.createdAt,
      finishedAt: clear ? null : (finishedAt ?? state.finishedAt),
      settings: state.settings,
      players: state.players,
      rounds: rounds ?? state.rounds,
    );
    changes.add(state);
  }

  @override
  Future<void> addRound(int gameId, Entries entries) async => _set(
    rounds: [
      ...state.rounds,
      RoundData(number: state.rounds.length + 1, entries: entries),
    ],
  );

  @override
  Future<Entries?> upsertRound(int gameId, int number, Entries entries) async {
    final previous = state.rounds
        .where((r) => r.number == number)
        .firstOrNull
        ?.entries;
    if (previous == null) {
      await addRound(gameId, entries);
    } else {
      await updateRound(gameId, number, entries);
    }
    return previous;
  }

  @override
  Future<void> updateRound(int gameId, int number, Entries entries) async =>
      _set(
        rounds: [
          for (final r in state.rounds)
            r.number == number
                ? RoundData(number: number, entries: entries)
                : r,
        ],
      );

  @override
  Future<bool> finish(int gameId) async {
    finishCalls++;
    if (state.isFinished) return false;
    _set(finishedAt: DateTime(2026, 5, 2));
    return true;
  }

  @override
  Future<void> reopen(int gameId) async {
    reopenCalls++;
    _set(clear: true);
  }

  @override
  Future<GameState?> load(int id) async => state;
}

class _MemoryDrafts extends DraftStore {
  _MemoryDrafts(super.settings);
  @override
  Future<Map<String, Object?>?> load(int gameId) async => null;
  @override
  Future<void> save(int gameId, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(int gameId) async {}
}

class _MemorySettings extends SettingsRepository {
  _MemorySettings(super.db);
  final values = <String, String>{};
  @override
  Future<void> set(String key, String value) async => values[key] = value;
  @override
  Future<String?> get(String key) async => values[key];
  @override
  Future<void> remove(String key) async => values.remove(key);
}

GameState customGame({
  Map<String, Object?> settings = const {},
  List<List<int>> rounds = const [],
  DateTime? finishedAt,
  int players = 3,
}) => GameState(
  id: 1,
  type: 'custom',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: finishedAt,
  settings: {...const CustomRules().defaultSettings, ...settings},
  players: [
    for (var i = 0; i < players; i++)
      PlayerRef(
        id: i + 1,
        name: [
          'Anna',
          'Bas',
          'Chris',
          'Dora',
          'Eva',
          'Femke',
          'Gijs',
          'Hanna',
        ][i],
        avatar: i,
      ),
  ],
  rounds: [
    for (var r = 0; r < rounds.length; r++)
      RoundData(
        number: r + 1,
        entries: {
          for (var i = 0; i < players; i++)
            '${i + 1}': {'points': rounds[r][i]},
        },
      ),
  ],
);

void main() {
  late AppDatabase db;
  late _FakeRepo repo;
  late _MemorySettings settings;
  late List<String> visited;

  setUpAll(() => initializeDateFormatting('nl'));
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    visited = [];
  });
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester,
    GameState state, {
    required String start,
    bool reduceMotion = false,
  }) async {
    usePhoneScreen(tester);
    repo = _FakeRepo(db, state);
    settings = _MemorySettings(db);
    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('HOME')),
        GoRoute(
          path: '/new/:type',
          builder: (_, s) {
            visited.add(s.uri.toString());
            return const Text('NEW');
          },
        ),
        GoRoute(
          path: '/game/:id',
          builder: (_, s) =>
              GameScreen(gameId: 1, key: ValueKey(s.uri.toString())),
        ),
        GoRoute(
          path: '/finished/:id',
          builder: (_, s) {
            visited.add(s.uri.toString());
            return FinishedGameScreen(
              gameId: 1,
              celebrate: s.uri.queryParameters['celebrate'] == '1',
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repo),
          gameStateProvider.overrideWith((ref, id) => repo.stream()),
          draftStoreProvider.overrideWithValue(
            _MemoryDrafts(SettingsRepository(db)),
          ),
          settingsRepositoryProvider.overrideWithValue(settings),
          prefsProvider.overrideWithValue(const AppPrefs({'haptics': '0'})),
        ],
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light(),
            locale: const Locale('nl'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('a game that ends by itself', () {
    testWidgets('goes to the result exactly once, and finishes the game', (
      tester,
    ) async {
      await open(
        tester,
        customGame(settings: {'targetScore': 3}),
        start: '/game/1',
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Anna').last);
        await tester.pump();
        await tester.pump();
      }
      expect(visited, isEmpty, reason: 'target 3 not reached yet');
      await tester.tap(find.text('Anna').last);
      await settle(tester);
      expect(visited, ['/finished/1?celebrate=1']);
      expect(repo.finishCalls, 1);
      expect(repo.state.isFinished, isTrue);
      expect(find.byType(ShareResultCard), findsOneWidget);
      await settle(tester);
      expect(visited.length, 1, reason: 'never navigates twice');
    });

    testWidgets(
      'opening a game that is already over does not jump to the result',
      (tester) async {
        await open(
          tester,
          customGame(
            settings: {'targetScore': 3},
            rounds: [
              [5, 0, 0],
            ],
          ),
          start: '/game/1',
        );
        await settle(tester);
        expect(visited, isEmpty);
        expect(repo.finishCalls, 0);
        expect(find.text('Spel afgelopen'), findsWidgets);
      },
    );

    testWidgets('finishing by hand: one confirmation, one navigation', (
      tester,
    ) async {
      await open(
        tester,
        customGame(
          rounds: [
            [2, 1, 0],
          ],
        ),
        start: '/game/1',
      );
      await tester.tap(find.byType(PopupMenuButton<String>));
      await settle(tester);
      await tester.tap(find.text('Spel afronden'));
      await settle(tester);
      expect(find.textContaining('afronden en bewaren'), findsOneWidget);
      await tester.tap(find.text('Spel afronden').last);
      await settle(tester);
      expect(visited, ['/finished/1?celebrate=1']);
      expect(repo.finishCalls, 1);
    });
  });

  group('result screen', () {
    GameState done({List<List<int>>? rounds, int players = 3}) => customGame(
      rounds:
          rounds ??
          [
            [30, 12, 3],
          ],
      players: players,
      finishedAt: DateTime(2026, 5, 2),
    );

    testWidgets('shows the winner and the final points on the share card', (
      tester,
    ) async {
      await open(tester, done(), start: '/finished/1');
      await settle(tester);
      expect(find.byType(ShareResultCard), findsOneWidget);
      expect(find.text('30'), findsNWidgets(2));
      expect(find.text('Anna'), findsNWidgets(2));
      for (final t in [
        'Delen',
        'Opslaan als afbeelding',
        'Nieuw spel',
        'Hervat spel',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tie is shown as shared win', (tester) async {
      await open(
        tester,
        done(
          rounds: [
            [30, 30, 3],
          ],
        ),
        start: '/finished/1',
      );
      await settle(tester);
      expect(find.text('Gedeelde winst'), findsOneWidget);
    });

    testWidgets('2 and 8 players fit without overflow', (tester) async {
      await open(
        tester,
        done(
          rounds: [
            [5, 4],
          ],
          players: 2,
        ),
        start: '/finished/1',
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
      await open(
        tester,
        done(
          rounds: [
            [8, 7, 6, 5, 4, 3, 2, 1],
          ],
          players: 8,
        ),
        start: '/finished/1',
      );
      await settle(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('right after the end the crown settles with an animation', (
      tester,
    ) async {
      await open(tester, done(), start: '/finished/1?celebrate=1');
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      await settle(tester);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a visit from History does not celebrate', (tester) async {
      await open(tester, done(), start: '/finished/1');
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduce motion: no animation at all', (tester) async {
      await open(
        tester,
        done(),
        start: '/finished/1?celebrate=1',
        reduceMotion: true,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('"Hervat spel" reopens the game after one confirmation', (
      tester,
    ) async {
      await open(tester, done(), start: '/finished/1');
      await tester.tap(find.text('Hervat spel'));
      await settle(tester);
      expect(find.textContaining('weer openen'), findsOneWidget);
      await tester.tap(find.text('Hervat spel').last);
      await settle(tester);
      expect(repo.reopenCalls, 1);
      expect(repo.state.isFinished, isFalse);
      // back in the game, and an over game does not bounce back to the result
      expect(visited, ['/finished/1']);
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('"Nieuw spel" opens the new game screen for the same game', (
      tester,
    ) async {
      await open(tester, done(), start: '/finished/1');
      await tester.tap(find.text('Nieuw spel'));
      await settle(tester);
      expect(visited.last, '/new/custom');
    });

    testWidgets('close goes home', (tester) async {
      await open(tester, done(), start: '/finished/1');
      await tester.tap(find.byTooltip('Sluiten'));
      await settle(tester);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('remembers the open result screen, and forgets it on leaving', (
      tester,
    ) async {
      await open(tester, done(), start: '/finished/1');
      expect(settings.values[lastResultKey], '1');
      await tester.tap(find.byTooltip('Sluiten'));
      await settle(tester);
      expect(settings.values.containsKey(lastResultKey), isFalse);
    });
  });

  group('restart on the result screen', () {
    test('a killed app reopens the finished game it was showing', () async {
      final settings = SettingsRepository(db);
      final games = GameRepository(db);
      final id = await games.createGame('custom', [], {});
      await games.finish(id);
      await settings.set(lastResultKey, '$id');
      expect(await resultLocationToRestore(settings, games), '/finished/$id');
    });

    test(
      'nothing to restore, a resumed game or a deleted game: normal start',
      () async {
        final settings = SettingsRepository(db);
        final games = GameRepository(db);
        expect(await resultLocationToRestore(settings, games), isNull);
        final id = await games.createGame('custom', [], {});
        await settings.set(lastResultKey, '$id'); // game is not finished
        expect(await resultLocationToRestore(settings, games), isNull);
        expect(
          await settings.get(lastResultKey),
          isNull,
          reason: 'stale marker cleared',
        );
        await settings.set(lastResultKey, '999'); // deleted game
        expect(await resultLocationToRestore(settings, games), isNull);
        await settings.set(lastResultKey, 'x');
        expect(await resultLocationToRestore(settings, games), isNull);
      },
    );
  });
}
