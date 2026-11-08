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
import 'package:kaartmaat/core/ui/wide_digit_pad.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/rules/duizenden_rules.dart';
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
  _MemoryDrafts(super.settings, [Map<int, Map<String, Object?>>? data])
    : data = data ?? {};
  final Map<int, Map<String, Object?>> data;
  @override
  Future<Map<String, Object?>?> load(int gameId) async => data[gameId];
  @override
  Future<void> save(int gameId, Map<String, Object?> draft) async =>
      data[gameId] = draft;
  @override
  Future<void> clear(int gameId) async => data.remove(gameId);
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

GameState duizendenGame({
  Map<String, Object?> settings = const {},
  List<List<int>> rounds = const [],
  int players = 3,
}) => GameState(
  id: 1,
  type: 'duizenden',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: null,
  settings: {...const DuizendenRules().defaultSettings, ...settings},
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
    Map<int, Map<String, Object?>>? drafts,
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
            _MemoryDrafts(SettingsRepository(db), drafts),
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

  group('Duizenden on the game screen', () {
    Future<void> typeScore(WidgetTester tester, String keys) async {
      for (final k in keys.split('')) {
        await tester.tap(
          find.descendant(
            of: find.byType(WideDigitPad),
            matching: find.text(k == '-' ? '±' : k),
          ),
        );
        await tester.pump();
      }
    }

    Future<void> enterRound(WidgetTester tester, List<String> scores) async {
      for (var i = 0; i < scores.length; i++) {
        await typeScore(tester, scores[i]);
        if (i < scores.length - 1) {
          await tester.tap(find.text('Volgende'));
          await tester.pump();
        }
      }
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Ronde opslaan'));
      await settle(tester);
    }

    testWidgets('one tap saves the round, clears the panel and plays +1 once', (
      tester,
    ) async {
      await open(tester, duizendenGame(), start: '/game/1');
      await enterRound(tester, ['120', '-30', '0']);
      await tester.tap(find.text('Ronde opslaan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.state.rounds.length, 1);
      expect(repo.state.rounds.single.entries['2'], {'points': -30});
      expect(find.text('+1'), findsOneWidget);
      await settle(tester);
      expect(find.text('+1'), findsNothing);
      // the panel is empty again and the save button is off
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Ronde opslaan'),
            )
            .onPressed,
        isNull,
      );
      expect(visited, isEmpty);
    });

    testWidgets('correcting an earlier round does not play +1 again', (
      tester,
    ) async {
      await open(
        tester,
        duizendenGame(
          rounds: [
            [10, 20, 30],
            [5, 5, 5],
          ],
        ),
        start: '/game/1',
      );
      await tester.tap(find.text('10').first); // tap round 1 in the table
      await settle(tester);
      expect(find.text('Ronde 1 corrigeren'), findsWidgets);
      await tester.tap(find.text('Ronde opslaan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('+1'), findsNothing);
      expect(repo.state.rounds.length, 2);
    });

    testWidgets('reaching the target ends the game once and opens the result', (
      tester,
    ) async {
      await open(
        tester,
        duizendenGame(
          settings: {'targetScore': 100},
          rounds: [
            [60, 40, 10],
          ],
        ),
        start: '/game/1',
      );
      await enterRound(tester, ['50', '10', '5']); // Anna 110
      await save(tester);
      expect(visited, ['/finished/1?celebrate=1']);
      expect(repo.finishCalls, 1);
      expect(repo.state.isFinished, isTrue);
      await settle(tester);
      expect(visited.length, 1);
    });

    testWidgets(
      'two players past the target: the game ends with the highest total',
      (tester) async {
        await open(
          tester,
          duizendenGame(
            settings: {'targetScore': 100},
            rounds: [
              [90, 95, 0],
            ],
          ),
          start: '/game/1',
        );
        await enterRound(tester, ['15', '20', '0']); // 105 and 115
        await save(tester);
        expect(visited, ['/finished/1?celebrate=1']);
        expect(find.text('Bas'), findsWidgets);
        expect(find.text('115'), findsWidgets);
      },
    );

    testWidgets('a round that stays below the target does not end the game', (
      tester,
    ) async {
      await open(
        tester,
        duizendenGame(
          settings: {'targetScore': 100},
          rounds: [
            [10, 10, 10],
          ],
        ),
        start: '/game/1',
      );
      await enterRound(tester, ['80', '-5', '0']);
      await save(tester);
      expect(visited, isEmpty);
      expect(repo.state.isFinished, isFalse);
    });

    testWidgets('half-filled scores survive the app being killed', (
      tester,
    ) async {
      final drafts = <int, Map<String, Object?>>{};
      await open(tester, duizendenGame(), start: '/game/1', drafts: drafts);
      await enterRound(tester, ['45', '-3']);
      await tester.pump(const Duration(seconds: 1)); // the draft timer fires
      expect(drafts[1], isNotNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      await open(tester, duizendenGame(), start: '/game/1', drafts: drafts);
      await settle(tester);
      expect(find.text('45'), findsWidgets);
      expect(find.text('-3'), findsWidgets);
    });

    testWidgets(
      'an edit that moves the total below the target ends the "over" state',
      (tester) async {
        await open(
          tester,
          duizendenGame(
            settings: {'targetScore': 100},
            rounds: [
              [60, 0, 0],
              [50, 0, 0],
            ],
          ),
          start: '/game/1',
        );
        expect(find.text('Spel afgelopen'), findsWidgets); // Anna 110
        await tester.tap(find.text('60').first); // correct round 1
        await settle(tester);
        for (var i = 0; i < 2; i++) {
          await tester.tap(
            find.descendant(
              of: find.byType(WideDigitPad),
              matching: find.byIcon(Icons.backspace_outlined),
            ),
          );
          await tester.pump();
        }
        await typeScore(tester, '10'); // Anna: 10 + 50 = 60
        await tester.tap(find.text('Ronde opslaan'));
        await settle(tester);
        expect(repo.state.rounds.first.entries['1'], {'points': 10});
        expect(find.text('Spel afgelopen'), findsNothing);
        expect(visited, isEmpty, reason: 'an edit never jumps to the result');
      },
    );
  });
}
