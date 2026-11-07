import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/ui/quick_button_row.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/ui/boerenbridge_panel.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

class _Store extends DraftStore {
  _Store(super.settings);
  final saved = <Map<String, Object?>>[];

  @override
  Future<void> save(int gameId, Map<String, Object?> draft) async => saved.add(draft);
}

/// Records what would be saved, without timers (those would stay pending in a
/// widget test).
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

GameState game(int players, {List<RoundData> rounds = const []}) => GameState(
      id: 1,
      type: 'boerenbridge',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const BoerenbridgeRules().defaultSettings,
      players: [for (var i = 1; i <= players; i++) PlayerRef(id: i, name: 'P$i')],
      rounds: rounds,
    );

RoundData round(int n, List<int> bids, [List<int>? tricks]) => RoundData(number: n, entries: {
      for (var i = 0; i < bids.length; i++)
        '${i + 1}': {'bid': bids[i], if (tricks != null) 'tricks': tricks[i]},
    });

void main() {
  late AppDatabase db;
  late _Store store;
  late _TestSaver saver;
  late List<_Saved> saves;
  var cancelled = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = _Store(SettingsRepository(db));
    saver = _TestSaver(store, 1);
    saves = [];
    cancelled = 0;
  });
  tearDown(() => db.close());

  Future<void> pumpPanel(
    WidgetTester tester, {
    required GameState state,
    required int number,
    Entries? existing,
    bool editing = false,
    Map<String, Object?>? initialDraft,
    bool inScaffold = false,
  }) async {
    usePhoneScreen(tester);
    final panel = BoerenbridgePanel(
      ctx: PanelContext(
        view: GameView(state),
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

  Finder number(String text) => find.descendant(
      of: find.byType(QuickButtonRow), matching: find.text(text));

  group('bidding', () {
    testWidgets('one tap per player, then it moves on to the tricks by itself',
        (tester) async {
      // Round 1, 3 players: dealer is P1, bidding order P2, P3, P1.
      await pumpPanel(tester, state: game(3), number: 1);

      await tester.tap(number('0')); // P2
      await tester.pump();
      await tester.tap(number('0')); // P3
      await tester.pump();

      // The dealer may not bid 1 (0 + 0 + 1 = 1 card): greyed out, not tappable.
      final style = tester.widget<Text>(number('1')).style!;
      expect(style.decoration, TextDecoration.lineThrough);
      await tester.tap(number('1'), warnIfMissed: false);
      await tester.pump();
      expect(saves, isEmpty);

      await tester.tap(number('0')); // dealer bids 0
      await tester.pump();

      // bids stored as an open round, panel now asks for the tricks
      expect(saves.length, 1);
      expect(saves.single.complete, false);
      expect(saves.single.entries['1'], {'bid': 0});
      expect(find.text('Ronde afronden'), findsOneWidget);
    });

    testWidgets('each tap makes the next player the active one', (tester) async {
      await pumpPanel(tester, state: game(4), number: 2); // dealer P2, order P3, P4, P1, P2
      await tester.tap(number('1')); // P3
      await tester.pump();
      await tester.tap(number('0')); // P4
      await tester.pump();
      // chips show what was entered
      expect(find.text('1'), findsWidgets);
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('the dealer sees which bid is forbidden', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPanel(tester, state: game(3), number: 3); // 3 cards, dealer P3
      await tester.tap(number('1')); // P1
      await tester.pump();
      await tester.tap(number('1')); // P2
      await tester.pump();
      // dealer P3 now: 3 cards - 2 = 1 is forbidden
      expect(find.bySemanticsLabel('1, niet toegestaan'), findsOneWidget);
      expect(find.bySemanticsLabel('2'), findsOneWidget);
      handle.dispose();
    });
  });

  group('tricks', () {
    final open = round(1, [0, 1, 1]); // 1 card, bids by P1..P3, dealer P1

    testWidgets('the last player is filled in and one tap confirms', (tester) async {
      await pumpPanel(
          tester, state: game(3, rounds: [open]), number: 1, existing: open.entries);
      expect(find.text('Ronde afronden'), findsOneWidget); // starts on the tricks
      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(number('1')); // P2 (first in order) takes the trick
      await tester.pump();
      await tester.tap(number('0')); // P3
      await tester.pump();
      // order is P2, P3, P1: the dealer P1 gets the rest = 0 automatically

      final confirm = find.widgetWithText(FilledButton, 'Ronde afronden');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
      // the automatic player cannot be changed to something else
      await tester.tap(find.text('P1 · deler'));
      await tester.pump();
      await tester.tap(number('1'), warnIfMissed: false);
      await tester.pump();

      await tester.tap(confirm);
      await tester.pump();
      expect(saves.length, 1);
      expect(saves.single.complete, true);
      expect(saves.single.entries['2'], {'bid': 1, 'tricks': 1});
      expect(saves.single.entries['3'], {'bid': 1, 'tricks': 0});
      expect(saves.single.entries['1'], {'bid': 0, 'tricks': 0});
      expect(saves.single.undoDraft, isNotNull);
    });

    testWidgets('confirm stays off while the tricks do not add up', (tester) async {
      await pumpPanel(
          tester, state: game(3, rounds: [open]), number: 1, existing: open.entries);
      final confirm = find.widgetWithText(FilledButton, 'Ronde afronden');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      expect(find.textContaining('Totaal slagen: 0 van 1'), findsOneWidget);
    });

    testWidgets('a value that would leave too few tricks is greyed out',
        (tester) async {
      final two = round(2, [1, 1, 0]); // 2 cards
      await pumpPanel(tester,
          state: game(3, rounds: [round(1, [1, 0, 0], [1, 0, 0]), two]),
          number: 2,
          existing: two.entries);
      await tester.tap(number('2')); // P3 (order: dealer P2 -> P3, P1, P2) takes 2
      await tester.pump();
      // P1 cannot take anything more than 0 now; 1 and 2 are struck through
      expect(tester.widget<Text>(number('1')).style!.decoration, TextDecoration.lineThrough);
      expect(tester.widget<Text>(number('2')).style!.decoration, TextDecoration.lineThrough);
    });

    testWidgets('the live preview shows the round score before confirming',
        (tester) async {
      await pumpPanel(
          tester, state: game(3, rounds: [open]), number: 1, existing: open.entries);
      await tester.tap(number('1')); // P2: bid 1, took 1 -> exact: 10 + 5
      await tester.pump();
      await tester.tap(number('0')); // P3: bid 1, took 0 -> -5
      await tester.pump();
      // dealer P1 bid 0 and gets 0 -> exact: +10
      expect(find.text('+15'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('-5'), findsOneWidget);
    });
  });

  group('drafts and corrections', () {
    testWidgets('a draft of this round is restored', (tester) async {
      final open = round(1, [0, 1, 1]);
      await pumpPanel(
        tester,
        state: game(3, rounds: [open]),
        number: 1,
        existing: open.entries,
        initialDraft: {
          'round': 1,
          'editing': false,
          'step': 'tricks',
          'bids': {'1': 0, '2': 1, '3': 1},
          'tricks': {'2': 1, '3': 0},
          'focus': 2,
        },
      );
      expect(find.text('Ronde afronden'), findsOneWidget);
      // P3 had 1 trick in the draft, P1 (dealer) gets the rest automatically
      final confirm = find.widgetWithText(FilledButton, 'Ronde afronden');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    });

    testWidgets('a draft of another round is ignored', (tester) async {
      await pumpPanel(
        tester,
        state: game(3),
        number: 1,
        initialDraft: {
          'round': 7,
          'editing': false,
          'step': 'tricks',
          'bids': {'1': 1, '2': 0, '3': 0},
          'tricks': {},
          'focus': 0,
        },
      );
      expect(find.text('Naar slagen'), findsOneWidget); // fresh bidding step
    });

    testWidgets('every change is written to the draft', (tester) async {
      await pumpPanel(tester, state: game(3), number: 1);
      await tester.tap(number('0'));
      await tester.pump();
      expect(saver.scheduled, isNotEmpty);
      expect(saver.scheduled.last['round'], 1);
      expect((saver.scheduled.last['bids'] as Map)['2'], 0);
    });

    testWidgets('correcting a finished round: no jumping, close button leaves',
        (tester) async {
      final done = round(1, [1, 0, 0], [1, 0, 0]);
      await pumpPanel(
        tester,
        state: game(3, rounds: [done]),
        number: 1,
        existing: done.entries,
        editing: true,
      );

      // change the first bid in bidding order: no partial save, no auto jump
      await tester.tap(find.text('Biedingen'));
      await tester.pump();
      await tester.tap(number('1'));
      await tester.pump();
      expect(saves, isEmpty);

      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, 1);
    });
  });

  group('fits the thumb zone', () {
    testWidgets('4 players, 5 cards stays within 45% of the screen', (tester) async {
      await pumpPanel(tester, state: game(4), number: 5, inScaffold: true);
      final total = tester.getSize(find.byType(GameScreenScaffold)).height;
      final panel = tester.getSize(find.byType(AnimatedSize)).height;
      expect(panel, lessThanOrEqualTo(total * 0.5 + 24));
      expect(tester.takeException(), isNull);
    });

    testWidgets('3 players, 17 cards still works (the panel scrolls)', (tester) async {
      await pumpPanel(tester, state: game(3), number: 17, inScaffold: true);
      final total = tester.getSize(find.byType(GameScreenScaffold)).height;
      final panel = tester.getSize(find.byType(AnimatedSize)).height;
      expect(panel, lessThanOrEqualTo(total * 0.5 + 24));
      expect(tester.takeException(), isNull);
      expect(number('17'), findsOneWidget);
    });
  });
}
