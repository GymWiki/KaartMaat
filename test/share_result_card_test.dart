import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/duizenden_rules.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/klaverjas_rules.dart';
import 'package:kaartmaat/features/history/share_result_card.dart';

import 'helpers.dart';

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

GameState custom(
  List<int> points, {
  List<String>? names,
  bool lowestWins = false,
  int rounds = 1,
}) => GameState(
  id: 1,
  type: 'custom',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: DateTime(2026, 5, 1),
  settings: {'lowestWins': lowestWins},
  players: [
    for (var i = 0; i < points.length; i++)
      PlayerRef(id: i + 1, name: (names ?? _names)[i], avatar: i),
  ],
  rounds: [
    for (var r = 1; r <= rounds; r++)
      RoundData(
        number: r,
        entries: {
          for (var i = 0; i < points.length; i++)
            '${i + 1}': {'points': r == 1 ? points[i] : 0},
        },
      ),
  ],
);

GameState duizenden() => GameState(
  id: 1,
  type: 'duizenden',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: DateTime(2026, 5, 1),
  settings: const DuizendenRules().defaultSettings,
  players: [
    for (var i = 0; i < 4; i++) PlayerRef(id: i + 1, name: _names[i], avatar: i),
  ],
  rounds: [
    for (final (n, scores) in [
      (1, [620, 450, 300, -80]),
      (2, [-100, 220, 100, 60]),
      (3, [530, 200, 0, 40]),
    ])
      RoundData(
        number: n,
        entries: {
          for (var i = 0; i < 4; i++) '${i + 1}': {'points': scores[i]},
        },
      ),
  ],
);

GameState klaverjas() => GameState(
  id: 1,
  type: 'klaverjassen',
  createdAt: DateTime(2026, 5, 1),
  finishedAt: DateTime(2026, 5, 1),
  settings: const KlaverjasRules().defaultSettings,
  players: [
    for (var i = 0; i < 4; i++)
      PlayerRef(id: i + 1, name: _names[i], avatar: i),
  ],
  rounds: [
    RoundData(
      number: 1,
      entries: {
        'wij': {
          'playing': true,
          'pit': false,
          'cards': 100,
          'three': 0,
          'four': 0,
          'stuk': 0,
          'equal': 0,
          'jacks': 0,
        },
        'zij': {
          'playing': false,
          'pit': false,
          'cards': 62,
          'three': 0,
          'four': 0,
          'stuk': 0,
          'equal': 0,
          'jacks': 0,
        },
      },
    ),
  ],
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('nl');
    final loader = FontLoader('RobotoCondensed')
      ..addFont(rootBundle.load('assets/fonts/RobotoCondensed-Bold.ttf'));
    await loader.load();
  });

  Future<void> pumpCard(
    WidgetTester tester,
    GameState state, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(1080, 1350);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Center(
            child: RepaintBoundary(
              child: ShareResultCard(view: GameView(state)),
            ),
          ),
        ),
      ),
      scaffold: false,
    );
    await tester.pump();
    // let the avatar pictures decode (real time) before the golden is taken
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  group('golden', () {
    final cases = <String, GameState>{
      '2_players': custom([30, 12]),
      '4_players': custom([30, 25, 12, 3]),
      '8_players': custom([80, 70, 60, 50, 40, 30, 20, 10]),
      'tie': custom([30, 30, 12]),
      'team_klaverjassen': klaverjas(),
      'long_names': custom(
        [30, 12, 3],
        names: [
          'Alexandra-Maria van der Berg-Oostenrijk de Derde',
          'Bartholomeus Johannes Hendrikus Willemsen',
          'Chris',
        ],
      ),
      'lowest_wins': custom([30, 12, 3], lowestWins: true),
      'duizenden': duizenden(),
    };
    cases.forEach((name, state) {
      testWidgets(name, (tester) async {
        await pumpCard(tester, state);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(ShareResultCard),
          matchesGoldenFile('goldens/share_card_$name.png'),
        );
      });
    });
  });

  group('content and layout', () {
    testWidgets('fixed 4:5 size, whatever the text scale', (tester) async {
      await pumpCard(tester, custom([30, 12]), textScale: 2.5);
      final size = tester.getSize(find.byType(ShareResultCard));
      expect(size, const Size(360, 450));
      expect(size.width / size.height, closeTo(0.8, 0.0001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('winner, points and ranking are shown', (tester) async {
      await pumpCard(tester, custom([30, 12, 3]));
      expect(find.text('Anna'), findsNWidgets(2)); // winner block + ranking
      expect(find.text('30'), findsNWidgets(2));
      expect(
        find.text('Uitslag bijgehouden met de Kaartmaat App'),
        findsOneWidget,
      );
      expect(find.text('1 ronde gespeeld'), findsOneWidget);
    });

    testWidgets('a tie shows "Gedeelde winst" and both names, rank 1 twice', (
      tester,
    ) async {
      await pumpCard(tester, custom([30, 30, 12]));
      expect(find.text('Gedeelde winst'), findsOneWidget);
      expect(find.textContaining('Anna'), findsWidgets);
      expect(find.textContaining('Bas'), findsWidgets);
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget); // next rank skips 2
    });

    testWidgets('lowest wins: the lowest total is first and wins', (
      tester,
    ) async {
      await pumpCard(tester, custom([30, 12, 3], lowestWins: true));
      final names = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      expect(names.indexOf('Chris') < names.indexOf('Bas'), isTrue);
      expect(find.text('Gedeelde winst'), findsNothing);
    });

    testWidgets('no donkey when everybody is tied', (tester) async {
      await pumpCard(tester, custom([10, 10, 10]));
      expect(find.text('Gedeelde winst'), findsOneWidget);
    });

    testWidgets('2 to 8 players fit without overflow', (tester) async {
      for (var n = 2; n <= 8; n++) {
        await pumpCard(tester, custom([for (var i = 0; i < n; i++) 100 - i]));
        expect(tester.takeException(), isNull, reason: '$n players');
        expect(
          tester.getSize(find.byType(ShareResultCard)),
          const Size(360, 450),
        );
      }
    });

    testWidgets('long names are ellipsized, no overflow', (tester) async {
      final long = 'X' * 60;
      await pumpCard(tester, custom([5, 4], names: [long, 'Bas']));
      expect(tester.takeException(), isNull);
    });

    testWidgets('team game: team names with the players under them', (
      tester,
    ) async {
      await pumpCard(tester, klaverjas());
      expect(find.text('Wij'), findsWidgets);
      expect(find.text('Zij'), findsWidgets);
      expect(find.text('Anna & Chris'), findsWidgets);
      expect(find.text('Bas & Dora'), findsWidgets);
      expect(find.textContaining('Klaverjassen, Amsterdams'), findsOneWidget);
    });

    testWidgets('a game without rounds shows no winner section', (
      tester,
    ) async {
      final empty = GameState(
        id: 1,
        type: 'boerenbridge',
        createdAt: DateTime(2026, 5, 1),
        finishedAt: DateTime(2026, 5, 1),
        settings: const BoerenbridgeRules().defaultSettings,
        players: [
          for (var i = 0; i < 3; i++) PlayerRef(id: i + 1, name: _names[i]),
        ],
        rounds: const [],
      );
      await pumpCard(tester, empty);
      expect(tester.takeException(), isNull);
      expect(find.text('Gedeelde winst'), findsNothing);
    });
  });
}
