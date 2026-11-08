import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/theme/app_theme.dart';
import 'package:kaartmaat/core/ui/wide_digit_pad.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';
import 'package:kaartmaat/features/games/ui/klaverjas_panel.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

class _TestSaver extends DraftSaver {
  _TestSaver(super.store, super.gameId);
  final drafts = <Map<String, Object?>>[];
  @override
  void schedule(Map<String, Object?> draft) => drafts.add(draft);
}

Entry _team({
  bool playing = false,
  required int cards,
  int three = 0,
  int? bid,
  String? bidder,
  String? suit,
}) => {
  'playing': playing,
  'pit': false,
  'cards': cards,
  'three': three,
  'four': 0,
  'stuk': 0,
  'equal': 0,
  'jacks': 0,
  'bid': ?bid,
  'bidder': ?bidder,
  'suit': ?suit,
};

/// Anna, Bas, Chris, Dora at the table: wij = Anna + Chris, zij = Bas + Dora.
/// Round 1: Anna deals, so Bas bids first, then Chris, Dora, Anna.
GameState game({
  List<RoundData> rounds = const [],
  Map<String, Object?> settings = const {},
}) => GameState(
  id: 1,
  type: 'klaverjassen',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: null,
  settings: {
    ...const KlaverjasRules().defaultSettings,
    'variant': 'gronings',
    ...settings,
  },
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
  late List<Entries> saved;
  var cancelled = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saver = _TestSaver(DraftStore(SettingsRepository(db)), 1);
    saved = [];
    cancelled = 0;
  });
  tearDown(() => db.close());

  Future<void> pumpPanel(
    WidgetTester tester, {
    GameState? state,
    int number = 1,
    bool editing = false,
    Entries? existing,
    Map<String, Object?>? draft,
    Size? size,
    double textScale = 1.0,
    bool dark = false,
  }) async {
    usePhoneScreen(tester);
    if (size != null) {
      tester.view.physicalSize = size * 2.625;
    }
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: SingleChildScrollView(
            child: KlaverjasPanel(
              ctx: PanelContext(
                view: GameView(state ?? game()),
                roundNumber: number,
                existing: existing,
                editing: editing,
                draft: saver,
                initialDraft: draft,
                onSave: (e, {required complete, undoDraft}) async =>
                    saved.add(e),
                onCancel: () => cancelled++,
              ),
            ),
          ),
        ),
      ),
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
    );
    await tester.pump();
  }

  Future<void> tapText(
    WidgetTester tester,
    String text, {
    bool last = false,
  }) async {
    final f = find.text(text);
    expect(f, findsWidgets, reason: text);
    await tester.tap(last ? f.last : f.first);
    await tester.pump();
  }

  Future<void> pad(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(
        find.descendant(of: find.byType(WideDigitPad), matching: find.text(d)),
      );
      await tester.pump();
    }
  }

  FilledButton raise(WidgetTester tester, int step) =>
      tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('+$step'),
          matching: find.byType(FilledButton),
        ),
      );

  /// Bas opens at [opening]; Chris raises to [opening] + [step] and wins.
  Future<void> bidChris(
    WidgetTester tester, {
    int opening = 70,
    int step = 20,
  }) async {
    await tapText(tester, '$opening');
    await tapText(tester, 'Chris');
    await tapText(tester, '+$step');
  }

  testWidgets(
    'a Gronings hand starts with the bidding: opening bids 70 to 160',
    (tester) async {
      await pumpPanel(tester);
      for (final b in [70, 100, 160]) {
        expect(find.text('$b'), findsOneWidget, reason: 'opening bid $b');
      }
      expect(find.text('170'), findsNothing);
      expect(
        find.text('+10'),
        findsNothing,
        reason: 'no raises before a first bid',
      );
    },
  );

  testWidgets('invalid raises are greyed out, never an error', (tester) async {
    await pumpPanel(tester, state: game(settings: {'maxBid': 100}));
    await tapText(tester, '90');
    await tapText(tester, 'Chris');
    expect(raise(tester, 10).onPressed, isNotNull); // 100
    expect(raise(tester, 20).onPressed, isNull); // 110 > highest bid
    expect(raise(tester, 30).onPressed, isNull);
  });

  testWidgets('"Bod wissen" takes the last bid back', (tester) async {
    await pumpPanel(tester);
    await bidChris(tester);
    expect(find.text('Chris biedt 90'), findsOneWidget);
    await tapText(tester, 'Bod wissen');
    expect(find.text('Bas biedt 70'), findsOneWidget);
    await tapText(tester, 'Bod wissen');
    expect(find.text('70'), findsOneWidget); // opening bids are back
  });

  testWidgets('everybody passes: the player left of the dealer must bid 70', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(find.text('Bas moet 70 bieden'), findsOneWidget);
    await tapText(tester, 'Iedereen past');
    // straight on to the trump suit, with Bas as bidder at the minimum
    expect(find.text('Harten'), findsOneWidget);
    await tapText(tester, 'Schoppen');
    expect(find.text('Bas · 70'), findsOneWidget);
    await pad(tester, '75');
    await tapText(tester, 'Opslaan');
    final zij = saved.single['zij']!;
    expect(zij['bid'], 70);
    expect(zij['bidder'], '2');
    expect(zij['suit'], 'spades');
    expect(zij['playing'], true);
  });

  testWidgets('the minimum is a setting: the forced bid follows it', (
    tester,
  ) async {
    await pumpPanel(tester, state: game(settings: {'minBid': 80}));
    expect(find.text('Bas moet 80 bieden'), findsOneWidget);
    expect(find.text('70'), findsNothing);
  });

  testWidgets('bid, trump, points: one hand saved with everything in it', (
    tester,
  ) async {
    await pumpPanel(tester);
    await bidChris(tester); // Chris 90
    await tapText(tester, 'Troef kiezen');
    await tapText(tester, 'Harten');
    expect(find.text('Chris · 90'), findsOneWidget);
    await pad(tester, '100');
    // live preview: bid made, points for both teams
    expect(find.text('bod 90 gehaald'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('+62'), findsOneWidget);
    await tapText(tester, 'Opslaan');
    final wij = saved.single['wij']!;
    expect(wij['playing'], true);
    expect(wij['bid'], 90);
    expect(wij['bidder'], '3');
    expect(wij['suit'], 'hearts');
    expect(wij['cards'], 100);
    expect(saved.single['zij']!['cards'], 62);
  });

  testWidgets('a bid that is not made shows nat in the preview: 0 and 162', (
    tester,
  ) async {
    await pumpPanel(tester);
    await bidChris(tester, opening: 100, step: 10); // 110
    await tapText(tester, 'Troef kiezen');
    await tapText(tester, 'Ruiten');
    await pad(tester, '95');
    expect(find.text('bod 110 niet gehaald'), findsOneWidget);
    expect(find.text('NAT'), findsOneWidget);
    expect(find.text('+162'), findsOneWidget);
  });

  testWidgets('roem counts towards the bid in the preview', (tester) async {
    await pumpPanel(tester);
    await bidChris(tester, opening: 100, step: 10); // 110
    await tapText(tester, 'Troef kiezen');
    await tapText(tester, 'Klaveren');
    await pad(tester, '95');
    expect(find.text('bod 110 niet gehaald'), findsOneWidget);
    await tapText(tester, 'Roem · 0 / 0');
    await tester.tap(find.text('+20').first); // three in a row for wij
    await tester.pump();
    await tapText(tester, 'Roem · 20 / 0');
    expect(find.text('bod 110 gehaald'), findsOneWidget); // 95 + 20 = 115
  });

  testWidgets('the suit of the last hand is preselected for the same bidder', (
    tester,
  ) async {
    final earlier = RoundData(
      number: 1,
      entries: {
        'wij': _team(
          playing: true,
          cards: 100,
          bid: 90,
          bidder: '3',
          suit: 'spades',
        ),
        'zij': _team(cards: 62),
      },
    );
    await pumpPanel(tester, state: game(rounds: [earlier]), number: 2);
    // round 2: Bas deals, Chris bids first
    await tapText(tester, '80');
    await tapText(tester, 'Troef kiezen');
    final spades = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Schoppen',
      ),
    );
    expect(spades.properties.selected, isTrue);
    await tapText(tester, 'Volgende'); // keep the preselected suit
    expect(find.text('Chris · 80'), findsOneWidget);
  });

  testWidgets('correcting a hand reopens the result with bid and suit', (
    tester,
  ) async {
    final stored = {
      'wij': _team(
        playing: true,
        cards: 100,
        bid: 90,
        bidder: '3',
        suit: 'hearts',
      ),
      'zij': _team(cards: 62),
    };
    await pumpPanel(
      tester,
      state: game(rounds: [RoundData(number: 1, entries: stored)]),
      editing: true,
      existing: stored,
    );
    expect(find.text('Chris · 90'), findsOneWidget);
    expect(find.text('bod 90 gehaald'), findsOneWidget);
    await tapText(tester, 'Opslaan');
    expect(saved.single['wij']!['bid'], 90);
    // tap the summary to change the bid
    await tapText(tester, 'Chris · 90');
    expect(
      find.text('Iedereen past'),
      findsNothing,
    ); // a bid exists: "Bod wissen"
    expect(find.text('Bod wissen'), findsOneWidget);
  });

  testWidgets('resuming mid-bidding brings the bids back', (tester) async {
    await pumpPanel(
      tester,
      draft: {
        'round': 1,
        'editing': false,
        'step': 0,
        'bids': [
          {'p': '2', 'b': 70},
          {'p': '3', 'b': 100},
        ],
        'bidFocus': '4',
        'suit': null,
        'playing': 'wij',
        'cards': '',
        'pit': false,
        'page': 'points',
      },
    );
    expect(find.text('Chris biedt 100'), findsOneWidget);
  });

  testWidgets('every step is written to the draft', (tester) async {
    await pumpPanel(tester);
    await tapText(tester, '70');
    expect(saver.drafts.last['bids'], [
      {'p': '2', 'b': 70},
    ]);
    await tapText(tester, 'Troef kiezen');
    expect(saver.drafts.last['step'], 1);
    await tapText(tester, 'Harten');
    expect(saver.drafts.last['suit'], 'hearts');
    expect(saver.drafts.last['step'], 2);
  });

  for (final (label, size) in [
    ('360x640', const Size(360, 640)),
    ('411x914', const Size(411, 914)),
  ]) {
    testWidgets('no overflow on $label in any step', (tester) async {
      await pumpPanel(tester, size: size);
      expect(tester.takeException(), isNull);
      await tapText(tester, '70');
      await tapText(tester, 'Chris');
      await tapText(tester, '+10');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Troef kiezen');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Harten');
      await pad(tester, '100');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the other variants never show the bidding step', (tester) async {
    await pumpPanel(tester, state: game(settings: {'variant': 'amsterdams'}));
    expect(find.text('Iedereen past'), findsNothing);
    expect(find.text('Opslaan'), findsOneWidget);
  });

  testWidgets('no overflow with a 200% system font in any step', (
    tester,
  ) async {
    await pumpPanel(tester, size: const Size(411, 914), textScale: 2.0);
    await tapText(tester, '70');
    await tapText(tester, 'Chris');
    await tapText(tester, '+10');
    await tapText(tester, 'Troef kiezen');
    await tapText(tester, 'Harten');
    await pad(tester, '100');
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'accessibility guidelines in every step (${dark ? "dark" : "light"})',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpPanel(tester, dark: dark);
        Future<void> check(String step) async {
          await expectLater(
            tester,
            meetsGuideline(androidTapTargetGuideline),
            reason: step,
          );
          await expectLater(
            tester,
            meetsGuideline(labeledTapTargetGuideline),
            reason: step,
          );
        }

        await check('bidding');
        await tapText(tester, '70');
        await tapText(tester, 'Chris');
        await tapText(tester, '+10');
        await check('raise');
        await tapText(tester, 'Troef kiezen');
        await check('trump');
        await tapText(tester, 'Harten');
        await pad(tester, '100');
        await check('result');
        handle.dispose();
      },
    );
  }
}
