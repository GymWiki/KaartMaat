import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/toepen_rules.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/games/ui/toepen_panel.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

class _TestSaver extends DraftSaver {
  _TestSaver(super.store, super.gameId);
  @override
  void schedule(Map<String, Object?> draft) {}
}

RoundData pts(int n, List<int> points) => RoundData(
  number: n,
  entries: {
    for (var i = 0; i < points.length; i++) '${i + 1}': {'points': points[i]},
  },
);

GameState game({
  List<RoundData> rounds = const [],
  Map<String, Object?> settings = const {},
  int players = 4,
}) => GameState(
  id: 1,
  type: 'toepen',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: null,
  settings: {...const ToepenRules().defaultSettings, ...settings},
  players: [
    for (var i = 0; i < players; i++)
      PlayerRef(id: i + 1, name: ['Anna', 'Bas', 'Chris', 'Dora', 'Eva', 'Femke'][i]),
  ],
  rounds: rounds,
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
    int number = 1,
    bool editing = false,
  }) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      SingleChildScrollView(
        child: ToepenPanel(
          ctx: PanelContext(
            view: GameView(state ?? game()),
            roundNumber: number,
            existing: null,
            editing: editing,
            draft: saver,
            initialDraft: null,
            onSave: (e, {required complete, undoDraft}) async => stored.add(e),
            onCancel: () => cancelled++,
            onNewRound: (e) async => newRounds.add(e),
          ),
        ),
      ),
      overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
    );
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder.first);
    await tester.pump();
  }

  int pointsOf(String player) => stored.last[player]!['points'] as int;

  testWidgets('a tap on a name adds one point and is stored at once', (
    tester,
  ) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Bas'));
    expect(pointsOf('1'), 2);
    expect(pointsOf('2'), 1);
    expect(find.text('2'), findsWidgets); // Anna's total
  });

  testWidgets('the minus button takes a point off, and stops at zero', (
    tester,
  ) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Anna'));
    await tap(tester, find.byIcon(Icons.remove));
    expect(pointsOf('1'), 0);
    final minus = tester.widget<FilledButton>(
      find.widgetWithIcon(FilledButton, Icons.remove).first,
    );
    expect(minus.onPressed, isNull);
  });

  testWidgets('no knock button and no save button: "Volgende ronde" instead', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(find.textContaining('Kloppen'), findsNothing);
    expect(find.text('Opslaan'), findsNothing);
    await tap(tester, find.text('Bas'));
    await tap(tester, find.text('Volgende ronde'));
    expect(newRounds.single, {
      for (final p in ['1', '2', '3', '4']) p: {'points': 0},
    });
  });

  testWidgets('one point short of the limit shows "op pelt"', (tester) async {
    await pumpPanel(
      tester,
      state: game(rounds: [pts(1, [9, 3, 0, 0])]),
      number: 2,
    );
    expect(find.text('op pelt'), findsOneWidget);
    expect(find.text('armoe'), findsNothing);
    expect(find.text('uit'), findsNothing);
  });

  testWidgets('"op pelt" can be switched off in the settings', (tester) async {
    await pumpPanel(
      tester,
      state: game(
        rounds: [pts(1, [9, 3, 0, 0])],
        settings: {ToepenRules.povertyKey: false},
      ),
      number: 2,
    );
    expect(find.text('op pelt'), findsNothing);
  });

  testWidgets('a tap that reaches the limit makes the player "uit" and stops', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      state: game(rounds: [pts(1, [9, 0, 0, 0])]),
      number: 2,
    );
    await tap(tester, find.text('Anna'));
    expect(pointsOf('1'), 1);
    expect(find.text('uit'), findsOneWidget);
    await tap(tester, find.text('Anna'));
    expect(stored.length, 1); // out players collect no more points
  });

  testWidgets('correcting a past round: "Klaar" closes instead of next round', (
    tester,
  ) async {
    await pumpPanel(tester, editing: true);
    expect(find.text('Volgende ronde'), findsNothing);
    await tap(tester, find.text('Klaar'));
    expect(cancelled, 1);
    expect(newRounds, isEmpty);
  });
}
