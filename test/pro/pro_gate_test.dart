import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/pro/entitlement_service.dart';
import 'package:kaartmaat/features/pro/pro_gate.dart';
import 'package:kaartmaat/features/pro/purchase_controller.dart';
import 'package:kaartmaat/features/pro/purchase_gateway.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';
import 'pro_test_helpers.dart';
import 'purchase_controller_test.dart' show FakeGateway;

void main() {
  late MemorySettings store;
  late FakeGateway gateway;

  Future<void> pumpGate(
    WidgetTester tester, {
    Map<String, String>? initial,
    bool storeOnline = true,
  }) async {
    usePhoneScreen(tester);
    final db = memoryDb();
    addTearDown(db.close);
    store = MemorySettings(db, initial);
    gateway = FakeGateway();
    if (!storeOnline) gateway.product = null;
    PurchaseController.restoreWait = Duration.zero;
    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          ref.read(purchaseControllerProvider); // the app does this at startup
          return const ProGate(
            preview: Text('VOORBEELD'),
            child: Text('ECHTE INHOUD'),
          );
        },
      ),
      overrides: [
        settingsRepositoryProvider.overrideWithValue(store),
        purchaseGatewayProvider.overrideWithValue(gateway),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('without Pro: the wall with price, "eenmalig" and both buttons', (
    tester,
  ) async {
    await pumpGate(tester);
    expect(find.text('Kaartmaat Pro'), findsOneWidget);
    expect(find.text('€ 3,99'), findsOneWidget, reason: 'the store price');
    expect(find.text('Eenmalig, geen abonnement'), findsOneWidget);
    expect(find.text('Ontgrendel Pro'), findsOneWidget);
    expect(find.text('Aankopen herstellen'), findsOneWidget);
    for (final f in [
      'Statistieken en de Kaartkoning van het jaar',
      'Historie van al je afgeronde spellen',
      'Spelersgroepen om snel te selecteren',
    ]) {
      expect(find.text(f), findsOneWidget);
    }
    expect(find.text('VOORBEELD'), findsOneWidget, reason: 'faded preview');
    expect(find.text('ECHTE INHOUD'), findsNothing);
  });

  testWidgets('with Pro: the real content and no wall', (tester) async {
    await pumpGate(tester, initial: {'pro.purchased': '1'});
    expect(find.text('ECHTE INHOUD'), findsOneWidget);
    expect(find.text('Kaartmaat Pro'), findsNothing);
    expect(find.text('Ontgrendel Pro'), findsNothing);
  });

  testWidgets('the preview cannot be tapped', (tester) async {
    await pumpGate(tester);
    expect(
      find.ancestor(
        of: find.text('VOORBEELD'),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });

  testWidgets('no product data: a friendly message and "Opnieuw proberen"', (
    tester,
  ) async {
    await pumpGate(tester, storeOnline: false);
    expect(
      find.textContaining('prijs kon niet worden opgehaald'),
      findsOneWidget,
    );
    expect(find.text('Opnieuw proberen'), findsOneWidget);
    final unlock = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(unlock.onPressed, isNull);
    gateway.product = const ProProduct(id: proProductId, price: '€ 3,99');
    await tester.tap(find.text('Opnieuw proberen'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('€ 3,99'), findsOneWidget);
  });

  testWidgets('buying: the wall closes at once, with a thank-you', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.tap(find.text('Ontgrendel Pro'));
    await tester.pump();
    expect(gateway.buys, 1);
    gateway.send(PurchaseKind.purchased);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ECHTE INHOUD'), findsOneWidget);
    expect(find.text('Kaartmaat Pro'), findsNothing);
    expect(find.text('Bedankt! Pro is ontgrendeld'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('cancelled: back on the wall, no error message', (tester) async {
    await pumpGate(tester);
    await tester.tap(find.text('Ontgrendel Pro'));
    await tester.pump();
    gateway.send(PurchaseKind.canceled);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ontgrendel Pro'), findsOneWidget);
    expect(find.textContaining('niet gelukt'), findsNothing);
    expect(find.text('ECHTE INHOUD'), findsNothing);
  });

  testWidgets('failed: a clear message, still locked', (tester) async {
    await pumpGate(tester);
    await tester.tap(find.text('Ontgrendel Pro'));
    await tester.pump();
    gateway.send(PurchaseKind.error);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('De aankoop is niet gelukt'), findsOneWidget);
    expect(find.text('ECHTE INHOUD'), findsNothing);
  });

  testWidgets(
    'pending: "Betaling in behandeling", unlocked only on confirmation',
    (tester) async {
      await pumpGate(tester);
      await tester.tap(find.text('Ontgrendel Pro'));
      await tester.pump();
      gateway.send(PurchaseKind.pending);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Betaling in behandeling'), findsOneWidget);
      expect(find.text('ECHTE INHOUD'), findsNothing);
      // the button cannot be used again while the payment is pending
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      gateway.send(PurchaseKind.purchased);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ECHTE INHOUD'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('"Aankopen herstellen" without a purchase says so', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.tap(find.text('Aankopen herstellen'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Er is geen eerdere aankoop gevonden bij dit account.'),
      findsOneWidget,
    );
    expect(find.text('ECHTE INHOUD'), findsNothing);
  });

  testWidgets('"Aankopen herstellen" with a purchase unlocks Pro', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.tap(find.text('Aankopen herstellen'));
    await tester.pump();
    gateway.send(PurchaseKind.restored);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ECHTE INHOUD'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
