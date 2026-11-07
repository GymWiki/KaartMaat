import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  // Load settings first so the saved theme applies from the first frame.
  await container.read(settingsProvider.future);
  runApp(UncontrolledProviderScope(container: container, child: const KaartmaatApp()));
}
