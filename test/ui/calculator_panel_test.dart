import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/canasta_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/jokeren_rules.dart';
import 'package:kaartmaat/features/games/ui/calculator_entry.dart' show QuickAmount;
import 'package:kaartmaat/features/games/ui/calculator_panel.dart';
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

class _Saved {
  _Saved(this.entries, this.complete, this.undoDraft);
  final Entries entries;
  final bool complete;
  final Map<String, Object?>? undoDraft;
}

GameState jokeren() => GameState(
      id: 1,
      type: 'jokeren',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const JokerenRules().defaultSettings,
      players: const [
        PlayerRef(id: 1, name: 'Anna'),
        PlayerRef(id: 2, name: 'Bas'),
        PlayerRef(id: 3, name: 'Chris'),
      ],
      rounds: const [],
    );

GameState canasta() => GameState(
      id: 1,
      type: 'canasta',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const CanastaRules().defaultSettings,
      players: const [
        PlayerRef(id: 1, name: 'Anna'),
        PlayerRef(id: 2, name: 'Bas'),
        PlayerRef(id: 3, name: 'Chris'),
        PlayerRef(id: 4, name: 'Dora'),
      ],
      rounds: const [],
    );

final _quick = [
  QuickAmount((l) => l.quickJoker, 25),
  QuickAmount((l) => l.quickAce, 11),
  QuickAmount((l) => l.quickFace, 10),
];

final _canastaQuick = [
  QuickAmount((l) => l.quickNaturalCanasta, 500),
  QuickAmount((l) => l.quickMixedCanasta, 300),
  QuickAmount((l) => l.quickGoOut, 100),
  QuickAmount((l) => l.quickGoOutConcealed, 200),
  QuickAmount((l) => l.quickRedThree, 100),
  QuickAmount((l) => l.quickAllRedThrees, 800),
];

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
    List<QuickAmount>? quick,
    Entries? existing,
    bool editing = false,
    Map<String, Object?>? initialDraft,
    bool inScaffold = false,
  }) async {
    usePhoneScreen(tester);
    final panel = CalculatorPanel(
      quick: quick ?? _quick,
      ctx: PanelContext(
        view: GameView(state ?? jokeren()),
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

  Future<void> type(WidgetTester tester, String keys) async {
    for (final k in keys.split('')) {
      await tap(tester, find.widgetWithText(FilledButton, k));
    }
  }

  Finder add() => find.byIcon(Icons.add);
  Finder done() => find.widgetWithText(FilledButton, 'Klaar');
  Finder saveButton() => find.widgetWithText(FilledButton, 'Ronde opslaan');

  testWidgets('a whole round: type, Klaar, next player; the last one saves',
      (tester) async {
    await pumpPanel(tester);
    expect(done(), findsOneWidget);

    await type(tester, '25'); // Anna
    expect(find.text('= 25'), findsOneWidget);
    await tap(tester, done());

    // Bas: two amounts, added with +
    await type(tester, '11');
    await tap(tester, add());
    await type(tester, '14');
    expect(find.text('11 + 14'), findsOneWidget);
    expect(find.text('= 25'), findsOneWidget);
    await tap(tester, done());

    // Chris is the last one: the button saves the round (typed number included)
    expect(saveButton(), findsOneWidget);
    await type(tester, '7');
    await tap(tester, saveButton());

    expect(saves.single.complete, true);
    expect(saves.single.entries['1'], {'amounts': [25]});
    expect(saves.single.entries['2'], {'amounts': [11, 14]});
    expect(saves.single.entries['3'], {'amounts': [7]});
    expect(saves.single.undoDraft, isNotNull);
  });

  testWidgets('negative amounts, and Klaar without typing counts as zero', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.widgetWithText(FilledButton, '±'));
    await type(tester, '15');
    expect(find.text('= −15'), findsOneWidget);
    await tap(tester, add());
    expect(find.text('−15'), findsWidgets);

    await tap(tester, done()); // Anna done with -15
    await tap(tester, done()); // Bas: nothing to add
    await tap(tester, saveButton()); // Chris: nothing either, saves
    expect(saves.single.entries['1'], {'amounts': [-15]});
    expect(saves.single.entries['2'], {'amounts': <int>[]});
    expect(saves.single.entries['3'], {'amounts': <int>[]});
  });

  testWidgets('undo takes back what is typed first, then the last amount',
      (tester) async {
    await pumpPanel(tester);
    await type(tester, '25');
    await tap(tester, add());
    await type(tester, '9');
    expect(find.text('25 + 9'), findsOneWidget);

    await tap(tester, find.byIcon(Icons.undo)); // clears the 9
    expect(find.text('= 25'), findsOneWidget);
    await tap(tester, find.byIcon(Icons.undo)); // removes the 25
    expect(find.text('= 0'), findsOneWidget);
    expect(find.text('Nog geen bedragen'), findsOneWidget);
  });

  testWidgets('quick amounts add in one tap on their own page', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Snel'));
    expect(find.text('+25'), findsOneWidget);
    await tap(tester, find.text('Joker'));
    await tap(tester, find.text('Aas'));
    expect(find.text('25 + 11'), findsOneWidget);
    expect(find.text('= 36'), findsOneWidget);
    await tap(tester, find.text('Cijfers'));
    expect(find.widgetWithText(FilledButton, '7'), findsOneWidget);
  });

  testWidgets('switching player keeps what was typed, and a done player can be edited',
      (tester) async {
    await pumpPanel(tester);
    await type(tester, '30');
    await tap(tester, find.text('Bas')); // the typed 30 is added to Anna
    expect(find.text('30'), findsWidgets);
    await tap(tester, find.text('Anna'));
    expect(find.text('= 30'), findsOneWidget);
    await type(tester, '5');
    await tap(tester, find.text('Bas'));
    await tap(tester, find.text('Anna'));
    expect(find.text('30 + 5'), findsOneWidget);
  });

  group('drafts and corrections', () {
    testWidgets('changes are written to the draft', (tester) async {
      await pumpPanel(tester);
      await type(tester, '4');
      expect(saver.scheduled.last['typed'], '4');
      expect(saver.scheduled.last['round'], 1);
    });

    testWidgets('a draft of this round is restored', (tester) async {
      await pumpPanel(tester, initialDraft: {
        'round': 1,
        'editing': false,
        'amounts': {
          '1': [25, 11],
          '2': <int>[],
          '3': <int>[],
        },
        'done': ['1'],
        'focus': 1,
        'typed': '8',
        'page': 'digits',
      });
      expect(find.text('= 8'), findsOneWidget); // Bas, with 8 typed
      await tap(tester, find.text('Anna'));
      expect(find.text('25 + 11'), findsOneWidget);
    });

    testWidgets('correcting a past round loads all amounts and can be closed',
        (tester) async {
      await pumpPanel(
        tester,
        existing: {
          '1': {'amounts': [10, 5]},
          '2': {'amounts': [3]},
          '3': {'amounts': <int>[]},
        },
        editing: true,
      );
      expect(find.text('Ronde 1 corrigeren'), findsOneWidget);
      expect(find.text('10 + 5'), findsOneWidget);
      expect(saveButton(), findsOneWidget); // everybody is done already
      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, 1);
    });
  });

  testWidgets('Canasta: two teams and six quick amounts fit within 45%', (tester) async {
    await pumpPanel(tester, state: canasta(), quick: _canastaQuick, inScaffold: true);
    final total = tester.getSize(find.byType(GameScreenScaffold)).height;
    double panel() => tester.getSize(find.byType(AnimatedSize)).height;
    expect(panel(), lessThanOrEqualTo(total * 0.45 + 0.5));

    await tester.tap(find.text('Snel'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(panel(), lessThanOrEqualTo(total * 0.45 + 0.5));
    await tester.tap(find.text('Natuurlijke canasta'));
    await tester.pump();
    expect(find.text('= 500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('three players, two digits each: 3 taps per player', (tester) async {
    await pumpPanel(tester);
    for (final amount in ['25', '11', '30']) {
      await type(tester, amount);
      await tap(tester, find.widgetWithText(FilledButton, 'Klaar').evaluate().isNotEmpty ? done() : saveButton());
    }
    expect(saves.length, 1);
    expect(taps, 9); // 2 digits + Klaar per player, the last Klaar saves
  });
}
