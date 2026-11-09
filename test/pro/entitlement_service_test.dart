import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/pro/entitlement_service.dart';

import 'pro_test_helpers.dart';

void main() {
  late MemorySettings store;
  setUp(() async {
    final db = memoryDb();
    addTearDown(db.close);
    store = MemorySettings(db);
  });

  test('free by default; the product id is fixed', () async {
    final c = containerWith(store);
    addTearDown(c.dispose);
    await settle();
    expect(c.read(entitlementProvider), isFalse);
    expect(proProductId, 'kaartmaat_pro');
  });

  test(
    'a purchase makes the user Pro at once, and it is stored locally',
    () async {
      final c = containerWith(store);
      addTearDown(c.dispose);
      await settle();
      await c.read(entitlementProvider.notifier).grantPurchase();
      await settle();
      expect(c.read(entitlementProvider), isTrue);
      expect(store.values['pro.purchased'], '1');
    },
  );

  test(
    'offline after a purchase: a fresh start is still Pro (nothing asks the store)',
    () async {
      final first = containerWith(store);
      await settle();
      await first.read(entitlementProvider.notifier).grantPurchase();
      first.dispose();
      // app restarted with no connection: only the local store is read
      final second = containerWith(store);
      addTearDown(second.dispose);
      await settle();
      expect(second.read(entitlementProvider), isTrue);
    },
  );

  test('restoring a purchase is the same as buying: Pro stays on', () async {
    final c = containerWith(store);
    addTearDown(c.dispose);
    await settle();
    await c.read(entitlementProvider.notifier).grantPurchase();
    await c
        .read(entitlementProvider.notifier)
        .grantPurchase(); // twice: harmless
    await settle();
    expect(c.read(entitlementProvider), isTrue);
  });

  group('debug switch', () {
    test(
      'on gives Pro without a purchase, off hides it, auto follows the purchase',
      () async {
        final c = containerWith(store);
        addTearDown(c.dispose);
        await settle();
        final service = c.read(entitlementProvider.notifier);
        await service.setOverride(ProOverride.on);
        await settle();
        expect(c.read(entitlementProvider), isTrue);
        await service.grantPurchase();
        await service.setOverride(ProOverride.off);
        await settle();
        expect(c.read(entitlementProvider), isFalse);
        await service.setOverride(ProOverride.auto);
        await settle();
        expect(c.read(entitlementProvider), isTrue, reason: 'purchased');
        expect(store.values.containsKey('pro.debugOverride'), isFalse);
      },
    );

    test('the override never counts in a release build', () {
      for (final o in ProOverride.values) {
        expect(
          EntitlementService.isProFrom(
            purchased: false,
            override: o,
            debug: false,
          ),
          isFalse,
          reason: '$o',
        );
        expect(
          EntitlementService.isProFrom(
            purchased: true,
            override: o,
            debug: false,
          ),
          isTrue,
          reason: '$o',
        );
      }
    });
  });

  test('the legacy grant hook is empty: nobody gets Pro for free', () async {
    final c = containerWith(store);
    addTearDown(c.dispose);
    await settle();
    final service = c.read(entitlementProvider.notifier);
    expect(await service.legacyUserGrant(), isFalse);
    await service.applyLegacyGrant();
    await settle();
    expect(c.read(entitlementProvider), isFalse);
  });
}
