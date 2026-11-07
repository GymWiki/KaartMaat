import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/custom_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/ui/counter_panel.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

class _TestSaver extends DraftSaver {
  _TestSaver(super.store, super.gameId);
  final scheduled = <Map<String, Object?>>[];

  @override
  void schedule(Map<String, Object?> draft) => scheduled.add(draft);
}

GameState game({int players = 3, Map<String, Object?> settings = const {}}) => GameState(
      id: 1,
      type: 'custom',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: {...const CustomRules().defaultSettings, ...settings},
      players: [
        for (var i = 0; i < players; i++)
          PlayerRef(id: i + 1, name: ['Anna', 'Bas', 'Chris', 'Dora', 'Eva', 'Femke', 'Gijs', 'Hanna'][i]),
      ],
      rounds: const [],
    );

void main() {
  late AppDatabase db;
  late _TestSaver saver;
  late List<Entries> stored;
  late List<Entries> newRounds;
  var cancelled = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saver = _TestSaver(DraftStore(SettingsRepository(db)), 1);
    stored = [];
    newRounds = [];
    cancelled = 0;
  });
  tearDown(() => db.close());

  Future<void> pumpPanel(
    WidgetTester tester, {
    GameState? state,
    Entries? existing,
    bool editing = false,
    Map<String, Object?>? initialDraft,
    bool inScaffold = false,
  }) async {
    usePhoneScreen(tester);
    final panel = CounterPanel(
      ctx: PanelContext(
        view: GameView(state ?? game()),
        roundNumber: 1,
        existing: existing,
        editing: editing,
        draft: saver,
        initialDraft: initialDraft,
        onSave: (entries, {required complete, undoDraft}) async => stored.add(entries),
        onCancel: () => cancelled++,
        onNewRound: (entries) async => newRounds.add(entries),
      ),
    );
    await pumpApp(
      tester,
      inScaffold
          ? GameScreenScaffold(top: const SizedBox.expand(), panel: panel)
          : SingleChildScrollView(child: panel),
      overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
    );
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder.first);
    await tester.pump();
  }

  int pointsOf(String player) => stored.last[player]!['points'] as int;

  testWidgets('a tap adds the step and is stored at once', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Anna'));
    expect(pointsOf('1'), 1);
    expect(stored.length, 1);
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Bas'));
    expect(pointsOf('1'), 2);
    expect(pointsOf('2'), 1);
    expect(find.text('2'), findsWidgets); // Anna's total on her tile
  });

  testWidgets('long press and the minus button take the step off', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Anna'));
    await tester.longPress(find.text('Anna').first);
    await tester.pump();
    expect(pointsOf('1'), 1);
    await tap(tester, find.byIcon(Icons.remove).first);
    expect(pointsOf('1'), 0);
    await tap(tester, find.byIcon(Icons.remove).first);
    expect(pointsOf('1'), -1); // negative totals are fine
  });

  testWidgets('the step is chosen with quick buttons', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('+10'));
    await tap(tester, find.text('Bas'));
    await tap(tester, find.text('+5'));
    await tap(tester, find.text('Bas'));
    expect(pointsOf('2'), 15);
    await tap(tester, find.byIcon(Icons.remove).at(1));
    expect(pointsOf('2'), 10);
  });

  testWidgets('a custom step is typed once', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Eigen'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text('Opslaan'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('+25'), findsOneWidget); // the chip now shows the value
    await tap(tester, find.text('Chris'));
    expect(pointsOf('3'), 25);
  });

  testWidgets('the game setting is the starting step, a draft remembers a change',
      (tester) async {
    await pumpPanel(tester, state: game(settings: {'step': 5}));
    await tap(tester, find.text('Anna'));
    expect(pointsOf('1'), 5);

    await pumpPanel(tester, initialDraft: {'round': 9, 'editing': false, 'step': 10});
    await tap(tester, find.text('Anna'));
    expect(pointsOf('1'), 10); // remembered although it was another round
  });

  testWidgets('undo walks back through the taps in this panel', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Bas'));
    await tap(tester, find.text('Anna'));
    await tap(tester, find.byIcon(Icons.undo));
    expect(pointsOf('1'), 1);
    await tap(tester, find.byIcon(Icons.undo));
    expect(pointsOf('2'), 0);
    await tap(tester, find.byIcon(Icons.undo));
    expect(pointsOf('1'), 0);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
  });

  testWidgets('"Volgende ronde" starts a new, empty round', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Volgende ronde'));
    expect(newRounds.single, {
      '1': {'points': 0},
      '2': {'points': 0},
      '3': {'points': 0},
    });
  });

  testWidgets('correcting a past round: loaded, closable, no next round', (tester) async {
    await pumpPanel(
      tester,
      existing: {
        '1': {'points': 12},
        '2': {'points': 3},
        '3': {'points': 0},
      },
      editing: true,
    );
    expect(find.text('Ronde 1 corrigeren'), findsOneWidget);
    expect(find.text('deze ronde +12'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Volgende ronde')).onPressed,
      isNull,
    );
    await tap(tester, find.text('Bas'));
    expect(pointsOf('2'), 4);
    await tester.tap(find.byIcon(Icons.close));
    expect(cancelled, 1);
  });

  testWidgets('4 players fit within 45% of the screen; 8 still work', (tester) async {
    await pumpPanel(tester, state: game(players: 4), inScaffold: true);
    final total = tester.getSize(find.byType(GameScreenScaffold)).height;
    expect(tester.getSize(find.byType(AnimatedSize)).height,
        lessThanOrEqualTo(total * 0.45 + 0.5));
    expect(tester.takeException(), isNull);
    await pumpPanel(tester, state: game(players: 8), inScaffold: true);
    expect(tester.takeException(), isNull);
  });
}
