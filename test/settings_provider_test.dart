import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/db/providers.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

void main() {
  test('startup preload gets the saved settings (no hang at the splash screen)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await container.read(settingsRepositoryProvider).set('theme', 'oled');

    final stopwatch = Stopwatch()..start();
    await preloadSettings(container);

    // Must be loaded right away, not after the 8 second fallback.
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
    expect(container.read(prefsProvider).themeChoice, ThemeChoice.oled);
  });

  test('without listening, a plain read of the stream provider hangs (why preload listens)',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await expectLater(
      container.read(settingsProvider.future).timeout(const Duration(seconds: 1)),
      throwsA(isA<Exception>()),
    );
  });
}
