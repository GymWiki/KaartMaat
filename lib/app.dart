import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/demo/demo_data.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/pro/purchase_controller.dart';
import 'features/settings/data/settings_repository.dart';

class KaartmaatApp extends ConsumerWidget {
  const KaartmaatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the store from the very start, so a purchase that was cut
    // short is finished when the app opens again.
    ref.read(purchaseControllerProvider);
    final choice = ref.watch(prefsProvider).themeChoice;
    return MaterialApp.router(
      debugShowCheckedModeBanner: !demoModeEnabled,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: choice == ThemeChoice.oled ? AppTheme.oled() : AppTheme.dark(),
      themeMode: switch (choice) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark || ThemeChoice.oled => ThemeMode.dark,
      },
      routerConfig: appRouter,
      locale: const Locale('nl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
