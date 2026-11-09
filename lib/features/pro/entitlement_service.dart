import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/data/settings_repository.dart';

/// The one non-consumable product that unlocks everything in Pro.
const proProductId = 'kaartmaat_pro';

const _purchasedKey = 'pro.purchased';
const _overrideKey = 'pro.debugOverride';

/// Debug builds only: force Pro on or off to test without a real purchase.
enum ProOverride { auto, on, off }

/// The single source of truth for "is this a Pro user". Every Pro check in
/// the app goes through this service (`ref.watch(entitlementProvider)` is the
/// bool), never through the store directly.
///
/// The status is kept locally, so the app works offline. It is only ever
/// switched ON here (a purchase, or a purchase restored from the store): a
/// failed or missing connection to the store never takes Pro away.
class EntitlementService extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(prefsProvider);
    return isProFrom(
      purchased: prefs.proPurchased,
      override: prefs.proOverride,
      debug: kDebugMode,
    );
  }

  /// Pure rule, also used by the tests. The override only counts in debug
  /// builds.
  static bool isProFrom({
    required bool purchased,
    required ProOverride override,
    required bool debug,
  }) {
    if (debug) {
      if (override == ProOverride.on) return true;
      if (override == ProOverride.off) return false;
    }
    return purchased;
  }

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  /// A purchase went through (or was restored): remember it for good.
  Future<void> grantPurchase() => _repo.set(_purchasedKey, '1');

  /// Debug switch under Instellingen.
  Future<void> setOverride(ProOverride value) => value == ProOverride.auto
      ? _repo.remove(_overrideKey)
      : _repo.set(_overrideKey, value.name);

  /// Hook to give people who already used the app before Pro existed Pro for
  /// free. Deliberately empty: fill it in only once a version of the app has
  /// been published to the stores (for example: "has games stored from before
  /// the Pro release"). Returns true when the user was granted Pro.
  Future<bool> legacyUserGrant() async => false;

  /// Run at startup: apply the legacy grant if there is one.
  Future<void> applyLegacyGrant() async {
    if (state) return;
    if (await legacyUserGrant()) await grantPurchase();
  }
}

final entitlementProvider = NotifierProvider<EntitlementService, bool>(
  EntitlementService.new,
);
