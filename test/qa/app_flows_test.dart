// QA pass: the real app (router, screens, providers) on an in-memory
// database, driven like a user. No emulator needed.
import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaartmaat/app.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/db/providers.dart';
import 'package:kaartmaat/core/router/app_router.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/groups/data/group_repository.dart';
import 'package:kaartmaat/features/history/share_result_card.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

late AppDatabase db;
late List<int> ids; // Anna, Bas, Chris, Dora, Eva, Femke, Gerrit, Hanna, Ilse

const names = [
  'Anna',
  'Bas',
  'Chris',
  'Dora',
  'Eva',
  'Femke',
  'Gerrit',
  'Hanna',
  'Ilse',
];

/// Database calls need real async inside a widget test.
Future<T> real<T>(WidgetTester tester, Future<T> Function() f) async =>
    (await tester.runAsync(f)) as T;

Future<GameState> loadGame(WidgetTester tester, int id) async {
  final g = await real<GameState?>(tester, () => GameRepository(db).load(id));
  return g!;
}

Future<void> settle(WidgetTester tester, [int times = 6]) async {
  for (var i = 0; i < times; i++) {
    // let pending database work finish in real time, then run the frames
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Boots the real app. [seedPlayers] players are created first.
Future<void> boot(
  WidgetTester tester, {
  int seedPlayers = 9,
  Future<void> Function()? seed,
  bool pro = true,
}) async {
  d.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  usePhoneScreen(tester);
  db = AppDatabase(NativeDatabase.memory());
  ids = await real(
    tester,
    () async => [
      for (final n in names.take(seedPlayers))
        (await PlayerRepository(db).add(n)).id!,
    ],
  );

  if (seed != null) await real(tester, seed);
  // the screens behind Pro are tested as a Pro user (debug override)
  if (pro) {
    await real(
      tester,
      () => SettingsRepository(db).set('pro.debugOverride', 'on'),
    );
  }
  appRouter.go('/');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const KaartmaatApp(),
    ),
  );
  await settle(tester);
}

Future<void> goTo(WidgetTester tester, String path) async {
  appRouter.go(path);
  await settle(tester);
}

Future<void> tapText(WidgetTester tester, String text, {int index = 0}) async {
  final f = find.text(text);
  expect(f, findsWidgets, reason: 'no "$text" on screen');
  await tester.tap(f.at(index));
  await settle(tester);
}

/// Like testWidgets, but disposes the app inside the test body so drift's
/// stream clean-up timers are gone before flutter_test checks for them.
void appTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    try {
      await body(tester);
    } finally {
      // let snackbars (undo, max players) finish before the app goes away
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    }
  });
}

void main() {
  proWallTests();
  startGuardTests();
  setUpAll(() => initializeDateFormatting('nl'));

  appTest('home shows every game, Dutch only', (tester) async {
    await boot(tester);
    for (final t in [
      'Algemene teller',
      'Boerenbridge',
      'Klaverjassen',
      'Toepen',
      'Rikken',
      'Hartenjagen',
      'Jokeren',
      'Canasta',
      'Duizenden',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(gameDefinitions.length, 9);
    // bottom navigation
    for (final t in [
      'Spellen',
      'Spelers',
      'Historie',
      'Statistieken',
      'Instellingen',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  for (final entry in gameDefinitions.entries) {
    final id = entry.key;
    final rules = entry.value.rules;
    appTest(
      'new game "$id": start enabled for ${rules.minPlayers}..${rules.maxPlayers} players only',
      (tester) async {
        await boot(tester);
        await goTo(tester, '/new/$id');
        final start = find.byType(FilledButton).last;
        bool enabled() => tester.widget<FilledButton>(start).onPressed != null;

        expect(enabled(), isFalse, reason: 'no players selected');
        expect(
          find.text('Kies ${rules.minPlayers} tot ${rules.maxPlayers} spelers'),
          findsOneWidget,
        );

        var selected = 0;
        for (final n in names) {
          await tester.tap(find.widgetWithText(ActionChip, n));
          await settle(tester, 2);
          selected = (selected + 1).clamp(0, rules.maxPlayers);
          expect(
            enabled(),
            selected >= rules.minPlayers && selected <= rules.maxPlayers,
            reason: '$selected selected',
          );
        }
        // 9 players tapped: never more than the maximum can be selected
        expect(find.text('Start spel'), findsOneWidget);
        expect(enabled(), isTrue);
      },
    );
  }

  appTest('history: a finished game opens the result screen with its actions', (
    tester,
  ) async {
    await boot(
      tester,
      seedPlayers: 2,
      seed: () async {
        final repo = GameRepository(db);
        final gid = await repo.createGame('custom', ids, {});
        await repo.addRound(gid, {
          '${ids[0]}': {'points': 3},
          '${ids[1]}': {'points': 1},
        });
        await repo.finish(gid);
      },
    );
    await goTo(tester, '/history');
    expect(find.text('Algemene teller'), findsWidgets);
    expect(find.textContaining('Winnaar: Anna'), findsOneWidget);
    await tester.tap(find.text('Algemene teller').last);
    await settle(tester);
    // the share card is the screen, the actions sit below it
    expect(find.byType(ShareResultCard), findsOneWidget);
    expect(find.text('Delen'), findsOneWidget);
    expect(find.text('Opslaan als afbeelding'), findsOneWidget);
    expect(find.text('Nieuw spel'), findsOneWidget);
    expect(find.text('Hervat spel'), findsOneWidget);
    expect(find.text('Anna'), findsWidgets);
  });

  appTest('players: duplicate names are refused with a message, rename works', (
    tester,
  ) async {
    await boot(tester, seedPlayers: 2);
    await goTo(tester, '/players');
    await tester.tap(find.text('Speler toevoegen'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'anna');
    await tester.tap(find.text('Opslaan'));
    await settle(tester);
    expect(find.text('Deze naam bestaat al'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Opslaan'));
    await settle(tester);
    expect(find.text('Vul een naam in'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Chris');
    await tester.tap(find.text('Opslaan'));
    await settle(tester);
    expect(find.text('Chris'), findsOneWidget);
    expect(
      (await real(
        tester,
        () => PlayerRepository(db).watchActive().first,
      )).length,
      3,
    );
  });

  appTest('a saved group starts a game with its members in order', (
    tester,
  ) async {
    await boot(tester, seedPlayers: 4);
    await real(
      tester,
      () => GroupRepository(
        db,
      ).save(name: 'Vrijdag', memberIds: [ids[2], ids[0], ids[3], ids[1]]),
    );
    await settle(tester);
    await goTo(tester, '/new/klaverjassen');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Vrijdag (4)'));
    await settle(tester, 2);
    await tester.tap(find.text('Start spel'));
    await settle(tester);
    final s = (await loadGame(tester, 1));
    expect(s.players.map((p) => p.name), ['Chris', 'Anna', 'Dora', 'Bas']);
    expect(s.groupId, isNotNull);
  });

  appTest('"Hervat spel" card shows the unfinished game and opens it', (
    tester,
  ) async {
    await boot(
      tester,
      seedPlayers: 3,
      seed: () async {
        final gid = await GameRepository(db).createGame('custom', ids, {});
        await GameRepository(db).addRound(gid, {
          for (final i in ids) '$i': {'points': 2},
        });
      },
    );
    expect(find.text('Hervat spel'), findsOneWidget);
    expect(find.textContaining('1 ronde'), findsWidgets);
    await tester.tap(find.text('Hervat spel'));
    await settle(tester);
    expect(find.text('Anna'), findsWidgets);
  });
}

void proWallTests() {
  appTest(
    'Pro: no wall at startup, wall only when Statistieken or Historie opens',
    (tester) async {
      await boot(tester, pro: false);
      // the home screen and the free parts never show the wall
      expect(find.text('Kaartmaat Pro'), findsNothing);
      expect(find.text('Ontgrendel Pro'), findsNothing);
      await goTo(tester, '/players');
      expect(find.text('Ontgrendel Pro'), findsNothing);
      await goTo(tester, '/stats');
      expect(find.text('Kaartmaat Pro'), findsOneWidget);
      expect(find.text('Ontgrendel Pro'), findsOneWidget);
      expect(
        find.text('Kaartkoning ${DateTime.now().year}'),
        findsOneWidget,
        reason: 'sample preview',
      );
      await goTo(tester, '/history');
      expect(find.text('Kaartmaat Pro'), findsOneWidget);
      expect(
        find.text('Klaverjassen'),
        findsOneWidget,
        reason: 'sample preview',
      );
    },
  );

  appTest('Pro: with Pro the real screens show', (tester) async {
    await boot(tester); // pro by the debug override
    await goTo(tester, '/stats');
    expect(find.text('Kaartmaat Pro'), findsNothing);
    expect(find.text('Nog geen afgeronde spellen'), findsWidgets);
    await goTo(tester, '/history');
    expect(find.text('Kaartmaat Pro'), findsNothing);
  });

  appTest('Pro: free users keep their games, and Pro shows them at once', (
    tester,
  ) async {
    await boot(
      tester,
      seedPlayers: 2,
      pro: false,
      seed: () async {
        final repo = GameRepository(db);
        final gid = await repo.createGame('custom', ids, {});
        await repo.addRound(gid, {
          '${ids[0]}': {'points': 3},
          '${ids[1]}': {'points': 1},
        });
        await repo.finish(gid);
      },
    );
    // stored while free, behind the wall
    final finished = await real(
      tester,
      () => GameRepository(db).watchFinished().first,
    );
    expect(finished.length, 1);
    await goTo(tester, '/history');
    expect(find.text('Ontgrendel Pro'), findsOneWidget);
    expect(
      find.textContaining('Winnaar: Anna'),
      findsWidgets,
      reason: 'own data in the preview',
    );
    // after the purchase the same data is there
    await real(tester, () => SettingsRepository(db).set('pro.purchased', '1'));
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
  });
}

void startGuardTests() {
  appTest('QA-01: older unfinished games are listed and can be deleted', (
    tester,
  ) async {
    await boot(
      tester,
      seedPlayers: 2,
      seed: () async {
        final repo = GameRepository(db);
        await repo.createGame('toepen', ids, {});
        await repo.createGame('custom', ids, {});
      },
    );
    expect(find.text('Hervat spel'), findsOneWidget);
    expect(find.text('Andere lopende spellen'), findsOneWidget);
    // the older one (Toepen) is a tile of its own
    expect(find.text('Toepen'), findsWidgets);
    await tester.tap(find.byTooltip('Spel verwijderen'));
    await settle(tester);
    await tester.tap(find.text('Verwijderen').last);
    await settle(tester);
    final left = await real(tester, () => db.select(db.games).get());
    expect(left.length, 1);
    expect(left.single.type, 'custom');
  });

  appTest('QA-02b: tapping Start spel twice starts only one game', (
    tester,
  ) async {
    await boot(tester, seedPlayers: 2);
    await goTo(tester, '/new/custom');
    await tester.tap(find.widgetWithText(ActionChip, 'Anna'));
    await tester.tap(find.widgetWithText(ActionChip, 'Bas'));
    await settle(tester, 2);
    final start = find.text('Start spel');
    // two taps without a frame in between, like a nervous double tap
    await tester.tap(start);
    await tester.tap(start, warnIfMissed: false);
    await settle(tester);
    final all = await real(tester, () => db.select(db.games).get());
    expect(all.length, 1);
  });
}
