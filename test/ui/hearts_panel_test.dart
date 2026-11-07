import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/ui/player_selector.dart';
import 'package:kaartmaat/core/ui/quick_button_row.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/hearts_rules.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/hearts_panel.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
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

GameState game({int players = 4, Map<String, Object?> settings = const {}}) => GameState(
      id: 1,
      type: 'hartenjagen',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: {...const HeartsRules().defaultSettings, ...settings},
      players: [
        for (var i = 0; i < players; i++) PlayerRef(id: i + 1, name: ['Anna', 'Bas', 'Chris', 'Dora', 'Eva', 'Femke'][i]),
      ],
      rounds: const [],
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
    Entries? existing,
    bool editing = false,
    Map<String, Object?>? initialDraft,
    bool inScaffold = false,
  }) async {
    usePhoneScreen(tester);
    final panel = HeartsPanel(
      ctx: PanelContext(
        view: GameView(state ?? game()),
        roundNumber: 1,
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

  Finder hearts(int n) =>
      find.descendant(of: find.byType(QuickButtonRow), matching: find.text('$n'));
  Finder chipValue(String text) =>
      find.descendant(of: find.byType(PlayerSelector), matching: find.text(text));
  Finder confirm() => find.widgetWithText(FilledButton, 'Opslaan');
  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirm()).onPressed != null;

  testWidgets('the last player is filled in: three taps and a confirm', (tester) async {
    await pumpPanel(tester);
    expect(confirmEnabled(tester), false);

    await tap(tester, hearts(3)); // Anna
    await tap(tester, hearts(2)); // Bas
    await tap(tester, hearts(1)); // Chris
    // Dora (last) gets the other 7 hearts and, by default, the queen
    expect(chipValue('20'), findsOneWidget);
    expect(find.text('Verdeeld: 26 van 26'), findsOneWidget);
    expect(confirmEnabled(tester), true);

    await tap(tester, confirm());
    expect(taps, 4);
    final e = saves.single.entries;
    expect([for (final p in ['1', '2', '3', '4']) e[p]!['points']], [3, 2, 1, 20]);
    expect(e['4']!['queen'], true);
    expect(saves.single.complete, true);
  });

  testWidgets('the queen goes to whoever is selected, only one at a time',
      (tester) async {
    await pumpPanel(tester);
    await tap(tester, hearts(3)); // Anna
    await tap(tester, hearts(2)); // Bas
    await tap(tester, hearts(1)); // Chris

    await tap(tester, find.textContaining('Bas')); // select Bas
    await tap(tester, find.text('Schoppen Vrouw +13'));
    expect(chipValue('15'), findsOneWidget); // 2 hearts + 13
    expect(chipValue('7'), findsOneWidget); // Dora without the queen

    await tap(tester, find.textContaining('Chris'));
    await tap(tester, find.text('Schoppen Vrouw +13'));
    expect(chipValue('14'), findsOneWidget); // Chris: 1 + 13
    expect(chipValue('2'), findsOneWidget); // Bas lost it
    await tap(tester, confirm());
    expect(saves.single.entries['3']!['queen'], true);
    expect(saves.single.entries['2']!['queen'], false);
  });

  testWidgets('hearts that are no longer left are greyed out', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester);
    await tap(tester, hearts(10)); // Anna takes 10, 3 are left
    // Bas can take 0..3 only
    expect(find.bySemanticsLabel('4, niet toegestaan'), findsOneWidget);
    expect(find.bySemanticsLabel('13, niet toegestaan'), findsOneWidget);
    expect(find.bySemanticsLabel('3, niet toegestaan'), findsNothing);
    handle.dispose();
  });

  testWidgets('the last seat cannot be typed over', (tester) async {
    await pumpPanel(tester);
    await tap(tester, hearts(1));
    await tap(tester, hearts(1));
    await tap(tester, hearts(1));
    await tap(tester, find.textContaining('Dora'));
    final before = saver.scheduled.length;
    await tester.tap(hearts(5), warnIfMissed: false);
    await tester.pump();
    expect(saver.scheduled.length, before); // nothing changed
    expect(chipValue('23'), findsOneWidget); // 10 hearts + queen
  });

  group('de maan schieten', () {
    testWidgets('one tap: shooter 0, the others get the round total', (tester) async {
      await pumpPanel(tester);
      await tap(tester, find.textContaining('Chris'));
      await tap(tester, find.text('Maan'));
      expect(chipValue('26'), findsNWidgets(3));
      expect(chipValue('0'), findsOneWidget);
      expect(find.text('De maan is geschoten'), findsOneWidget);
      expect(confirmEnabled(tester), true);

      await tap(tester, confirm());
      expect(taps, 3);
      expect(saves.single.entries['3']!['moon'], true);
      expect(saves.single.entries['3']!['points'], 0);
      expect(saves.single.entries['1']!['points'], 26);
    });

    testWidgets('tapping Maan again undoes it', (tester) async {
      await pumpPanel(tester);
      await tap(tester, find.text('Maan'));
      await tap(tester, find.text('Maan'));
      expect(confirmEnabled(tester), false);
      expect(find.text('De maan is geschoten'), findsNothing);
    });

    testWidgets('the other mode: shooter gets minus the total', (tester) async {
      await pumpPanel(tester, state: game(settings: {'moonMode': 'shooter'}));
      await tap(tester, find.text('Maan'));
      expect(chipValue('-26'), findsOneWidget);
    });

    testWidgets('no Maan button when the moon is switched off', (tester) async {
      await pumpPanel(tester, state: game(settings: {'moonEnabled': false}));
      expect(find.text('Maan'), findsNothing);
    });
  });

  group('drafts and corrections', () {
    testWidgets('changes are written to the draft', (tester) async {
      await pumpPanel(tester);
      await tap(tester, hearts(4));
      expect(saver.scheduled.last['round'], 1);
      expect((saver.scheduled.last['hearts'] as Map)['1'], 4);
    });

    testWidgets('a draft of this round is restored', (tester) async {
      await pumpPanel(tester, initialDraft: {
        'round': 1,
        'editing': false,
        'hearts': {'1': 5, '2': 4, '3': 0, '4': null},
        'queen': '2',
        'moon': null,
        'focus': 2,
      });
      expect(chipValue('17'), findsOneWidget); // Bas 4 + queen
      expect(chipValue('4'), findsOneWidget); // Dora: the 4 hearts left
      expect(confirmEnabled(tester), true);
    });

    testWidgets('correcting a past round loads hearts and queen', (tester) async {
      await pumpPanel(
        tester,
        existing: {
          '1': {'points': 3, 'moon': false, 'queen': false},
          '2': {'points': 15, 'moon': false, 'queen': true},
          '3': {'points': 1, 'moon': false, 'queen': false},
          '4': {'points': 7, 'moon': false, 'queen': false},
        },
        editing: true,
      );
      expect(chipValue('15'), findsOneWidget);
      expect(confirmEnabled(tester), true);
      expect(find.text('Ronde 1 corrigeren'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, 1);
    });
  });

  testWidgets('4 players fit within 45% of the screen', (tester) async {
    await pumpPanel(tester, inScaffold: true);
    final total = tester.getSize(find.byType(GameScreenScaffold)).height;
    expect(tester.getSize(find.byType(AnimatedSize)).height,
        lessThanOrEqualTo(total * 0.5 + 24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('6 players still work (the panel may scroll)', (tester) async {
    await pumpPanel(tester, state: game(players: 6), inScaffold: true);
    expect(tester.takeException(), isNull);
    await tester.tap(hearts(2).first);
    await tester.pump();
  });
}
