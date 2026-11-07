import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/l10n/gen/app_localizations.dart';
import 'package:kaartmaat/core/theme/app_theme.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';

/// A normal phone: 411 x 914 dp (1080 x 2400 px at 2.625).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

/// Pumps [child] in the real app theme, Dutch, inside a Scaffold.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  bool scaffold = true,
}) =>
    tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.light(),
      locale: const Locale('nl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: scaffold ? Scaffold(body: child) : child,
    ));

/// An unfinished "custom" game with players 1..[players] and one round per
/// entry of [rounds] (points per player, in seat order).
GameState customGame(List<List<int>> rounds, {int players = 3}) => GameState(
      id: 1,
      type: 'custom',
      createdAt: DateTime(2026, 5, 1),
      finishedAt: null,
      settings: const {'lowestWins': false},
      players: [for (var i = 1; i <= players; i++) PlayerRef(id: i, name: 'P$i')],
      rounds: [
        for (var r = 0; r < rounds.length; r++)
          RoundData(number: r + 1, entries: {
            for (var i = 0; i < players; i++) '${i + 1}': {'points': rounds[r][i]},
          }),
      ],
    );
