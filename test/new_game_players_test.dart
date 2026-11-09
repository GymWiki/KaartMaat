import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/ui/new_game_screen.dart';
import 'package:kaartmaat/features/groups/data/group_repository.dart';
import 'package:kaartmaat/features/players/data/player_order.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import 'helpers.dart';

class _FakeGroups extends GroupRepository {
  _FakeGroups(super.db);
  final saved = <({String name, List<int> members})>[];
  @override
  Future<int> save({
    int? id,
    required String name,
    required List<int> memberIds,
  }) async {
    saved.add((name: name, members: memberIds));
    return 99;
  }
}

List<PlayerRef> people(List<String> names) => [
  for (var i = 0; i < names.length; i++) PlayerRef(id: i + 1, name: names[i]),
];

const _names = [
  'Anna',
  'Bas',
  'Chris',
  'Dora',
  'Eva',
  'Femke',
  'Gijs',
  'Hanna',
  'Ilse',
  'Jan',
  'Kees',
  'Lotte',
  'Mila',
  'Noor',
  'Otto',
  'Pim',
  'Quinten',
  'Roos',
  'Sven',
  'Tess',
];

void main() {
  group('ordering helpers', () {
    test('recent players first, then everybody else alphabetically', () {
      final p = people(['Zoe', 'Anna', 'Bas', 'Chris', 'dora']);
      final last = {
        3: DateTime(2026, 5, 1), // Bas
        1: DateTime(2026, 6, 1), // Zoe
      };
      expect(sortByRecent(p, last).map((e) => e.name), [
        'Zoe',
        'Bas',
        'Anna',
        'Chris',
        'dora',
      ]);
    });

    test('the same moment: alphabetical; no games at all: alphabetical', () {
      final p = people(['Bas', 'Anna']);
      final same = {1: DateTime(2026, 5, 1), 2: DateTime(2026, 5, 1)};
      expect(sortByRecent(p, same).map((e) => e.name), ['Anna', 'Bas']);
      expect(sortByRecent(p, const {}).map((e) => e.name), ['Anna', 'Bas']);
    });

    test('a group fills its seats in order and stops at the game maximum', () {
      const g = GroupRef(id: 1, name: 'G', memberIds: [5, 3, 9, 1, 2]);
      expect(seatsForGroup(g, 8).ids, [5, 3, 9, 1, 2]);
      expect(seatsForGroup(g, 8).dropped, 0);
      final cut = seatsForGroup(g, 4);
      expect(cut.ids, [5, 3, 9, 1]);
      expect(cut.dropped, 1);
    });

    test('search is case-insensitive and ignores spaces around it', () {
      final p = people(['Anna', 'Hanna', 'Bas']);
      expect(filterByName(p, ' ANN ').map((e) => e.name), ['Anna', 'Hanna']);
      expect(filterByName(p, '').length, 3);
      expect(filterByName(p, 'x'), isEmpty);
    });
  });

  group('last played comes from the games already stored', () {
    test('existing players and games need no migration', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final players = PlayerRepository(db);
      final games = GameRepository(db);
      final a = (await players.add('Anna')).id!;
      final b = (await players.add('Bas')).id!;
      final c = (await players.add('Chris')).id!;
      await games.createGame('custom', [a, b], {});
      final last = await players.watchLastPlayed().first;
      expect(last.keys, {a, b}, reason: 'Chris never played');
      expect(last[a], isNotNull);
      final ordered = sortByRecent(await players.watchActive().first, last);
      expect(ordered.last.id, c);
    });
  });

  group('the screen', () {
    late AppDatabase db;
    late _FakeGroups groups;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      groups = _FakeGroups(db);
    });
    tearDown(() => db.close());

    Future<void> pumpScreen(
      WidgetTester tester, {
      List<String> names = _names,
      List<GroupRef> saved = const [],
      Map<int, DateTime> last = const {},
      String type = 'custom',
      double textScale = 1.0,
    }) async {
      usePhoneScreen(tester);
      await pumpApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: NewGameScreen(type: type),
          ),
        ),
        scaffold: false,
        overrides: [
          playersProvider.overrideWith((ref) => Stream.value(people(names))),
          groupsProvider.overrideWith((ref) => Stream.value(saved)),
          lastPlayedProvider.overrideWith((ref) => Stream.value(last)),
          groupRepositoryProvider.overrideWithValue(groups),
          prefsProvider.overrideWithValue(const AppPrefs({})),
        ],
      );
      await tester.pump();
      await tester.pump();
    }

    Finder chip(String name) => find.widgetWithText(ActionChip, name);

    /// Names at the table, in seat order.
    List<String> atTable(WidgetTester tester) => [
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(ReorderableListView),
          matching: find.byType(Text),
        ),
      ))
        if (t.data != null && !RegExp(r'^\d+$').hasMatch(t.data!)) t.data!,
    ];

    Future<void> tapChip(WidgetTester tester, String name) async {
      await tester.tap(chip(name));
      await tester.pump();
    }

    testWidgets('the Spelregels button opens the rulebook of the game', (
      tester,
    ) async {
      await pumpScreen(tester, type: 'klaverjassen');
      final button = find.widgetWithText(OutlinedButton, 'Spelregels');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Spelregels: Klaverjassen'), findsOneWidget);
      expect(find.text('Puntentelling'), findsWidgets);
    });

    testWidgets('players are picked into the table in tap order', (
      tester,
    ) async {
      await pumpScreen(tester, names: _names.take(5).toList());
      expect(find.text('Aan tafel (0)'), findsOneWidget);
      await tapChip(tester, 'Chris');
      await tapChip(tester, 'Anna');
      expect(find.text('Aan tafel (2)'), findsOneWidget);
      expect(atTable(tester), ['Chris', 'Anna']);
      // a chosen player leaves the list: nobody can be picked twice
      expect(chip('Chris'), findsNothing);
      expect(chip('Anna'), findsNothing);
      expect(chip('Bas'), findsOneWidget);
    });

    testWidgets('a tap on a player at the table takes them off again', (
      tester,
    ) async {
      await pumpScreen(tester, names: _names.take(5).toList());
      await tapChip(tester, 'Anna');
      await tapChip(tester, 'Bas');
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
      expect(atTable(tester), ['Bas']);
      expect(chip('Anna'), findsOneWidget);
    });

    testWidgets('dragging changes the seat order', (tester) async {
      await pumpScreen(tester, names: _names.take(5).toList());
      for (final n in ['Anna', 'Bas', 'Chris']) {
        await tapChip(tester, n);
      }
      await tester.timedDrag(
        find.byIcon(Icons.drag_handle).first,
        const Offset(0, 130),
        const Duration(milliseconds: 600),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(atTable(tester), ['Bas', 'Chris', 'Anna']);
    });

    testWidgets(
      'one tap on a group replaces the selection, in seat order, with undo',
      (tester) async {
        final saved = [
          const GroupRef(id: 7, name: 'Vrijdagavond', memberIds: [4, 2, 3, 1]),
        ];
        await pumpScreen(tester, names: _names.take(6).toList(), saved: saved);
        expect(find.text('Vrijdagavond (4)'), findsOneWidget);
        expect(find.text('Groep'), findsOneWidget); // the "+ Groep" chip
        await tapChip(tester, 'Femke'); // an earlier choice
        await tester.tap(find.text('Vrijdagavond (4)'));
        await tester.pump();
        expect(atTable(tester), ['Dora', 'Bas', 'Chris', 'Anna']);
        expect(find.text('Femke'), findsOneWidget, reason: 'free again');
        expect(find.text('Vrijdagavond geselecteerd'), findsOneWidget);
        // more players can still be added afterwards
        await tapChip(tester, 'Eva');
        expect(find.text('Aan tafel (5)'), findsOneWidget);
        // undo brings the earlier choice back
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(find.text('Ongedaan maken'));
        await tester.pump();
        expect(atTable(tester), ['Femke']);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'a group bigger than the game takes the first players and says so',
      (tester) async {
        final saved = [
          const GroupRef(id: 7, name: 'Groot', memberIds: [1, 2, 3, 4, 5]),
        ];
        await pumpScreen(
          tester,
          names: _names.take(6).toList(),
          saved: saved,
          type: 'klaverjassen',
        );
        await tester.tap(find.text('Groot (5)'));
        await tester.pump();
        expect(atTable(tester), ['Anna', 'Bas', 'Chris', 'Dora']);
        expect(
          find.text(
            'Klaverjassen is max. 4 spelers: de eerste 4 van Groot zijn gekozen',
          ),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('a group whose player was deleted shows the rest', (
      tester,
    ) async {
      // the repository leaves deleted players out, so the chip counts 2
      final saved = [
        const GroupRef(id: 7, name: 'Duo', memberIds: [1, 3]),
      ];
      await pumpScreen(tester, names: _names.take(4).toList(), saved: saved);
      expect(find.text('Duo (2)'), findsOneWidget);
      await tester.tap(find.text('Duo (2)'));
      await tester.pump();
      expect(atTable(tester), ['Anna', 'Chris']);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets(
      'choosing more players than the game allows is refused with a message',
      (tester) async {
        await pumpScreen(
          tester,
          names: _names.take(6).toList(),
          type: 'klaverjassen',
        );
        for (final n in ['Anna', 'Bas', 'Chris', 'Dora']) {
          await tapChip(tester, n);
        }
        await tapChip(tester, 'Eva');
        expect(find.text('Aan tafel (4)'), findsOneWidget);
        expect(find.text('Klaverjassen is max. 4 spelers'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('the player list follows the recent order', (tester) async {
      await pumpScreen(
        tester,
        names: _names.take(5).toList(),
        last: {5: DateTime(2026, 6, 1), 3: DateTime(2026, 5, 1)}, // Eva, Chris
      );
      final labels = [
        for (final c in tester.widgetList<ActionChip>(find.byType(ActionChip)))
          (c.label as Text).data,
      ]..remove('Groep'); // the "+ Groep" chip of the group row
      expect(labels.take(5).toList(), ['Eva', 'Chris', 'Anna', 'Bas', 'Dora']);
    });

    testWidgets(
      'with 20 saved players: 8 show, "Toon alle (20)" shows the rest',
      (tester) async {
        await pumpScreen(tester);
        final before = _countPlayerChips(tester);
        expect(before, 8, reason: "8 players show before \"Toon alle\"");
        expect(find.text('Toon alle (20)'), findsOneWidget);
        expect(find.text('Zoek speler'), findsOneWidget);
        await tester.ensureVisible(find.text('Toon alle (20)'));
        await tester.tap(find.text('Toon alle (20)'));
        await tester.pump();
        expect(_countPlayerChips(tester), 20);
        expect(find.text('Toon minder'), findsOneWidget);
      },
    );

    testWidgets('search narrows the list, and shows every match', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'ann');
      await tester.pump();
      expect(chip('Anna'), findsOneWidget);
      expect(chip('Hanna'), findsOneWidget);
      expect(chip('Bas'), findsNothing);
      expect(find.text('Toon alle (20)'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('Geen speler gevonden'), findsOneWidget);
    });

    testWidgets('no search field while there are fewer than 8 saved players', (
      tester,
    ) async {
      await pumpScreen(tester, names: _names.take(7).toList());
      expect(find.text('Zoek speler'), findsNothing);
      expect(find.textContaining('Toon alle'), findsNothing);
    });

    testWidgets(
      '"Opslaan als groep" appears with a selection and saves the seat order',
      (tester) async {
        await pumpScreen(tester, names: _names.take(5).toList());
        expect(find.text('Opslaan als groep'), findsNothing);
        await tapChip(tester, 'Dora');
        await tapChip(tester, 'Anna');
        await tester.tap(find.text('Opslaan als groep'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.enterText(find.byType(TextField).last, 'Zaterdag');
        await tester.pump();
        await tester.tap(find.text('Opslaan'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(groups.saved.single.name, 'Zaterdag');
        expect(groups.saved.single.members, [4, 1]);
        expect(find.text('Groep Zaterdag opgeslagen'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '20 players and a 200% system font: no overflow, nothing cut off',
      (tester) async {
        final saved = [
          for (var i = 0; i < 4; i++)
            GroupRef(
              id: i + 1,
              name: 'Groep met een lange naam ${i + 1}',
              memberIds: const [1, 2, 3, 4],
            ),
        ];
        await pumpScreen(tester, saved: saved, textScale: 2.0);
        await tapChip(tester, 'Anna');
        await tapChip(tester, 'Bas');
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Toon alle (18)'));
        await tester.tap(find.text('Toon alle (18)'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// Player chips on screen (not the "+ Groep" and "Nieuwe speler" chips).
int _countPlayerChips(WidgetTester tester) => tester
    .widgetList<ActionChip>(find.byType(ActionChip))
    .where((c) => !{'Groep', 'Nieuwe speler'}.contains((c.label as Text).data))
    .length;
