import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/toepen_rules.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/games/ui/toepen_panel.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

class _TestSaver extends DraftSaver {
  _TestSaver(super.store, super.gameId);
  final scheduled = <Map<String, Object?>>[];

  @override
  void schedule(Map<String, Object?> draft) => scheduled.add(draft);
}

class _Saved {
  _Saved(this.entries, this.complete, this.undoDraft);
  final Entries entries;
  final bool complete;
  final Map<String, Object?>? undoDraft;
}

RoundData won(int n, String winner) => RoundData(number: n, entries: {
      for (var i = 1; i <= 4; i++) '$i': {'winner': '$i' == winner, 'knocks': 0},
    });

GameState game({
  List<RoundData> rounds = const [],
  Map<String, Object?> settings = const {},
  int players = 4,
}) =>
    GameState(
      id: 1,
      type: 'toepen',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: {...const ToepenRules().defaultSettings, ...settings},
      players: [
        for (var i = 0; i < players; i++)
          PlayerRef(id: i + 1, name: ['Anna', 'Bas', 'Chris', 'Dora', 'Eva', 'Femke', 'Gijs', 'Hanna'][i]),
      ],
      rounds: rounds,
    );

void main() {
  late AppDatabase db;
  late _TestSaver saver;
  late List<_Saved> saves;
  var cancelled = 0;
  var taps = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saver = _TestSaver(DraftStore(SettingsRepository(db)), 1);
    saves = [];
    cancelled = 0;
    taps = 0;
  });
  tearDown(() => db.close());

  Future<void> pumpPanel(
    WidgetTester tester, {
    GameState? state,
    int number = 1,
    Entries? existing,
    bool editing = false,
    Map<String, Object?>? initialDraft,
    bool inScaffold = false,
  }) async {
    usePhoneScreen(tester);
    final panel = ToepenPanel(
      ctx: PanelContext(
        view: GameView(state ?? game()),
        roundNumber: number,
        existing: existing,
        editing: editing,
        draft: saver,
        initialDraft: initialDraft,
        onSave: (entries, {required complete, undoDraft}) async =>
            saves.add(_Saved(entries, complete, undoDraft)),
        onCancel: () => cancelled++,
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
    taps++;
    await tester.tap(finder.first);
    await tester.pump();
  }

  Finder confirm() => find.widgetWithText(FilledButton, 'Opslaan');
  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirm()).onPressed != null;

  testWidgets('a plain round: tap the winner, confirm', (tester) async {
    await pumpPanel(tester);
    expect(find.text('Inzet: 1'), findsOneWidget);
    expect(confirmEnabled(tester), false);
    expect(find.text('Tik op de winnaar van de ronde'), findsOneWidget);

    await tap(tester, find.text('Anna'));
    expect(confirmEnabled(tester), true);
    expect(find.text('+1'), findsNWidgets(3)); // the losers see their points now

    await tap(tester, confirm());
    expect(taps, 2);
    final e = saves.single.entries;
    expect(e['1']!['winner'], true);
    expect(e['2']!['winner'], false);
    expect(e['2']!.containsKey('foldAt'), false);
    expect(saves.single.complete, true);
  });

  testWidgets('Kloppen raises the stake; someone who folds pays the knock they folded at',
      (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Kloppen'));
    expect(find.text('Inzet: 2'), findsOneWidget);

    await tap(tester, find.text('Past').at(1)); // Bas folds at knock 1
    await tap(tester, find.text('Kloppen'));
    expect(find.text('Inzet: 3'), findsOneWidget);
    await tap(tester, find.text('Past').at(2)); // Chris folds at knock 2
    await tap(tester, find.text('Anna')); // Anna wins
    // Bas +1, Chris +2, Dora (stayed in) +3
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);

    await tap(tester, confirm());
    final e = saves.single.entries;
    expect(e['2']!['foldAt'], 1);
    expect(e['3']!['foldAt'], 2);
    expect(e['4']!.containsKey('foldAt'), false);
    expect(e['1']!['knocks'], 2);
  });

  testWidgets('a fold can be taken back, and fewer knocks drop folds beyond them',
      (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Kloppen'));
    await tap(tester, find.text('Kloppen'));
    await tap(tester, find.text('Past').at(1)); // Bas folds at knock 2
    await tap(tester, find.text('Anna'));
    expect(find.text('+2'), findsOneWidget);

    await tap(tester, find.byIcon(Icons.remove)); // one knock less: the fold at 2 is gone
    expect(find.text('Inzet: 2'), findsOneWidget);
    expect(find.text('+2'), findsNWidgets(3));

    await tap(tester, find.text('Past').at(0)); // Bas folds at 1 now
    await tap(tester, find.text('Past').at(0)); // and takes it back
    expect(find.text('+2'), findsNWidgets(3));
  });

  testWidgets('poverty is marked and counts as a knock', (tester) async {
    final state = game(
      settings: {'limit': 4},
      rounds: [won(1, '1'), won(2, '1'), won(3, '1')], // Bas, Chris, Dora on 3
    );
    await pumpPanel(tester, state: state, number: 4);
    expect(find.text('armoe'), findsNWidgets(3));
    expect(find.text('Inzet: 2'), findsOneWidget); // the poverty knock is knock 1
    expect(find.text('Past'), findsNWidgets(4)); // folding at it is possible

    await tap(tester, find.text('Anna'));
    // stayers pay 2 and reach 5: over the limit, shown in the tile
    expect(find.text('3 → 5'), findsNWidgets(3));
  });

  testWidgets('players who are out cannot win and are marked', (tester) async {
    final state = game(
      settings: {'limit': 2, 'poverty': false},
      rounds: [won(1, '1'), won(2, '1')], // Bas, Chris, Dora are out
    );
    await pumpPanel(tester, state: state, number: 3);
    expect(find.text('uit'), findsNWidgets(3));
    await tester.tap(find.text('Bas'), warnIfMissed: false);
    await tester.pump();
    expect(confirmEnabled(tester), false);
    await tap(tester, find.text('Anna'));
    expect(confirmEnabled(tester), true);
  });

  group('drafts and corrections', () {
    testWidgets('changes are written to the draft', (tester) async {
      await pumpPanel(tester);
      await tap(tester, find.text('Chris'));
      expect(saver.scheduled.last['winner'], '3');
      expect(saver.scheduled.last['round'], 1);
    });

    testWidgets('a draft of this round is restored', (tester) async {
      await pumpPanel(tester, initialDraft: {
        'round': 1,
        'editing': false,
        'winner': '2',
        'knocks': 1,
        'fold': {'3': 1},
      });
      expect(find.text('Inzet: 2'), findsOneWidget);
      expect(confirmEnabled(tester), true);
      expect(find.text('+1'), findsOneWidget); // Chris folded at knock 1
    });

    testWidgets('correcting a past round loads it and can be closed', (tester) async {
      final past = RoundData(number: 1, entries: {
        '1': {'winner': false, 'knocks': 1, 'foldAt': 1},
        '2': {'winner': true, 'knocks': 1},
        '3': {'winner': false, 'knocks': 1},
        '4': {'winner': false, 'knocks': 1},
      });
      await pumpPanel(
        tester,
        state: game(rounds: [past]),
        existing: past.entries,
        editing: true,
      );
      expect(find.text('Inzet: 2'), findsOneWidget);
      expect(confirmEnabled(tester), true);
      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, 1);
    });
  });

  testWidgets('4 players fit within 45% of the screen; 8 still work', (tester) async {
    await pumpPanel(tester, inScaffold: true);
    final total = tester.getSize(find.byType(GameScreenScaffold)).height;
    expect(tester.getSize(find.byType(AnimatedSize)).height,
        lessThanOrEqualTo(total * 0.5 + 24));
    expect(tester.takeException(), isNull);

    await pumpPanel(tester, state: game(players: 8), inScaffold: true);
    expect(tester.takeException(), isNull);
  });
}
