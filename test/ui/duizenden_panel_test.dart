import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/ui/wide_digit_pad.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/duizenden_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/ui/duizenden_panel.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

class _TestSaver extends DraftSaver {
  _TestSaver(super.store, super.gameId);
  final drafts = <Map<String, Object?>>[];
  @override
  void schedule(Map<String, Object?> draft) => drafts.add(draft);
}

const _names = [
  'Anna',
  'Bas',
  'Chris',
  'Dora',
  'Eva',
  'Femke',
  'Gijs',
  'Hanna',
];

GameState game({
  List<List<int>> rounds = const [],
  Map<String, Object?> settings = const {},
  int players = 3,
}) => GameState(
  id: 1,
  type: 'duizenden',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: null,
  settings: {...const DuizendenRules().defaultSettings, ...settings},
  players: [
    for (var i = 0; i < players; i++) PlayerRef(id: i + 1, name: _names[i]),
  ],
  rounds: [
    for (var r = 0; r < rounds.length; r++)
      RoundData(
        number: r + 1,
        entries: {
          for (var i = 0; i < players; i++)
            '${i + 1}': {'points': rounds[r][i]},
        },
      ),
  ],
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
  }) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      SingleChildScrollView(
        child: DuizendenPanel(
          ctx: PanelContext(
            view: GameView(state ?? game()),
            roundNumber: number,
            existing: existing,
            editing: editing,
            draft: saver,
            initialDraft: draft,
            onSave: (e, {required complete, undoDraft}) async => saved.add(e),
            onCancel: () => cancelled++,
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

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).first);
    await tester.pump();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Ronde opslaan'),
  );

  testWidgets('"Ronde opslaan" needs a score for everybody; 0 counts', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(saveButton(tester).onPressed, isNull);
    await type(tester, '50');
    await tapText(tester, 'Volgende');
    await type(tester, '0'); // 0 is a value
    await tapText(tester, 'Volgende');
    expect(
      saveButton(tester).onPressed,
      isNull,
      reason: 'Chris is still empty',
    );
    await type(tester, '120');
    expect(saveButton(tester).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Ronde opslaan'));
    await tester.pump();
    expect(saved.single, {
      '1': {'points': 50},
      '2': {'points': 0},
      '3': {'points': 120},
    });
  });

  testWidgets('the sign key makes a negative score, again makes it positive', (
    tester,
  ) async {
    await pumpPanel(tester);
    await type(tester, '-75');
    expect(find.text('-75'), findsOneWidget);
    await type(tester, '-');
    expect(find.text('75'), findsOneWidget);
    await type(tester, '-');
    await tester.tap(
      find.descendant(
        of: find.byType(WideDigitPad),
        matching: find.byIcon(Icons.backspace_outlined),
      ),
    );
    await tester.pump();
    expect(find.text('-7'), findsOneWidget);
  });

  testWidgets('"-0" is stored as 0, never as a lone minus', (tester) async {
    await pumpPanel(tester);
    await type(tester, '-0');
    expect(find.text('0'), findsWidgets);
    expect(find.text('-0'), findsNothing);
    await type(tester, '-');
    // just a minus is not a score yet
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('"Volgende" goes to the next player without a score', (
    tester,
  ) async {
    await pumpPanel(tester);
    await type(tester, '10');
    await tapText(tester, 'Volgende'); // -> Bas
    await type(tester, '20');
    await tester.tap(find.text('Anna').first); // jump back to Anna
    await tester.pump();
    await tapText(tester, 'Volgende'); // Bas is filled: -> Chris
    await type(tester, '30');
    await tapText(tester, 'Volgende'); // everybody filled: moves on in order
    expect(saveButton(tester).onPressed, isNotNull);
    expect(saved, isEmpty);
  });

  testWidgets('"Volgende" waits for a usable value', (tester) async {
    await pumpPanel(tester);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Volgende'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('every chip shows what the total becomes while typing', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      state: game(
        rounds: [
          [300, 120, -40],
        ],
      ),
      number: 2,
    );
    expect(find.text('300'), findsOneWidget); // current totals before typing
    await type(tester, '150');
    expect(find.text('→ 450'), findsOneWidget);
    await tapText(tester, 'Volgende');
    await type(tester, '-');
    await type(tester, '60');
    expect(find.text('→ 60'), findsOneWidget);
  });

  testWidgets('whoever would reach the target is pointed out', (tester) async {
    await pumpPanel(
      tester,
      state: game(
        rounds: [
          [900, 500, 0],
        ],
      ),
      number: 2,
    );
    await type(tester, '100');
    expect(find.text('Anna haalt de doelscore'), findsOneWidget);
    await tapText(tester, 'Volgende');
    await type(tester, '50');
    expect(find.text('Anna haalt de doelscore'), findsOneWidget);
  });

  testWidgets('a score outside the range is blocked with a warning', (
    tester,
  ) async {
    await pumpPanel(tester);
    await type(tester, '-1000');
    expect(find.text('Score buiten -999 tot 9999'), findsOneWidget);
    await tapText(tester, 'Volgende'); // blocked: stays on Anna
    await tester.tap(find.text('Bas').first);
    await tester.pump();
    await type(tester, '1');
    await tapText(tester, 'Volgende');
    await type(tester, '1');
    expect(saveButton(tester).onPressed, isNull);
    // fix Anna's typo: one digit less and -100 is fine
    await tester.tap(find.text('Anna').first);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(WideDigitPad),
        matching: find.byIcon(Icons.backspace_outlined),
      ),
    );
    await tester.pump();
    expect(find.text('Score buiten -999 tot 9999'), findsNothing);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('the range comes from the settings', (tester) async {
    await pumpPanel(
      tester,
      state: game(settings: {'minEntry': -50, 'maxEntry': 200}),
    );
    await type(tester, '201');
    expect(find.text('Score buiten -50 tot 200'), findsOneWidget);
  });

  testWidgets('correcting a round loads its scores and offers to close', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      state: game(
        rounds: [
          [10, -5, 0],
          [20, 20, 20],
        ],
      ),
      number: 1,
      editing: true,
      existing: {
        '1': {'points': 10},
        '2': {'points': -5},
        '3': {'points': 0},
      },
    );
    expect(find.text('Ronde 1 corrigeren'), findsOneWidget);
    expect(find.text('-5'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
    // the preview leaves the corrected round out of the base totals
    expect(find.text('→ 30'), findsOneWidget); // 20 (round 2) + 10
    await tester.tap(find.byTooltip('Annuleren'));
    expect(cancelled, 1);
  });

  testWidgets('a half-filled panel comes back from its draft', (tester) async {
    await pumpPanel(
      tester,
      draft: {
        'round': 1,
        'editing': false,
        'values': {'1': '45', '2': '-3', '3': ''},
        'focus': 2,
      },
    );
    expect(find.text('45'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
    await type(tester, '9');
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('a draft of another round is ignored', (tester) async {
    await pumpPanel(
      tester,
      draft: {
        'round': 7,
        'editing': false,
        'values': {'1': '45', '2': '-3', '3': '5'},
      },
    );
    expect(find.text('45'), findsNothing);
  });

  testWidgets('every change is written to the draft', (tester) async {
    await pumpPanel(tester);
    await type(tester, '12');
    expect(saver.drafts.last['values'], {'1': '12', '2': '', '3': ''});
    await tapText(tester, 'Volgende');
    expect(saver.drafts.last['focus'], 1);
  });

  for (final n in [2, 8]) {
    testWidgets('$n players fit without overflow', (tester) async {
      await pumpPanel(tester, state: game(players: n));
      for (var i = 0; i < n; i++) {
        await type(tester, '${i + 1}');
        await tapText(tester, 'Volgende');
      }
      expect(tester.takeException(), isNull);
      expect(saveButton(tester).onPressed, isNotNull);
    });
  }
}
