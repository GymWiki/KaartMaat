import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/ui/live_score_preview.dart';
import 'package:kaartmaat/core/ui/player_selector.dart';
import 'package:kaartmaat/core/ui/touch.dart';

import '../helpers.dart';

void main() {
  group('PlayerSelector.nextUnfilled', () {
    test('moves to the next player without a value, wrapping around', () {
      expect(PlayerSelector.nextUnfilled([true, false, false], 0), 1);
      expect(PlayerSelector.nextUnfilled([true, false, false], 1), 2);
      expect(PlayerSelector.nextUnfilled([false, false, true], 1), 0);
    });

    test('skips players that are filled or derived', () {
      expect(PlayerSelector.nextUnfilled([true, true, false, true], 0), 2);
    });

    test('is null when everybody is filled in', () {
      expect(PlayerSelector.nextUnfilled([true, true, true], 1), isNull);
    });
  });

  group('PlayerSelector', () {
    testWidgets('shows values and a check, selects on tap, big targets',
        (tester) async {
      usePhoneScreen(tester);
      int? picked;
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: PlayerSelector(
            chips: const [
              PlayerChipData(label: 'Anna', value: '3', done: true),
              PlayerChipData(label: 'Bas'),
              PlayerChipData(label: 'Chris'),
              PlayerChipData(label: 'Dora'),
              PlayerChipData(label: 'Eva'),
            ],
            selectedIndex: 1,
            onSelected: (i) => picked = i,
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);

      await tester.tap(find.text('Chris'));
      expect(picked, 2);

      // 5 players wrap onto a second row: Eva sits below Anna
      expect(tester.getTopLeft(find.text('Eva')).dy,
          greaterThan(tester.getTopLeft(find.text('Anna')).dy));
      final height = tester.getSize(find.ancestor(
          of: find.text('Anna'), matching: find.byType(SizedBox)).first).height;
      expect(height, greaterThanOrEqualTo(kTouchTarget));
    });
  });

  group('LiveScorePreview', () {
    testWidgets('shows signed points per player and badges', (tester) async {
      await pumpApp(
        tester,
        const LiveScorePreview(
          scores: [PreviewScore('Wij', 142), PreviewScore('Zij', 0), PreviewScore('X', -15)],
          badges: ['NAT'],
        ),
      );
      expect(find.text('+142'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('-15'), findsOneWidget); // sign, not only color
      expect(find.text('NAT'), findsOneWidget);
    });

    testWidgets('shows the zero-sum check', (tester) async {
      await pumpApp(
        tester,
        const LiveScorePreview(scores: [PreviewScore('A', 10), PreviewScore('B', -10)], sum: 0),
      );
      expect(find.text('Som van alle spelers: 0'), findsOneWidget);
    });

    testWidgets('a message replaces the scores', (tester) async {
      await pumpApp(
        tester,
        const LiveScorePreview(
          scores: [PreviewScore('A', 10)],
          message: 'Kies eerst de spelende partij',
        ),
      );
      expect(find.text('Kies eerst de spelende partij'), findsOneWidget);
      expect(find.text('+10'), findsNothing);
    });

    test('signed', () {
      expect(LiveScorePreview.signed(5), '+5');
      expect(LiveScorePreview.signed(0), '0');
      expect(LiveScorePreview.signed(-5), '-5');
    });
  });
}
