import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/l10n/gen/app_localizations.dart';
import 'package:kaartmaat/core/ui/avatars.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/history/result_image.dart';
import 'package:kaartmaat/features/history/result_export.dart';
import 'package:kaartmaat/features/history/share_result_card.dart';
import 'package:kaartmaat/features/players/data/player_repository.dart';

GameState game(Map<int, int> points) => GameState(
      id: 1,
      type: 'custom',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: DateTime(2026, 5, 1),
      settings: const {'lowestWins': false},
      players: [
        for (final id in points.keys) PlayerRef(id: id, name: 'P$id', avatar: id),
      ],
      rounds: [
        RoundData(number: 1, entries: {
          for (final e in points.entries) '${e.key}': {'points': e.value},
        }),
      ],
    );

void main() {
  setUpAll(() => initializeDateFormatting('nl'));

  group('badges', () {
    test('crown for first place, donkey for last place', () {
      final b = badgesFor(GameView(game({1: 30, 2: 20, 3: 5})));
      expect(b.crown, {'1'});
      expect(b.donkey, {'3'});
    });

    test('ties share the badge; with two players the loser is the donkey', () {
      final tie = badgesFor(GameView(game({1: 30, 2: 30, 3: 5})));
      expect(tie.crown, {'1', '2'});
      expect(tie.donkey, {'3'});
      final two = badgesFor(GameView(game({1: 9, 2: 3})));
      expect(two.crown, {'1'});
      expect(two.donkey, {'2'});
    });

    test('no donkey when everybody tied for first', () {
      final b = badgesFor(GameView(game({1: 10, 2: 10, 3: 10})));
      expect(b.crown, {'1', '2', '3'});
      expect(b.donkey, isEmpty);
    });
  });

  test('avatars wrap around and persist per player', () async {
    expect(avatarCount, 8);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final players = PlayerRepository(db);
    final id = (await players.add('Anna')).id!;
    expect((await players.watchActive().first).single.avatar, id % avatarCount);
    await players.setAvatar(id, 5);
    expect((await players.watchActive().first).single.avatar, 5);
  });

  testWidgets('the result card renders to a 1080x1350 PNG with the watermark',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('nl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: key,
            child: ShareResultCard(view: GameView(game({1: 30, 2: 20, 3: 5}))),
          ),
        ),
      ),
    ));

    expect(find.text('Uitslag bijgehouden met de Kaartmaat App'), findsOneWidget);
    expect(find.text('P1'), findsWidgets);

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() => renderCardPng(boundary));
    expect(bytes!.sublist(1, 4), [0x50, 0x4E, 0x47]); // "PNG"
    final codec = await tester.runAsync(() => ui.instantiateImageCodec(bytes));
    final frame = await tester.runAsync(() => codec!.getNextFrame());
    expect(frame!.image.width, 1080);
    expect(frame.image.height, 1350);
  });
}
