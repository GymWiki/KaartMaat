import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/ui/seat_chips.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/games/ui/round_table.dart';

import 'helpers.dart';

GameState gameOf(String type, int players, {List<String>? names}) {
  final def = definitionFor(type);
  return GameState(
    id: 1,
    type: type,
    createdAt: DateTime(2026, 5, 1),
    finishedAt: null,
    settings: def.rules.defaultSettings,
    players: [
      for (var i = 0; i < players; i++)
        PlayerRef(id: i + 1, name: names?[i] ?? 'P${i + 1}'),
    ],
    rounds: const [],
  );
}

void main() {
  group('the chips', () {
    testWidgets('dealer: a round brass chip with a "D" and the label "Deler"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: DealerChip()));
      expect(find.text('D'), findsOneWidget);
      expect(find.bySemanticsLabel('Deler'), findsOneWidget);
      final box = tester.widget<Container>(find.byType(Container).first);
      expect((box.decoration! as BoxDecoration).shape, BoxShape.circle);
      expect(tester.getSize(find.byType(DealerChip)), const Size(16, 16));
      handle.dispose();
    });

    testWidgets('first bidder: an outlined chip with a "1" and "Eerste bieder"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: FirstBidderChip()));
      expect(find.text('1'), findsOneWidget);
      expect(find.bySemanticsLabel('Eerste bieder'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the chip ignores the system font scale', (tester) async {
      await pumpApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
          child: const Center(child: DealerChip()),
        ),
      );
      expect(tester.getSize(find.byType(DealerChip)), const Size(16, 16));
      expect(tester.takeException(), isNull);
    });
  });

  group('name with chip', () {
    Future<void> pump(
      WidgetTester tester,
      String name,
      SeatMarker? marker,
      double width, {
      bool reduceMotion = false,
    }) => pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Center(
          child: SizedBox(
            width: width,
            child: NameWithMarker(
              name: name,
              marker: marker,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ),
    );

    testWidgets('a long name is cut with an ellipsis, the chip stays whole', (
      tester,
    ) async {
      await pump(
        tester,
        'Bartholomeus Johannes Hendrikus Willemsen',
        SeatMarker.dealer,
        46,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(DealerChip), findsOneWidget);
      final chip = tester.getRect(find.byType(DealerChip));
      final row = tester.getRect(find.byType(NameWithMarker));
      expect(row.contains(chip.center), isTrue);
      expect(chip.size, const Size(16, 16));
      final text = tester.widget<Text>(find.textContaining('Bartholomeus'));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
    });

    testWidgets('no marker, no chip', (tester) async {
      await pump(tester, 'Anna', null, 80);
      expect(find.byType(DealerChip), findsNothing);
      expect(find.byType(FirstBidderChip), findsNothing);
    });

    testWidgets('a new round makes the chip pop over in about 250 ms', (
      tester,
    ) async {
      await pump(tester, 'Anna', SeatMarker.dealer, 120);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DealerChip), findsOneWidget);
      await pump(tester, 'Anna', SeatMarker.firstBidder, 120);
      await tester.pump(const Duration(milliseconds: 100));
      // halfway: the old chip is still leaving while the new one arrives
      expect(find.byType(DealerChip), findsOneWidget);
      expect(find.byType(FirstBidderChip), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DealerChip), findsNothing);
      expect(find.byType(FirstBidderChip), findsOneWidget);
    });

    testWidgets('reduced motion: it switches at once', (tester) async {
      await pump(tester, 'Anna', SeatMarker.dealer, 120, reduceMotion: true);
      await pump(tester, 'Anna', null, 120, reduceMotion: true);
      await tester.pump();
      expect(find.byType(DealerChip), findsNothing);
    });
  });

  group('the table header', () {
    Future<void> pumpTable(
      WidgetTester tester,
      String type,
      int players,
      int round, {
      List<String>? names,
    }) async {
      usePhoneScreen(tester);
      final state = gameOf(type, players, names: names);
      final view = GameView(state);
      final markers = definitionFor(type).seatMarkers!(view, round);
      await pumpApp(
        tester,
        RoundTable(view: view, seatMarker: (p) => markers[p]),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    Finder chipNextTo(String name, Type chip) => find.descendant(
      of: find.ancestor(
        of: find.text(name),
        matching: find.byType(NameWithMarker),
      ),
      matching: find.byType(chip),
    );

    testWidgets('Boerenbridge: D at the dealer, 1 at the player left of them', (
      tester,
    ) async {
      await pumpTable(tester, 'boerenbridge', 4, 1);
      expect(chipNextTo('P1', DealerChip), findsOneWidget);
      expect(chipNextTo('P2', FirstBidderChip), findsOneWidget);
      expect(find.byType(DealerChip), findsOneWidget);
      expect(find.byType(FirstBidderChip), findsOneWidget);
    });

    testWidgets('the chips move on with the round, and wrap around the table', (
      tester,
    ) async {
      await pumpTable(tester, 'boerenbridge', 4, 2);
      expect(chipNextTo('P2', DealerChip), findsOneWidget);
      expect(chipNextTo('P3', FirstBidderChip), findsOneWidget);
      await pumpTable(tester, 'boerenbridge', 4, 4);
      expect(chipNextTo('P4', DealerChip), findsOneWidget);
      expect(chipNextTo('P1', FirstBidderChip), findsOneWidget);
    });

    testWidgets('7 and 8 players with long names: no overflow', (tester) async {
      for (final n in [7, 8]) {
        final long = [
          for (var i = 0; i < n; i++) 'Spelernaam-met-een-lange-naam-${i + 1}',
        ];
        await pumpTable(tester, 'boerenbridge', n, 1, names: long);
        expect(tester.takeException(), isNull, reason: '$n players');
        expect(find.byType(DealerChip), findsOneWidget);
        expect(find.byType(FirstBidderChip), findsOneWidget);
      }
    });

    testWidgets('Klaverjassen: the chips mark the teams of dealer and first bidder', (
      tester,
    ) async {
      await pumpTable(tester, 'klaverjassen', 4, 1);
      // dealer P1 is in wij, the player left of them (P2) in zij
      final markers = definitionFor(
        'klaverjassen',
      ).seatMarkers!(GameView(gameOf('klaverjassen', 4)), 1);
      expect(markers, {
        'wij': SeatMarker.dealer,
        'zij': SeatMarker.firstBidder,
      });
      expect(find.byType(DealerChip), findsOneWidget);
      expect(find.byType(FirstBidderChip), findsOneWidget);
    });

    test('games where dealing does not matter show no chips', () {
      for (final type in [
        'custom',
        'duizenden',
        'hartenjagen',
        'toepen',
        'jokeren',
        'canasta',
        'rikken',
      ]) {
        expect(definitionFor(type).seatMarkers, isNull, reason: type);
      }
    });
  });
}
