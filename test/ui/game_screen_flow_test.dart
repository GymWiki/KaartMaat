import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/ui/quick_button_row.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/ui/counter_panel.dart';
import 'package:kaartmaat/features/games/ui/game_screen.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

/// Keeps the game in memory and pushes every change to the screen, so the
/// whole flow runs synchronously inside the widget test.
class _FakeRepo extends GameRepository {
  _FakeRepo(super.db, this.state);

  GameState state;
  final changes = StreamController<GameState?>.broadcast();

  Stream<GameState?> stream() async* {
    yield state;
    yield* changes.stream;
  }

  void _set(List<RoundData> rounds) {
    state = GameState(
      id: state.id,
      type: state.type,
      createdAt: state.createdAt,
      finishedAt: state.finishedAt,
      settings: state.settings,
      players: state.players,
      rounds: rounds,
    );
    changes.add(state);
  }

  @override
  Future<void> addRound(int gameId, Entries entries) async =>
      _set([...state.rounds, RoundData(number: state.rounds.length + 1, entries: entries)]);

  @override
  Future<void> updateRound(int gameId, int number, Entries entries) async => _set([
        for (final r in state.rounds)
          r.number == number ? RoundData(number: number, entries: entries) : r,
      ]);

  @override
  Future<void> deleteLastRound(int gameId) async =>
      _set(state.rounds.sublist(0, state.rounds.length - 1));
}

class _MemoryDrafts extends DraftStore {
  _MemoryDrafts(super.settings);
  final data = <int, Map<String, Object?>>{};

  @override
  Future<Map<String, Object?>?> load(int gameId) async => data[gameId];

  @override
  Future<void> save(int gameId, Map<String, Object?> draft) async => data[gameId] = draft;

  @override
  Future<void> clear(int gameId) async => data.remove(gameId);
}

GameState newGame({List<RoundData> rounds = const []}) => GameState(
      id: 1,
      type: 'boerenbridge',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const BoerenbridgeRules().defaultSettings,
      players: const [
        PlayerRef(id: 1, name: 'Anna'),
        PlayerRef(id: 2, name: 'Bas'),
        PlayerRef(id: 3, name: 'Chris'),
      ],
      rounds: rounds,
    );

GameState countingGame() => GameState(
      id: 1,
      type: 'custom',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const CustomRules().defaultSettings,
      players: const [
        PlayerRef(id: 1, name: 'Anna'),
        PlayerRef(id: 2, name: 'Bas'),
        PlayerRef(id: 3, name: 'Chris'),
      ],
      rounds: const [],
    );

/// The whole Boerenbridge round on ONE screen: bids, tricks, confirm, undo,
/// and correcting an earlier round.
void main() {
  late AppDatabase db;
  late _FakeRepo repo;
  late _MemoryDrafts drafts;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Finder number(String text) =>
      find.descendant(of: find.byType(QuickButtonRow), matching: find.text(text));

  Future<void> openGame(WidgetTester tester, GameState state) async {
    usePhoneScreen(tester);
    repo = _FakeRepo(db, state);
    drafts = _MemoryDrafts(SettingsRepository(db));
    await pumpApp(
      tester,
      GameScreen(gameId: 1),
      scaffold: false,
      overrides: [
        gameRepositoryProvider.overrideWithValue(repo),
        gameStateProvider.overrideWith((ref, id) => repo.stream()),
        draftStoreProvider.overrideWithValue(drafts),
        prefsProvider.overrideWithValue(const AppPrefs({})),
      ],
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1)); // let the draft timer fire
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('a full round without leaving the screen, then undo', (tester) async {
    await openGame(tester, newGame());

    // Round 1: dealer is Anna, bidding order Bas, Chris, Anna. Table on top,
    // panel at the bottom: one screen.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.textContaining('Deler: Anna'), findsOneWidget);

    await tester.tap(number('1')); // Bas bids 1
    await tester.pump();
    await tester.tap(number('0')); // Chris bids 0
    await tester.pump();
    // Anna (dealer): 0 would make the bids add up to the 1 trick, so it is
    // greyed out and a tap does nothing
    await tester.tap(number('0'), warnIfMissed: false);
    await tester.pump();
    expect(repo.state.rounds, isEmpty);
    await tester.tap(number('1'));
    await tester.pump();

    // The bids were stored as an open round and the panel asks for the tricks.
    expect(repo.state.rounds.length, 1);
    expect(repo.state.rounds.single.entries.values.map((e) => e['tricks']),
        everyElement(isNull));
    expect(find.text('Ronde afronden'), findsOneWidget);

    await tester.tap(number('1')); // Bas wins the trick
    await tester.pump();
    await tester.tap(number('0')); // Chris none; Anna is filled in: 0
    await tester.pump();
    await tester.tap(find.text('Ronde afronden'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final entries = repo.state.rounds.single.entries;
    expect([for (final p in ['1', '2', '3']) entries[p]!['tricks']], [0, 1, 0]);
    expect(find.byType(SnackBar), findsNothing); // undo lives in the round bar
    expect(find.text('+1'), findsOneWidget); // new round: confirmation plays
    // the next round is ready: dealer Bas, and the draft is gone
    expect(find.textContaining('Ronde 2 van'), findsOneWidget);
    expect(find.textContaining('Deler: Bas'), findsOneWidget);
    expect(drafts.data, isEmpty);

    // undo brings the round back to the tricks step, with the tricks as typed
    await tester.pump(const Duration(seconds: 2)); // animation done
    expect(find.text('+1'), findsNothing);
    await tester.tap(find.byTooltip('Ongedaan maken'));
    await tester.pump();
    await tester.pump();
    expect(find.text('+1'), findsNothing); // undo: no particle
    expect(repo.state.rounds.single.entries.values.map((e) => e['tricks']),
        everyElement(isNull));
    expect(find.text('Ronde afronden'), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, 'Ronde afronden');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

    await close(tester);
  });

  testWidgets('tapping an earlier round corrects it in the same panel', (tester) async {
    final done = RoundData(number: 1, entries: {
      '1': {'bid': 0, 'tricks': 0},
      '2': {'bid': 1, 'tricks': 1},
      '3': {'bid': 1, 'tricks': 0},
    });
    await openGame(tester, newGame(rounds: [done]));

    expect(find.textContaining('Deler: Bas'), findsOneWidget); // round 2 is the next one
    await tester.tap(find.text('bod 1 · 1'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Ronde 1 corrigeren'), findsWidgets);
    expect(find.byType(Scaffold), findsOneWidget); // still the same screen

    // fix Bas's bid and save: totals follow
    await tester.tap(number('0')); // first in bidding order for round 1 is Bas
    await tester.pump();
    await tester.tap(find.text('Slagen'));
    await tester.pump();
    expect(find.text('Ronde afronden'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Deler: Bas'), findsOneWidget); // back on the new round
    expect(repo.state.rounds.single.entries['2'], {'bid': 1, 'tricks': 1}); // untouched
    expect(find.text('+1'), findsNothing); // editing/closing: no particle

    await close(tester);
  });

  testWidgets('a half-filled panel is restored when the screen opens again',
      (tester) async {
    await openGame(tester, newGame());
    await tester.tap(number('1')); // Bas bids 1
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // draft timer
    await tester.pump();
    final saved = drafts.data[1]!;
    expect((saved['bids'] as Map)['2'], 1);
    await close(tester);

    // "Restart": new screen, same drafts
    repo = _FakeRepo(db, newGame());
    await pumpApp(
      tester,
      GameScreen(gameId: 1),
      scaffold: false,
      overrides: [
        gameRepositoryProvider.overrideWithValue(repo),
        gameStateProvider.overrideWith((ref, id) => repo.stream()),
        draftStoreProvider.overrideWithValue(drafts),
        prefsProvider.overrideWithValue(const AppPrefs({})),
      ],
    );
    await tester.pump();
    await tester.pump();
    // Bas's bid of 1 is back on the chip, Chris is up next
    expect(find.text('Bas'), findsWidgets);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await close(tester);
  });

  testWidgets('counting live: taps are stored at once, next round, correcting an old one',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await openGame(tester, countingGame());
    Finder tile(String name) => find.descendant(
        of: find.byType(CounterPanel), matching: find.text(name));
    int points(int round, String player) =>
        repo.state.rounds[round - 1].entries[player]!['points'] as int;

    // nothing yet: the first tap creates round 1
    expect(repo.state.rounds, isEmpty);
    await tester.tap(tile('Anna'));
    await tester.pump();
    await tester.tap(tile('Anna'));
    await tester.pump();
    expect(repo.state.rounds.length, 1);
    expect(points(1, '1'), 2);

    // next round: a new empty round, taps now go there
    await tester.tap(find.text('Volgende ronde'));
    await tester.pump();
    await tester.pump();
    expect(repo.state.rounds.length, 2);
    await tester.tap(tile('Bas'));
    await tester.pump();
    expect(points(2, '2'), 1);
    expect(points(1, '2'), 0);

    // tap round 1 in the table: corrected in the same panel, then back
    await tester.tap(find.bySemanticsLabel(RegExp('^Ronde 1, ')));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Ronde 1 corrigeren'), findsWidgets);
    await tester.tap(tile('Anna'));
    await tester.pump();
    expect(points(1, '1'), 3);
    await tester.tap(find.text('Klaar'));
    await tester.pump();
    await tester.pump();
    await tester.tap(tile('Chris'));
    await tester.pump();
    expect(points(2, '3'), 1);

    await close(tester);
    semantics.dispose();
  });
}
