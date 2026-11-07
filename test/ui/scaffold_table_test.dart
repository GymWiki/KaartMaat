import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/round_table.dart';

import '../helpers.dart';

const _topKey = Key('top');
const _panelKey = Key('panel');

Widget _scaffold({double panelHeight = 200, Widget? panel, bool withPanel = true}) =>
    GameScreenScaffold(
      top: Container(key: _topKey, color: Colors.green),
      panel: withPanel
          ? (panel ?? SizedBox(key: _panelKey, height: panelHeight, width: double.infinity))
          : null,
    );

void main() {
  group('GameScreenScaffold', () {
    testWidgets('a small panel keeps its own height', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(tester, _scaffold(panelHeight: 200));
      expect(tester.getSize(find.byKey(_panelKey)).height, 200);
    });

    testWidgets('a tall panel is capped at 50% and the top keeps 50%', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(tester, _scaffold(panelHeight: 900));
      final total = tester.getSize(find.byType(GameScreenScaffold)).height;
      final topHeight = tester.getSize(find.byKey(_topKey)).height;

      expect(topHeight, greaterThanOrEqualTo(total * 0.5 - 1));
      // the panel itself scrolls, nothing overflows
      expect(tester.takeException(), isNull);
      expect(find.descendant(
          of: find.byType(GameScreenScaffold), matching: find.byType(SingleChildScrollView)),
          findsOneWidget);
    });

    testWidgets('the cap follows the space left when a keyboard is open',
        (tester) async {
      usePhoneScreen(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 800); // ~305 dp
      addTearDown(tester.view.resetViewInsets);
      await pumpApp(tester, _scaffold(panelHeight: 900));

      final total = tester.getSize(find.byType(GameScreenScaffold)).height;
      expect(total, lessThan(914 * 0.75)); // body shrank
      final topHeight = tester.getSize(find.byKey(_topKey)).height;
      expect(topHeight, greaterThanOrEqualTo(total * 0.5 - 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a panel the top fills everything', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(tester, _scaffold(withPanel: false));
      expect(tester.getSize(find.byKey(_topKey)).height,
          tester.getSize(find.byType(GameScreenScaffold)).height);
      expect(GameScreenScaffold.panelInsetOf(tester.element(find.byKey(_topKey))), 0);
    });

    testWidgets('reports how much room the panel covers', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(tester, _scaffold(panelHeight: 240));
      await tester.pump();
      final inset = GameScreenScaffold.panelInsetOf(tester.element(find.byKey(_topKey)));
      expect(inset, greaterThanOrEqualTo(240));
      expect(inset, lessThan(240 + 60)); // plus padding and safe area
    });
  });

  group('RoundTable', () {
    GameView view(List<List<int>> rounds) => GameView(customGame(rounds));

    testWidgets('shows names, running totals and every round', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(
        tester,
        SizedBox(
          height: 400,
          child: RoundTable(view: view(const [[10, 5, 0], [20, 5, 15]])),
        ),
      );
      expect(find.text('P1'), findsOneWidget);
      expect(find.text('30'), findsWidgets); // total of P1, also its round 2? 20 + 10
      expect(find.text('Totaal'), findsWidgets);
      expect(find.text('10'), findsWidgets);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('tapping a row reports the round for editing', (tester) async {
      usePhoneScreen(tester);
      int? tapped;
      await pumpApp(
        tester,
        SizedBox(
          height: 400,
          child: RoundTable(
            view: view(const [[1, 2, 3], [4, 5, 6]]),
            onTapRound: (n) => tapped = n,
          ),
        ),
      );
      await tester.tap(find.text('4'));
      expect(tapped, 2);
    });

    testWidgets('the current round gets a placeholder row; editing is marked',
        (tester) async {
      usePhoneScreen(tester);
      final handle = tester.ensureSemantics();
      int? tapped;
      await pumpApp(
        tester,
        SizedBox(
          height: 400,
          child: RoundTable(
            view: view(const [[1, 2, 3]]),
            currentRound: 2,
            editingRound: 1,
            onTapRound: (n) => tapped = n,
          ),
        ),
      );
      expect(find.text('2'), findsWidgets); // round number 2 placeholder (and a score)
      expect(find.bySemanticsLabel(RegExp('Ronde 1, wordt bewerkt')), findsOneWidget);
      await tester.tap(find.text('–').first);
      expect(tapped, 2);
      handle.dispose();
    });

    testWidgets('highlighted cells carry a check and details show', (tester) async {
      usePhoneScreen(tester);
      await pumpApp(
        tester,
        SizedBox(
          height: 400,
          child: RoundTable(
            view: view(const [[10, 5, 0]]),
            cellHighlight: (round, p) => p == '1',
            cellDetail: (round, p) => p == '1' ? 'bod 2 · 2' : null,
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('bod 2 · 2'), findsOneWidget);
    });

    testWidgets('eight players fit without sideways scrolling', (tester) async {
      usePhoneScreen(tester);
      final g = GameView(customGame([
        for (var r = 0; r < 3; r++) [for (var i = 0; i < 8; i++) 100 * (r + 1) + i],
      ], players: 8));
      await pumpApp(tester, SizedBox(height: 500, child: RoundTable(view: g)));
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('P8')).right, lessThanOrEqualTo(411));
    });
  });
}
