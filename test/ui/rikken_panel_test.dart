import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/rikken_rules.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/games/ui/rikken_panel.dart';
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

GameState game({List<RoundData> rounds = const []}) => GameState(
      id: 1,
      type: 'rikken',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const RikkenRules().defaultSettings,
      players: const [
        PlayerRef(id: 1, name: 'Anna'),
        PlayerRef(id: 2, name: 'Bas'),
        PlayerRef(id: 3, name: 'Chris'),
        PlayerRef(id: 4, name: 'Dora'),
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
    int number = 1,
    GameState? state,
    Entries? existing,
    bool editing = false,
    Map<String, Object?>? initialDraft,
    bool inScaffold = false,
  }) async {
    usePhoneScreen(tester);
    final panel = RikkenPanel(
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

  Finder grid(String semanticLabel) => find.bySemanticsLabel(semanticLabel);
  Finder confirm() => find.widgetWithText(FilledButton, 'Opslaan');
  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirm()).onPressed != null;

  testWidgets('rik with a partner in four taps, zero-sum visible before saving',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester);
    expect(confirmEnabled(tester), false);

    await tap(tester, grid('Rik (met maat)')); // 1: contract
    await tap(tester, find.text('Anna')); // 2: bidder
    await tap(tester, find.text('Bas')); // 3: partner
    // made with the 8 tricks it needs: nothing more to enter
    expect(confirmEnabled(tester), true);
    expect(find.text('+10'), findsNWidgets(2));
    expect(find.text('-10'), findsNWidgets(2));
    expect(find.text('Som van alle spelers: 0'), findsOneWidget);

    await tap(tester, confirm()); // 4: confirm
    expect(taps, 4);
    expect(saves.single.complete, true);
    expect(saves.single.entries['1'], {'role': 'bidder', 'contract': 'rik', 'tricks': 8});
    expect(saves.single.entries['2']!['role'], 'partner');
    expect(saves.single.entries['3']!['role'], 'opp');
    handle.dispose();
  });

  testWidgets('a solo contract needs no partner: three taps', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Misère')); // contract
    await tap(tester, find.text('Chris')); // bidder, straight to the result
    expect(find.text('Overslagen'), findsNothing); // exact contract: no stepper
    expect(find.textContaining('Precies 0 slagen'), findsOneWidget);
    expect(find.text('+75'), findsOneWidget);
    expect(find.text('-25'), findsNWidgets(3));
    await tap(tester, confirm());
    expect(taps, 3);
    expect(saves.single.entries['3']!['role'], 'bidder');
  });

  testWidgets('not made: undertricks start at 1 and can be stepped', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester);
    await tap(tester, grid('Rik (met maat)'));
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Bas'));
    await tap(tester, find.text('Niet gehaald').last);

    expect(find.text('Onderslagen'), findsOneWidget);
    // 1 undertrick: stake 10 + 5 = 15, the bidder pays both opponents
    expect(find.text('-30'), findsOneWidget);
    expect(find.text('+15'), findsNWidgets(2));
    expect(find.text('Som van alle spelers: 0'), findsOneWidget);

    await tap(tester, find.byIcon(Icons.add)); // 2 undertricks: stake 20
    expect(find.text('-40'), findsOneWidget);
    await tap(tester, find.byIcon(Icons.remove));
    await tap(tester, find.byIcon(Icons.remove)); // cannot go below 1
    expect(find.text('-30'), findsOneWidget);

    await tap(tester, confirm());
    expect(saves.single.entries['1']!['tricks'], 7);
    handle.dispose();
  });

  testWidgets('overtricks raise the stake', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester);
    await tap(tester, grid('Rik (met maat)'));
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Bas'));
    await tap(tester, find.byIcon(Icons.add));
    await tap(tester, find.byIcon(Icons.add)); // 10 tricks
    expect(find.text('+20'), findsNWidgets(2));
    await tap(tester, confirm());
    expect(saves.single.entries['1']!['tricks'], 10);
    handle.dispose();
  });

  testWidgets('the previous contract is preselected: bidder and confirm only',
      (tester) async {
    final previous = RoundData(number: 1, entries: {
      'p': {'role': 'x'},
    });
    // a real earlier round: Anna played piek
    final first = RoundData(number: 1, entries: {
      '1': {'role': 'bidder', 'contract': 'piek', 'tricks': 1},
      '2': {'role': 'opp', 'contract': 'piek', 'tricks': 1},
      '3': {'role': 'opp', 'contract': 'piek', 'tricks': 1},
      '4': {'role': 'opp', 'contract': 'piek', 'tricks': 1},
    });
    expect(previous.number, 1);
    await pumpPanel(tester, number: 2, state: game(rounds: [first]));
    // contract crumb shows Piek and we are asked for the bidder right away
    expect(find.text('Piek'), findsOneWidget);
    await tap(tester, find.text('Bas'));
    await tap(tester, confirm());
    expect(taps, 2);
    expect(saves.single.entries['2'], {'role': 'bidder', 'contract': 'piek', 'tricks': 1});
  });

  testWidgets('crumbs jump back; changing to a solo contract drops the partner',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPanel(tester);
    await tap(tester, grid('Rik (met maat)'));
    await tap(tester, find.text('Anna'));
    await tap(tester, find.text('Bas'));
    expect(find.text('maat Bas'), findsOneWidget);

    await tap(tester, find.text('Rik')); // crumb: back to the contracts
    await tap(tester, find.text('Piek'));
    expect(find.text('maat Bas'), findsNothing);
    expect(find.text('Uitslag'), findsNothing); // result already complete: no partner needed
    expect(confirmEnabled(tester), true);
    handle.dispose();
  });

  testWidgets('confirm stays off until the choices are complete', (tester) async {
    await pumpPanel(tester);
    await tap(tester, find.text('Piek'));
    expect(confirmEnabled(tester), false); // no bidder yet
    expect(find.text('Kies wie er biedt'), findsOneWidget);
    await tap(tester, find.text('Anna'));
    expect(confirmEnabled(tester), true);
  });

  group('drafts and corrections', () {
    testWidgets('changes are written to the draft', (tester) async {
      await pumpPanel(tester);
      await tap(tester, find.text('Piek'));
      await tap(tester, find.text('Dora'));
      expect(saver.scheduled.last['contract'], 'piek');
      expect(saver.scheduled.last['bidder'], '4');
      expect(saver.scheduled.last['round'], 1);
    });

    testWidgets('a draft of this round is restored', (tester) async {
      await pumpPanel(tester, initialDraft: {
        'round': 1,
        'editing': false,
        'step': 'result',
        'contract': 'alone9',
        'bidder': '3',
        'partner': null,
        'success': false,
        'diff': 2,
      });
      expect(find.text('Onderslagen'), findsOneWidget);
      expect(confirmEnabled(tester), true);
      // 9 alone failed by 2: 20 + 10 = 30 per opponent
      expect(find.text('-90'), findsOneWidget);
    });

    testWidgets('correcting a past round loads it', (tester) async {
      final past = RoundData(number: 1, entries: {
        '1': {'role': 'bidder', 'contract': 'rik', 'tricks': 6},
        '2': {'role': 'partner', 'contract': 'rik', 'tricks': 6},
        '3': {'role': 'opp', 'contract': 'rik', 'tricks': 6},
        '4': {'role': 'opp', 'contract': 'rik', 'tricks': 6},
      });
      await pumpPanel(
        tester,
        state: game(rounds: [past]),
        existing: past.entries,
        editing: true,
      );
      expect(find.text('Ronde 1 corrigeren'), findsOneWidget);
      expect(find.text('Onderslagen'), findsOneWidget);
      expect(find.text('maat Bas'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, 1);
    });
  });

  testWidgets('every step fits within 45% of the screen', (tester) async {
    await pumpPanel(tester, inScaffold: true);
    final total = tester.getSize(find.byType(GameScreenScaffold)).height;
    double panel() => tester.getSize(find.byType(AnimatedSize)).height;
    expect(panel(), lessThanOrEqualTo(total * 0.45 + 0.5)); // contract grid

    await tester.tap(find.text('Piek').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(panel(), lessThanOrEqualTo(total * 0.45 + 0.5)); // bidder
    await tester.tap(find.text('Anna').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(panel(), lessThanOrEqualTo(total * 0.45 + 0.5)); // result
    expect(tester.takeException(), isNull);
  });
}
