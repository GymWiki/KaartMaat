import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/data/wakelock_controller.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/ui/game_screen.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

class _FakeWakelock extends WakelockController {
  _FakeWakelock();
  final calls = <bool>[];
  @override
  Future<void> set(bool on) async => calls.add(on);
}

class _NoDrafts extends DraftStore {
  _NoDrafts(super.settings);
  @override
  Future<Map<String, Object?>?> load(int gameId) async => null;
  @override
  Future<void> save(int gameId, Map<String, Object?> draft) async {}
  @override
  Future<void> clear(int gameId) async {}
}

GameState gameOf(String type) {
  final def = definitionFor(type);
  return GameState(
    id: 1,
    type: type,
    createdAt: DateTime(2026, 5, 1),
    finishedAt: null,
    settings: def.rules.defaultSettings,
    players: [
      for (var i = 0; i < def.minPlayers; i++)
        PlayerRef(id: i + 1, name: 'Speler${i + 1}'),
    ],
    rounds: const [],
  );
}

void main() {
  late AppDatabase db;
  late _FakeWakelock wakelock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    wakelock = _FakeWakelock();
  });
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester,
    String type, {
    Map<String, String> prefs = const {},
  }) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      const GameScreen(gameId: 1),
      scaffold: false,
      overrides: [
        gameRepositoryProvider.overrideWithValue(GameRepository(db)),
        gameStateProvider.overrideWith((ref, id) => Stream.value(gameOf(type))),
        draftStoreProvider.overrideWithValue(_NoDrafts(SettingsRepository(db))),
        prefsProvider.overrideWithValue(AppPrefs(prefs)),
        wakelockProvider.overrideWithValue(wakelock),
      ],
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> letSnackBarsFinish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  }

  Finder on() => find.byIcon(Icons.light_mode);
  Finder off() => find.byIcon(Icons.light_mode_outlined);

  testWidgets('off by default: outlined icon, the screen is not held', (
    tester,
  ) async {
    await open(tester, 'custom');
    expect(off(), findsOneWidget);
    expect(on(), findsNothing);
    expect(wakelock.calls, isEmpty);
  });

  testWidgets('a tap switches on and off, with a snackbar each time', (
    tester,
  ) async {
    await open(tester, 'custom');
    await tester.tap(find.byTooltip('Scherm aan houden'));
    await tester.pump();
    expect(wakelock.calls, [true]);
    expect(find.text('Scherm blijft aan'), findsOneWidget);
    expect(on(), findsOneWidget);
    await tester.tap(find.byTooltip('Scherm aan houden'));
    await tester.pump();
    expect(wakelock.calls, [true, false]);
    expect(find.text('Scherm mag uit'), findsOneWidget);
    expect(find.text('Scherm blijft aan'), findsNothing);
    expect(off(), findsOneWidget);
    await letSnackBarsFinish(tester);
  });

  testWidgets('the setting starts every game with the screen on', (
    tester,
  ) async {
    await open(tester, 'custom', prefs: {'keepAwake': '1'});
    expect(wakelock.calls, [true]);
    expect(on(), findsOneWidget);
    // and the button can still switch it off for this game
    await tester.tap(find.byTooltip('Scherm aan houden'));
    await tester.pump();
    expect(wakelock.calls, [true, false]);
    await letSnackBarsFinish(tester);
  });

  testWidgets('going to the background switches it off', (tester) async {
    await open(tester, 'custom');
    await tester.tap(find.byTooltip('Scherm aan houden'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(wakelock.calls, [true, false]);
    expect(off(), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(wakelock.calls, [
      true,
      false,
    ], reason: 'coming back does not switch it on');
    await letSnackBarsFinish(tester);
  });

  testWidgets('leaving the game switches it off', (tester) async {
    await open(tester, 'custom');
    await tester.tap(find.byTooltip('Scherm aan houden'));
    await tester.pump();
    await letSnackBarsFinish(tester);
    await tester.pumpWidget(const SizedBox());
    expect(wakelock.calls.last, isFalse);
  });

  for (final type in gameDefinitions.keys) {
    testWidgets('the button is in the $type screen', (tester) async {
      await open(tester, type);
      expect(find.byTooltip('Scherm aan houden'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('the default is a stored preference, off unless chosen', () {
    expect(const AppPrefs({}).keepAwakeByDefault, isFalse);
    expect(const AppPrefs({'keepAwake': '1'}).keepAwakeByDefault, isTrue);
    expect(const AppPrefs({'keepAwake': '0'}).keepAwakeByDefault, isFalse);
  });
}
