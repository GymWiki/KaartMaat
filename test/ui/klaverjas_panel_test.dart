import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/klaverjas_panel.dart';
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

GameState game({List<RoundData> rounds = const []}) => GameState(
      id: 1,
      type: 'klaverjassen',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const KlaverjasRules().defaultSettings,
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

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saver = _TestSaver(DraftStore(SettingsRepository(db)), 1);
    saves = [];
    cancelled = 0;
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
    final panel = KlaverjasPanel(
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

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, d));
      await tester.pump();
    }
  }

  Finder confirm() => find.widgetWithText(FilledButton, 'Opslaan');
  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirm()).onPressed != null;

  testWidgets('points of the playing team, the rest of the 162 fills in itself',
      (tester) async {
    await pumpPanel(tester);
    // round 1: dealer Anna, forehand is Bas, so Zij is preselected
    expect(find.text('Zij speelden'), findsOneWidget);
    expect(find.text('Wij: 0 · Zij: 0'), findsNothing);
    expect(confirmEnabled(tester), false);

    await type(tester, '95');
    expect(find.text('Zij: 95 · Wij: 67'), findsOneWidget);
    expect(find.text('+95'), findsOneWidget); // preview before confirming
    expect(find.text('+67'), findsOneWidget);
    expect(confirmEnabled(tester), true);
  });

  testWidgets('more than 162 cannot be typed', (tester) async {
    await pumpPanel(tester);
    await type(tester, '16');
    await type(tester, '3'); // 163: ignored
    expect(find.text('Zij: 16 · Wij: 146'), findsOneWidget);
    await type(tester, '2');
    expect(find.text('Zij: 162 · Wij: 0'), findsOneWidget);
  });

  testWidgets('switching team keeps the points and swaps who gets what',
      (tester) async {
    await pumpPanel(tester);
    await type(tester, '100');
    await tester.tap(find.text('Wij speelden'));
    await tester.pump();
    expect(find.text('Wij: 100 · Zij: 62'), findsOneWidget);
  });

  testWidgets('nat is recognised from the points and shown before saving',
      (tester) async {
    await pumpPanel(tester);
    await type(tester, '81'); // 81 - 81: tie counts as nat
    expect(find.text('NAT'), findsOneWidget);
    expect(find.text('+162'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    await tester.tap(find.byIcon(Icons.clear)); // clear
    await tester.pump();
    await type(tester, '82');
    expect(find.text('NAT'), findsNothing);
  });

  testWidgets('pit: all tricks, 162 plus the bonus, pad switched off', (tester) async {
    await pumpPanel(tester);
    await tester.tap(find.text('Pit'));
    await tester.pump();
    expect(find.text('PIT'), findsOneWidget);
    expect(find.text('+262'), findsOneWidget);
    expect(confirmEnabled(tester), true);

    await tester.tap(confirm());
    await tester.pump();
    final zij = saves.single.entries['zij']!;
    expect(zij['pit'], true);
    expect(zij['cards'], 162);
    expect(saves.single.entries['wij']!['cards'], 0);
  });

  group('roem', () {
    testWidgets('quick buttons add up per team, long press takes one off',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPanel(tester);
      await tester.tap(find.textContaining('Roem ·'));
      await tester.pump();

      final three = find.bySemanticsLabel(RegExp('^Wij Drie op rij'));
      await tester.tap(three);
      await tester.tap(three);
      await tester.pump();
      expect(find.textContaining('Roem · 40 / 0'), findsOneWidget);

      await tester.longPress(three);
      await tester.pump();
      expect(find.textContaining('Roem · 20 / 0'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp('^Zij Stuk')));
      await tester.pump();
      expect(find.textContaining('Roem · 20 / 20'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('roem is part of the preview and the saved entry', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPanel(tester);
      await type(tester, '90'); // Zij play with 90
      await tester.tap(find.textContaining('Roem ·'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(RegExp('^Zij Stuk'))); // +20
      await tester.tap(find.bySemanticsLabel(RegExp('^Wij Vier gelijke'))); // +100
      await tester.pump();
      // Zij 110 against Wij 72 + 100 = 172: Zij fail, so nat
      expect(find.text('NAT'), findsOneWidget);
      await tester.tap(find.text('Punten'));
      await tester.pump();
      await tester.tap(confirm());
      await tester.pump();
      expect(saves.single.complete, true);
      expect(saves.single.entries['zij']!['stuk'], 1);
      expect(saves.single.entries['wij']!['equal'], 1);
      handle.dispose();
    });
  });

  testWidgets('confirm saves the round in one tap and keeps an undo draft',
      (tester) async {
    await pumpPanel(tester);
    await type(tester, '100');
    await tester.tap(confirm());
    await tester.pump();
    expect(saves.length, 1);
    expect(saves.single.complete, true);
    expect(saves.single.undoDraft, isNotNull);
    expect(saves.single.entries['zij']!['playing'], true);
    expect(saves.single.entries['zij']!['cards'], 100);
    expect(saves.single.entries['wij']!['cards'], 62);
  });

  testWidgets('the team follows the dealer rotation', (tester) async {
    await pumpPanel(tester, number: 2); // dealer Bas, forehand Chris -> Wij
    expect(find.text('Wij speelden'), findsOneWidget);
    expect(find.text('Deler: Bas'), findsOneWidget);
  });

  group('drafts and corrections', () {
    testWidgets('every change is written to the draft', (tester) async {
      await pumpPanel(tester);
      await type(tester, '7');
      expect(saver.scheduled.last['cards'], '7');
      expect(saver.scheduled.last['round'], 1);
    });

    testWidgets('a draft of this round is restored', (tester) async {
      await pumpPanel(tester, initialDraft: {
        'round': 1,
        'editing': false,
        'playing': 'wij',
        'cards': '110',
        'pit': false,
        'page': 'points',
        'roem': {
          'wij': {'three': 1, 'four': 0, 'stuk': 0, 'equal': 0, 'jacks': 0},
          'zij': {'three': 0, 'four': 0, 'stuk': 0, 'equal': 0, 'jacks': 0},
        },
      });
      expect(find.text('Wij: 110 · Zij: 52'), findsOneWidget);
      expect(find.textContaining('Roem · 20 / 0'), findsOneWidget);
    });

    testWidgets('a draft of another round is ignored', (tester) async {
      await pumpPanel(tester, initialDraft: {
        'round': 5,
        'editing': false,
        'playing': 'wij',
        'cards': '110',
      });
      expect(find.text('Zij speelden'), findsOneWidget);
      expect(find.text('Wij: 110 · Zij: 52'), findsNothing);
    });

    testWidgets('correcting a past round loads it and has a close button',
        (tester) async {
      final past = RoundData(number: 1, entries: {
        'wij': {'playing': true, 'pit': false, 'cards': 100, 'stuk': 1},
        'zij': {'playing': false, 'pit': false, 'cards': 62},
      });
      await pumpPanel(
        tester,
        state: game(rounds: [past]),
        existing: past.entries,
        editing: true,
      );
      expect(find.text('Ronde 1 corrigeren'), findsOneWidget);
      expect(find.text('Wij: 100 · Zij: 62'), findsOneWidget);
      expect(find.textContaining('Roem · 20 / 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, 1);
    });
  });

  testWidgets('fits within 45% of the screen', (tester) async {
    await pumpPanel(tester, inScaffold: true);
    final total = tester.getSize(find.byType(GameScreenScaffold)).height;
    final panel = tester.getSize(find.byType(AnimatedSize)).height;
    expect(panel, lessThanOrEqualTo(total * 0.45 + 0.5));
    expect(tester.takeException(), isNull);
    // both pages
    await tester.tap(find.textContaining('Roem ·'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(find.byType(AnimatedSize)).height,
        lessThanOrEqualTo(total * 0.45 + 0.5));
  });
}
