import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/ui/wide_digit_pad.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/ui/counter_panel.dart';
import 'package:kaartmaat/features/games/ui/game_screen.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/games/ui/score_entry_panel.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';
import 'package:kaartmaat/features/settings/ui/settings_editor.dart';

import 'helpers.dart';

class _TestSaver extends DraftSaver {
  _TestSaver(super.store, super.gameId);
  @override
  void schedule(Map<String, Object?> draft) {}
}

class _NoDrafts extends DraftStore {
  _NoDrafts(super.settings);
  @override
  Future<Map<String, Object?>?> load(int gameId) async => null;
  @override
  Future<void> save(int gameId, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(int gameId) async {}
}

GameState game({Map<String, Object?> settings = const {}, int players = 3}) =>
    GameState(
      id: 1,
      type: 'custom',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: settings,
      players: [
        for (var i = 0; i < players; i++)
          PlayerRef(id: i + 1, name: ['Anna', 'Bas', 'Chris', 'Dora'][i]),
      ],
      rounds: const [],
    );

void main() {
  const rules = CustomRules();
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('the method is a setting stored with the game', () {
    test('the default is Optellen, and Invullen is the other choice', () {
      expect(rules.defaultSettings['inputMode'], 'add');
      final spec = rules.settingSpecs.first;
      expect(spec.key, 'inputMode', reason: 'first (top) setting');
      expect(spec.options, ['add', 'enter']);
      expect(spec.segmented, isTrue);
    });

    test('it is saved with the game and comes back after a reload', () async {
      final repo = GameRepository(db);
      final players = PlayerRepository(db);
      final ids = [(await players.add('A')).id!, (await players.add('B')).id!];
      final id = await repo.createGame('custom', ids, {
        ...rules.defaultSettings,
        'inputMode': 'enter',
      });
      final loaded = (await repo.load(id))!;
      expect(loaded.settings['inputMode'], 'enter');
      expect(CustomRules.isEnterMode(loaded.config), isTrue);
    });

    test('games saved before the setting existed count as Optellen', () {
      final old = game(settings: const {'step': 5, 'targetScore': 0});
      expect(CustomRules.isEnterMode(old.config), isFalse);
      expect(definitionFor('custom').isLive(old.config), isTrue);
      final enter = game(settings: const {'inputMode': 'enter'});
      expect(definitionFor('custom').isLive(enter.config), isFalse);
    });

    test('scoring and the end of the game are the same for both methods', () {
      for (final mode in ['add', 'enter']) {
        final c = GameConfig(
          type: 'custom',
          participants: const ['a', 'b'],
          settings: {
            ...rules.defaultSettings,
            'inputMode': mode,
            'targetScore': 10,
          },
        );
        final rounds = [
          RoundData(
            number: 1,
            entries: {
              'a': {'points': 6},
              'b': {'points': -2},
            },
          ),
          RoundData(
            number: 2,
            entries: {
              'a': {'points': 5},
              'b': {'points': 1},
            },
          ),
        ];
        expect(rules.totals(c, rounds), {'a': 11, 'b': -1}, reason: mode);
        expect(rules.isFinished(c, rounds), isTrue, reason: mode);
        expect(rules.winners(c, rounds), ['a'], reason: mode);
      }
    });
  });

  group('settings screen', () {
    Future<void> pumpEditor(WidgetTester tester, Map<String, Object?> values) =>
        pumpApp(
          tester,
          StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: SettingsEditor(
                rules: rules,
                values: values,
                onChanged: (k, v) => setState(() => values[k] = v),
              ),
            ),
          ),
        );

    testWidgets(
      'segmented control on top, Optellen by default, with its hint',
      (tester) async {
        await pumpEditor(tester, {...rules.defaultSettings});
        expect(find.text('Invoermethode'), findsOneWidget);
        expect(find.byType(SegmentedButton<String>), findsOneWidget);
        expect(find.text('Optellen'), findsOneWidget);
        expect(find.text('Invullen'), findsOneWidget);
        expect(
          find.text('Tik op knoppen om punten bij spelers op te tellen.'),
          findsOneWidget,
        );
        // it is the first setting on the screen
        final method = tester.getTopLeft(find.text('Invoermethode')).dy;
        expect(
          tester.getTopLeft(find.text('Doelscore (0 = geen)')).dy,
          greaterThan(method),
        );
      },
    );

    testWidgets(
      'the hint follows the choice; the step setting is hidden for Invullen',
      (tester) async {
        await pumpEditor(tester, {...rules.defaultSettings});
        expect(find.text('Stap van de plus- en min-knoppen'), findsOneWidget);

        await tester.tap(find.text('Invullen'));
        await tester.pump();
        expect(
          find.text(
            'Vul per ronde de score van elke speler in met het numpad.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Tik op knoppen om punten bij spelers op te tellen.'),
          findsNothing,
        );
        // hidden, not greyed out
        expect(find.text('Stap van de plus- en min-knoppen'), findsNothing);
        // target score and "lowest wins" stay for both methods
        expect(find.text('Doelscore (0 = geen)'), findsOneWidget);
        expect(find.text('Laagste score wint'), findsOneWidget);

        await tester.tap(find.text('Optellen'));
        await tester.pump();
        expect(find.text('Stap van de plus- en min-knoppen'), findsOneWidget);
        expect(
          find.text('Tik op knoppen om punten bij spelers op te tellen.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'an old saved game without the setting shows the Optellen settings',
      (tester) async {
        await pumpEditor(tester, {'step': 5, 'targetScore': 0});
        expect(find.text('Stap van de plus- en min-knoppen'), findsOneWidget);
      },
    );
  });

  group('Invullen panel', () {
    late List<Entries> saved;
    setUp(() => saved = []);

    Future<void> pumpPanel(WidgetTester tester, {int players = 3}) async {
      usePhoneScreen(tester);
      final state = game(
        settings: {...rules.defaultSettings, 'inputMode': 'enter'},
        players: players,
      );
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: definitionFor('custom').panelBuilder!(
            PanelContext(
              view: GameView(state),
              roundNumber: 1,
              existing: null,
              editing: false,
              draft: _TestSaver(DraftStore(SettingsRepository(db)), 1),
              initialDraft: null,
              onSave: (e, {required complete, undoDraft}) async => saved.add(e),
              onCancel: () {},
            ),
          ),
        ),
        overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
      );
      await tester.pump();
    }

    Future<void> type(WidgetTester tester, String keys) async {
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

    FilledButton save(WidgetTester tester) => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ronde opslaan'),
    );

    testWidgets('it is the shared score entry, not the Duizenden extras', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(find.byType(ScoreEntryPanel), findsOneWidget);
      expect(find.byType(CounterPanel), findsNothing);
      expect(find.byType(WideDigitPad), findsOneWidget);
      expect(find.text('Volgende'), findsOneWidget);
      await type(tester, '12');
      // no "→ 12" new-total line under the tile
      expect(find.textContaining('→'), findsNothing);
      expect(find.textContaining('doelscore'), findsNothing);
    });

    testWidgets(
      '"Ronde opslaan" only works when every player is filled in; 0 counts',
      (tester) async {
        await pumpPanel(tester);
        expect(save(tester).onPressed, isNull);
        await type(tester, '40');
        await tester.tap(find.text('Volgende'));
        await tester.pump();
        await type(tester, '-5');
        await tester.tap(find.text('Volgende'));
        await tester.pump();
        expect(save(tester).onPressed, isNull, reason: 'Chris is still empty');
        await type(tester, '0'); // 0 counts as filled in
        expect(save(tester).onPressed, isNotNull);
        await tester.tap(find.text('Ronde opslaan'));
        await tester.pump();
        expect(saved.single, {
          '1': {'points': 40},
          '2': {'points': -5},
          '3': {'points': 0},
        });
      },
    );

    testWidgets('a lone minus is not a score yet', (tester) async {
      await pumpPanel(tester, players: 2);
      await type(tester, '5');
      await tester.tap(find.text('Volgende'));
      await tester.pump();
      await type(tester, '-');
      expect(save(tester).onPressed, isNull);
    });

    testWidgets('no overflow with 2 and 4 players', (tester) async {
      await pumpPanel(tester, players: 4);
      expect(tester.takeException(), isNull);
    });
  });

  group('game screen picks the panel from the stored method', () {
    Future<void> open(WidgetTester tester, GameState state) async {
      usePhoneScreen(tester);
      await pumpApp(
        tester,
        const GameScreen(gameId: 1),
        scaffold: false,
        overrides: [
          gameRepositoryProvider.overrideWithValue(GameRepository(db)),
          gameStateProvider.overrideWith((ref, id) => Stream.value(state)),
          draftStoreProvider.overrideWithValue(
            _NoDrafts(SettingsRepository(db)),
          ),
          prefsProvider.overrideWithValue(const AppPrefs({})),
        ],
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Invullen: number pad panel, "Ronde opslaan" per round', (
      tester,
    ) async {
      await open(
        tester,
        game(settings: {...rules.defaultSettings, 'inputMode': 'enter'}),
      );
      expect(find.byType(ScoreEntryPanel), findsOneWidget);
      expect(find.byType(CounterPanel), findsNothing);
      expect(find.text('Ronde opslaan'), findsOneWidget);
      expect(find.text('Volgende ronde'), findsNothing);
    });

    testWidgets('Optellen and old games: the counter panel as before', (
      tester,
    ) async {
      await open(tester, game(settings: {...rules.defaultSettings}));
      expect(find.byType(CounterPanel), findsOneWidget);
      expect(find.byType(ScoreEntryPanel), findsNothing);
      expect(find.text('Volgende ronde'), findsOneWidget);
    });

    testWidgets('a game saved before the setting existed is Optellen', (
      tester,
    ) async {
      await open(
        tester,
        game(settings: const {'step': 1, 'lowestWins': false}),
      );
      expect(find.byType(CounterPanel), findsOneWidget);
    });
  });
}
