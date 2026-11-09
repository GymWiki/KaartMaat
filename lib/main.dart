import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/providers.dart';
import 'core/demo/demo_data.dart';
import 'core/router/app_router.dart';
import 'core/router/startup.dart';
import 'features/games/data/game_repository.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // Store screenshots only: debug/profile with --dart-define=DEMO=true.
  if (demoModeEnabled) await seedDemoData(container.read(databaseProvider));
  await preloadSettings(container);
  // Killed on a result screen? Open it again.
  try {
    final where = await resultLocationToRestore(
      container.read(settingsRepositoryProvider),
      GameRepository(container.read(databaseProvider)),
    );
    if (where != null) appRouter.go(where);
  } catch (_) {
    // a normal start is always fine
  }
  runApp(UncontrolledProviderScope(container: container, child: const KaartmaatApp()));
}
