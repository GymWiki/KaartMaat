import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/providers.dart';
import 'package:kaartmaat/features/pro/purchase_controller.dart';
import 'package:kaartmaat/core/l10n/gen/app_localizations.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';
import 'package:kaartmaat/features/settings/ui/game_settings_screen.dart';
import 'package:kaartmaat/features/settings/ui/settings_screen.dart';
import 'package:kaartmaat/features/settings/ui/settings_editor.dart' show settingLabel;
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers.dart';
import '../pro/pro_test_helpers.dart';
import '../pro/purchase_controller_test.dart' show FakeGateway;

void main() {
  late MemorySettings store;

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Map<String, String>? initial,
    double textScale = 1,
  }) async {
    usePhoneScreen(tester);
    PackageInfo.setMockInitialValues(
      appName: 'Kaartmaat',
      packageName: 'nl.kaartmaat.kaartmaat',
      version: '1.0.0',
      buildNumber: '4',
      buildSignature: '',
    );
    final db = memoryDb();
    addTearDown(db.close);
    store = MemorySettings(db, initial);
    PurchaseController.restoreWait = Duration.zero;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
      scaffold: false,
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(store),
        purchaseGatewayProvider.overrideWithValue(FakeGateway()),
      ],
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapScrolled(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  group('Instellingen (hoofdscherm)', () {
    testWidgets('free: Pro card with price, buy and restore', (tester) async {
      await pump(tester, const SettingsScreen());
      expect(find.text('Kaartmaat Pro'), findsOneWidget);
      expect(find.textContaining('€ 3,99'), findsOneWidget);
      expect(find.text('Ontgrendel Pro'), findsOneWidget);
      expect(find.text('Aankopen herstellen'), findsOneWidget);
      expect(find.text('Pro actief. Bedankt voor je steun.'), findsNothing);
      expect(find.text('Spelinstellingen'), findsOneWidget);
      expect(find.text('Spelregels per spel instellen'), findsOneWidget);
    });

    testWidgets('Pro: the card says Pro is active, no buy buttons', (
      tester,
    ) async {
      await pump(
        tester,
        const SettingsScreen(),
        initial: {'pro.purchased': '1'},
      );
      expect(find.text('Pro actief. Bedankt voor je steun.'), findsOneWidget);
      expect(find.text('Ontgrendel Pro'), findsNothing);
      expect(find.text('Aankopen herstellen'), findsNothing);
    });

    testWidgets('sections: display, about, data', (tester) async {
      await pump(tester, const SettingsScreen());
      for (final t in [
        'Weergave en gebruik',
        'Thema',
        'Trillen bij invoer',
        'Scherm standaard aan tijdens spel',
        'Over Kaartmaat',
        'Privacyverklaring',
        'Gebruiksvoorwaarden',
        'Contact',
        'Gegevens',
        'Alle gegevens wissen',
      ]) {
        await tester.scrollUntilVisible(
          find.text(t),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(t), findsWidgets, reason: t);
      }
      await tester.scrollUntilVisible(
        find.text('1.0.0 (4)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    });

    testWidgets('the developer section only exists when asked for', (
      tester,
    ) async {
      await pump(tester, const SettingsScreen(showDeveloper: false));
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('Ontwikkelaar'), findsNothing);
      expect(find.text('Pro forceren (alleen debug)'), findsNothing);
    });

    testWidgets('developer section shows the Pro override', (tester) async {
      await pump(tester, const SettingsScreen(showDeveloper: true));
      await tester.scrollUntilVisible(
        find.text('Pro forceren (alleen debug)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ontwikkelaar'), findsOneWidget);
      expect(find.text('Automatisch'), findsOneWidget);
    });

    testWidgets('"Alle gegevens wissen" asks first and says it is final', (
      tester,
    ) async {
      await pump(tester, const SettingsScreen());
      await tapScrolled(tester, find.text('Alle gegevens wissen'));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Dit kan niet ongedaan worden gemaakt'),
          findsOneWidget);
      // cancel: nothing happens
      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();
      expect(find.text('Alle gegevens zijn gewist'), findsNothing);
      // confirm: wiped
      await tapScrolled(tester, find.text('Alle gegevens wissen'));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Alle gegevens wissen'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alle gegevens zijn gewist'), findsOneWidget);
    });

    for (final scale in [1.5, 2.0]) {
      testWidgets('text scale $scale: no overflow', (tester) async {
        await pump(tester, const SettingsScreen(showDeveloper: true), textScale: scale);
        await tester.drag(find.byType(ListView), const Offset(0, -4000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Spelinstellingen (accordeon)', () {
    const summaries = [
      '10 basis, 5 per slag, 5 straf',
      'Amsterdams · 16 giffen',
      '5 per slag, slem 35',
      '26 strafpunten, doel 100',
      'Uitvallen bij 10 punten',
      '10 rondes, laagste wint',
      'Doel 5000, canasta 500/300',
      'Doel 1000',
      'Optellen, stap 1',
    ];

    testWidgets('every game has a panel with its summary, all closed', (
      tester,
    ) async {
      await pump(tester, const GameSettingsScreen());
      expect(
        find.textContaining('standaardwaarden voor nieuwe spellen'),
        findsOneWidget,
      );
      for (final s in summaries) {
        await tester.scrollUntilVisible(
          find.text(s),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text('Standaardwaarden herstellen'), findsNothing);
    });

    testWidgets('a summary follows the stored values', (tester) async {
      await pump(
        tester,
        const GameSettingsScreen(),
        initial: {
          'rules.boerenbridge': jsonEncode({'exactBase': 20}),
          'rules.klaverjassen': jsonEncode({'variant': 'gronings'}),
        },
      );
      expect(find.text('20 basis, 5 per slag, 5 straf'), findsOneWidget);
      expect(find.text('Gronings · 16 giffen'), findsOneWidget);
    });

    testWidgets('opens and closes, one panel at a time', (tester) async {
      await pump(tester, const GameSettingsScreen());
      expect(find.text('Bieden mag niet kloppen'), findsNothing);

      await tester.tap(find.text('Boerenbridge'));
      await tester.pumpAndSettle();
      expect(find.text('Bieden mag niet kloppen'), findsOneWidget);
      expect(find.text('Standaardwaarden herstellen'), findsOneWidget);

      // opening another one closes the first
      await tester.tap(find.text('Klaverjassen'));
      await tester.pumpAndSettle();
      expect(find.text('Bieden mag niet kloppen'), findsNothing);
      expect(find.text('Variant'), findsOneWidget);
      expect(find.text('Standaardwaarden herstellen'), findsOneWidget);

      // tapping it again closes it
      await tester.tap(find.text('Klaverjassen'));
      await tester.pumpAndSettle();
      expect(find.text('Variant'), findsNothing);
      expect(find.text('Standaardwaarden herstellen'), findsNothing);
    });

    testWidgets('nothing got lost: every visible setting of every game is in its panel', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('nl'));
      await pump(tester, const GameSettingsScreen());
      var games = 0;
      for (final def in gameDefinitions.values) {
        final specs = def.rules.settingSpecs;
        if (specs.isEmpty) continue;
        games++;
        final header = find.text(def.name(l10n));
        await tester.scrollUntilVisible(
          header,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(header);
        await tester.pumpAndSettle();
        final defaults = def.rules.defaultSettings;
        for (final s in specs) {
          if (s.visibleIf != null &&
              defaults[s.visibleIf!.$1] != s.visibleIf!.$2) {
            continue;
          }
          expect(
            find.text(settingLabel(l10n, s.key), skipOffstage: false),
            findsWidgets,
            reason: '${def.rules.type}: ${s.key}',
          );
        }
      }
      expect(games, 9);
    });

    testWidgets('the header tells the screen reader it is expanded', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const GameSettingsScreen());
      final header = find.ancestor(
        of: find.text('Boerenbridge'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.expanded != null,
        ),
      );
      expect((tester.widget(header.first) as Semantics).properties.expanded,
          isFalse);
      await tester.tap(find.text('Boerenbridge'));
      await tester.pumpAndSettle();
      expect((tester.widget(header.first) as Semantics).properties.expanded,
          isTrue);
      handle.dispose();
    });

    testWidgets('changing a setting stores the same value as before', (
      tester,
    ) async {
      await pump(tester, const GameSettingsScreen());
      await tester.tap(find.text('Boerenbridge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bieden mag niet kloppen'));
      await tester.pumpAndSettle();
      final stored = jsonDecode(store.values['rules.boerenbridge']!) as Map;
      expect(stored['dealerRestriction'], false);
      expect(stored['exactBase'], 10, reason: 'the rest is kept');
    });

    testWidgets('"Standaardwaarden herstellen" resets only that game, with undo', (
      tester,
    ) async {
      await pump(
        tester,
        const GameSettingsScreen(),
        initial: {
          'rules.boerenbridge': jsonEncode({'exactBase': 20}),
          'rules.toepen': jsonEncode({'limit': 15}),
        },
      );
      await tester.tap(find.text('Boerenbridge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Standaardwaarden herstellen'));
      await tester.pumpAndSettle();

      expect(store.values.containsKey('rules.boerenbridge'), isFalse);
      expect(store.values['rules.toepen'], contains('15'), reason: 'other game');
      expect(find.text('10 basis, 5 per slag, 5 straf'), findsOneWidget);
      expect(find.text('Standaardwaarden hersteld'), findsOneWidget);

      await tester.tap(find.text('Ongedaan maken'));
      await tester.pumpAndSettle();
      expect(jsonDecode(store.values['rules.boerenbridge']!)['exactBase'], 20);
      expect(find.text('20 basis, 5 per slag, 5 straf'), findsOneWidget);
    });

    testWidgets('restore is off while a game is at its defaults', (tester) async {
      await pump(tester, const GameSettingsScreen());
      await tester.tap(find.text('Boerenbridge'));
      await tester.pumpAndSettle();
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Standaardwaarden herstellen'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Algemene teller: input mode first, step only for "Optellen"', (
      tester,
    ) async {
      await pump(tester, const GameSettingsScreen());
      await tapScrolled(tester, find.text('Algemene teller'));
      expect(find.text('Invoermethode'), findsOneWidget);
      expect(find.text('Stap van de plus- en min-knoppen'), findsOneWidget);
      await tester.tap(find.text('Invullen').last);
      await tester.pumpAndSettle();
      expect(find.text('Stap van de plus- en min-knoppen'), findsNothing);
    });

    testWidgets('the panel remembers which one was open', (tester) async {
      await pump(tester, const GameSettingsScreen());
      await tester.tap(find.text('Boerenbridge'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GameSettingsScreen)),
      );
      expect(container.read(openGamePanelProvider), 'boerenbridge');
    });

    for (final scale in [1.5, 2.0]) {
      testWidgets('text scale $scale: panels and open panel do not overflow', (
        tester,
      ) async {
        await pump(tester, const GameSettingsScreen(), textScale: scale);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Boerenbridge'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
