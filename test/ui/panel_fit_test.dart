import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

/// The real promise of the input panel: everything, including the confirm
/// button, is visible without scrolling inside the panel, on a normal phone
/// (411 x 914 dp, status bar 24, gesture bar 24, app bar 56).
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  GameState state(String type, int players, {List<RoundData> rounds = const []}) {
    final def = definitionFor(type);
    return GameState(
      id: 1,
      type: type,
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: def.rules.defaultSettings,
      players: [
        for (var i = 0; i < players; i++)
          PlayerRef(id: i + 1, name: ['Anna', 'Bas', 'Chris', 'Dora', 'Eva', 'Femke', 'Gijs', 'Hanna'][i]),
      ],
      rounds: rounds,
    );
  }

  // The panels need localizations: reuse pumpApp's delegates through a wrapper.
  Future<void> run(
    WidgetTester tester,
    String label,
    String type,
    int players, {
    int round = 1,
    List<RoundData> rounds = const [],
    Future<void> Function()? afterPump,
  }) async {
    late ({double content, double cap, double scrollable}) m;
    // pumpApp-like wrapper with providers
    usePhoneScreen(tester);
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final def = definitionFor(type);
    final s = state(type, players, rounds: rounds);
    final panel = def.panelBuilder!(PanelContext(
      view: GameView(s),
      roundNumber: round,
      existing: null,
      editing: false,
      draft: DraftSaver(DraftStore(SettingsRepository(db)), 1),
      initialDraft: null,
      onSave: (entries, {required complete, undoDraft}) async {},
      onCancel: () {},
      onNewRound: (entries) async {},
    ));
    await pumpApp(
      tester,
      GameScreenScaffold(top: const SizedBox.expand(), panel: panel),
      scaffold: false,
      overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
    );
    // pumpApp has no app bar: wrap in one by re-pumping inside a Scaffold
    await pumpApp(
      tester,
      Scaffold(
        appBar: AppBar(),
        body: GameScreenScaffold(top: const SizedBox.expand(), panel: panel),
      ),
      scaffold: false,
      overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
    );
    await tester.pump();
    if (afterPump != null) await afterPump();
    final scroll = tester.state<ScrollableState>(find.descendant(
        of: find.byType(GameScreenScaffold), matching: find.byType(Scrollable)).first);
    m = (
      content: tester.getSize(find.byType(AnimatedSize)).height,
      cap: tester.getSize(find.byType(GameScreenScaffold)).height * 0.5,
      scrollable: scroll.position.maxScrollExtent,
    );
    // ignore: avoid_print
    print('FIT $label: panel ${m.content.toStringAsFixed(0)} of ${m.cap.toStringAsFixed(0)} dp, hidden ${m.scrollable.toStringAsFixed(0)}');
    expect(tester.takeException(), isNull, reason: label);
    expect(m.scrollable, lessThanOrEqualTo(0.5), reason: '$label scrolls inside the panel');
  }

  testWidgets('Boerenbridge', (tester) async {
    await run(tester, 'bb 3p 1 card', 'boerenbridge', 3);
    await run(tester, 'bb 4p 7 cards', 'boerenbridge', 4, round: 7);
    await run(tester, 'bb 4p 13 cards', 'boerenbridge', 4, round: 13);
    await run(tester, 'bb 5p 10 cards', 'boerenbridge', 5, round: 10);
    await run(tester, 'bb 7p 7 cards', 'boerenbridge', 7, round: 7);
  });

  testWidgets('Klaverjassen', (tester) async {
    await run(tester, 'kv points', 'klaverjassen', 4);
    await run(tester, 'kv roem', 'klaverjassen', 4, afterPump: () async {
      await tester.tap(find.textContaining('Roem ·'));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  testWidgets('Rikken', (tester) async {
    await run(tester, 'rik contract', 'rikken', 4);
    await run(tester, 'rik result', 'rikken', 4, afterPump: () async {
      await tester.tap(find.text('Misère').first);
      await tester.pump();
      await tester.tap(find.text('Anna').first);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  testWidgets('Hartenjagen', (tester) async {
    await run(tester, 'hearts 4p', 'hartenjagen', 4);
    await run(tester, 'hearts 5p', 'hartenjagen', 5);
  });

  testWidgets('Toepen', (tester) async {
    await run(tester, 'toepen 4p', 'toepen', 4);
    await run(tester, 'toepen 6p', 'toepen', 6);
  });

  testWidgets('Jokeren and Canasta', (tester) async {
    await run(tester, 'jokeren digits', 'jokeren', 4);
    await run(tester, 'jokeren quick', 'jokeren', 4, afterPump: () async {
      await tester.tap(find.text('Snel'));
      await tester.pump(const Duration(milliseconds: 300));
    });
    await run(tester, 'canasta digits', 'canasta', 4);
    await run(tester, 'canasta quick', 'canasta', 4, afterPump: () async {
      await tester.tap(find.text('Snel'));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  testWidgets('Algemene teller', (tester) async {
    await run(tester, 'counter 4p', 'custom', 4);
    await run(tester, 'counter 6p', 'custom', 6);
  });
}
