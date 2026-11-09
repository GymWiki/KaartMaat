import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/pro/entitlement_service.dart';
import 'package:kaartmaat/features/pro/purchase_controller.dart';
import 'package:kaartmaat/features/pro/purchase_gateway.dart';

import 'pro_test_helpers.dart';

class FakeGateway implements PurchaseGateway {
  final stream = StreamController<List<PurchaseUpdate>>.broadcast();
  ProProduct? product = const ProProduct(id: proProductId, price: '€ 3,99');
  bool canBuy = true;
  int buys = 0;
  int restores = 0;
  final completed = <PurchaseKind>[];

  @override
  Stream<List<PurchaseUpdate>> get updates => stream.stream;
  @override
  Future<ProProduct?> loadProduct() async => product;
  @override
  Future<bool> buy() async {
    buys++;
    return canBuy;
  }

  @override
  Future<void> restore() async => restores++;
  @override
  Future<void> complete(PurchaseUpdate update) async =>
      completed.add(update.kind);

  void send(PurchaseKind kind, {String id = proProductId}) =>
      stream.add([PurchaseUpdate(kind, productId: id)]);
}

void main() {
  late MemorySettings store;
  late FakeGateway gateway;
  late dynamic container;

  Future<void> start({Map<String, String>? initial}) async {
    final db = memoryDb();
    addTearDown(db.close);
    store = MemorySettings(db, initial);
    gateway = FakeGateway();
    PurchaseController.restoreWait = Duration.zero;
    container = containerWith(
      store,
      overrides: [purchaseGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    container.read(purchaseControllerProvider); // the app does this at startup
    await settle();
  }

  PurchaseState state() => container.read(purchaseControllerProvider);
  bool pro() => container.read(entitlementProvider);

  test('the price comes from the store', () async {
    await start();
    expect(state().product!.price, '€ 3,99');
    expect(state().loadingProduct, isFalse);
    expect(state().productFailed, isFalse);
  });

  test(
    'no product data: failure state, and "Opnieuw proberen" works',
    () async {
      await start();
      gateway.product = null;
      await container.read(purchaseControllerProvider.notifier).loadProduct();
      expect(state().productFailed, isTrue);
      gateway.product = const ProProduct(id: proProductId, price: '€ 3,99');
      await container.read(purchaseControllerProvider.notifier).loadProduct();
      expect(state().productFailed, isFalse);
      expect(state().product, isNotNull);
    },
  );

  test(
    'a successful purchase unlocks Pro, is completed, and says thanks',
    () async {
      await start();
      await container.read(purchaseControllerProvider.notifier).buy();
      expect(gateway.buys, 1);
      expect(state().phase, PurchasePhase.purchasing);
      gateway.send(PurchaseKind.purchased);
      await settle();
      expect(pro(), isTrue);
      expect(gateway.completed, [PurchaseKind.purchased]);
      expect(state().phase, PurchasePhase.idle);
      expect(state().notice, PurchaseNotice.thanks);
    },
  );

  test('cancelled: back to normal, no error message, not Pro', () async {
    await start();
    await container.read(purchaseControllerProvider.notifier).buy();
    gateway.send(PurchaseKind.canceled);
    await settle();
    expect(pro(), isFalse);
    expect(state().phase, PurchasePhase.idle);
    expect(state().notice, PurchaseNotice.none);
  });

  test('failed: a message, not Pro', () async {
    await start();
    await container.read(purchaseControllerProvider.notifier).buy();
    gateway.send(PurchaseKind.error);
    await settle();
    expect(pro(), isFalse);
    expect(state().notice, PurchaseNotice.failed);
    expect(state().phase, PurchasePhase.idle);
  });

  test('the purchase flow cannot even start: failed message', () async {
    await start();
    gateway.canBuy = false;
    await container.read(purchaseControllerProvider.notifier).buy();
    expect(state().notice, PurchaseNotice.failed);
    expect(state().phase, PurchasePhase.idle);
  });

  test(
    'pending payment: "in behandeling", unlocked only when confirmed',
    () async {
      await start();
      await container.read(purchaseControllerProvider.notifier).buy();
      gateway.send(PurchaseKind.pending);
      await settle();
      expect(pro(), isFalse);
      expect(state().phase, PurchasePhase.pending);
      expect(state().notice, PurchaseNotice.pending);
      // a second tap while pending does not start another purchase
      await container.read(purchaseControllerProvider.notifier).buy();
      expect(gateway.buys, 1);
      gateway.send(PurchaseKind.purchased);
      await settle();
      expect(pro(), isTrue);
      expect(state().notice, PurchaseNotice.thanks);
    },
  );

  test('already owned: it is restored by itself', () async {
    await start();
    await container.read(purchaseControllerProvider.notifier).buy();
    gateway.send(PurchaseKind.alreadyOwned);
    await settle();
    expect(gateway.restores, greaterThanOrEqualTo(1));
    gateway.send(PurchaseKind.restored);
    await settle();
    expect(pro(), isTrue);
  });

  test('"Aankopen herstellen" with a purchase brings Pro back', () async {
    await start();
    final restoring = container
        .read(purchaseControllerProvider.notifier)
        .restore();
    await settle();
    gateway.send(PurchaseKind.restored);
    await restoring;
    await settle();
    expect(pro(), isTrue);
  });

  test('"Aankopen herstellen" without any purchase says so', () async {
    await start();
    await container.read(purchaseControllerProvider.notifier).restore();
    expect(pro(), isFalse);
    expect(state().notice, PurchaseNotice.restoreNone);
    expect(state().phase, PurchasePhase.idle);
  });

  test(
    'a purchase that was interrupted by closing the app is finished at the next start',
    () async {
      await start();
      // nobody pressed anything this session: the store replays the purchase
      gateway.send(PurchaseKind.purchased);
      await settle();
      expect(pro(), isTrue);
      expect(gateway.completed, [PurchaseKind.purchased]);
      expect(state().notice, PurchaseNotice.none, reason: 'quiet unlock');
    },
  );

  test(
    'offline at startup: earlier Pro stays Pro, nothing is taken away',
    () async {
      await start(initial: {'pro.purchased': '1'});
      gateway.product = null;
      await container.read(purchaseControllerProvider.notifier).loadProduct();
      expect(state().productFailed, isTrue);
      await container.read(purchaseControllerProvider.notifier).restore();
      expect(pro(), isTrue, reason: 'a failed connection never removes Pro');
    },
  );

  test('a purchase of some other product does not unlock Pro', () async {
    await start();
    gateway.send(PurchaseKind.purchased, id: 'something_else');
    await settle();
    expect(pro(), isFalse);
  });
}
