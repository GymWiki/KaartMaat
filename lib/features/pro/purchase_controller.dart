import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entitlement_service.dart';
import 'purchase_gateway.dart';

enum PurchasePhase { idle, purchasing, pending, restoring }

/// Something to tell the user once (the UI maps it to Dutch text).
enum PurchaseNotice { none, thanks, failed, pending, restoreNone }

class PurchaseState {
  const PurchaseState({
    this.product,
    this.loadingProduct = true,
    this.productFailed = false,
    this.phase = PurchasePhase.idle,
    this.notice = PurchaseNotice.none,
  });

  final ProProduct? product;
  final bool loadingProduct;
  final bool productFailed;
  final PurchasePhase phase;
  final PurchaseNotice notice;

  PurchaseState copyWith({
    ProProduct? product,
    bool? loadingProduct,
    bool? productFailed,
    PurchasePhase? phase,
    PurchaseNotice? notice,
  }) => PurchaseState(
    product: product ?? this.product,
    loadingProduct: loadingProduct ?? this.loadingProduct,
    productFailed: productFailed ?? this.productFailed,
    phase: phase ?? this.phase,
    notice: notice ?? this.notice,
  );
}

final purchaseGatewayProvider = Provider<PurchaseGateway>(
  (ref) => StorePurchaseGateway(),
);

/// Talks to the store through the gateway: loads the price, buys, restores,
/// and listens to the purchase stream from the moment the app starts, so a
/// purchase that was interrupted (app closed during payment) is finished the
/// next time the app opens.
class PurchaseController extends Notifier<PurchaseState> {
  StreamSubscription<List<PurchaseUpdate>>? _sub;

  /// How long a manual restore waits for the store before it says "nothing
  /// found".
  static Duration restoreWait = const Duration(seconds: 5);

  PurchaseGateway get _gateway => ref.read(purchaseGatewayProvider);
  EntitlementService get _entitlement =>
      ref.read(entitlementProvider.notifier);

  @override
  PurchaseState build() {
    _sub = _gateway.updates.listen(_onUpdates);
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(_startup);
    return const PurchaseState();
  }

  Future<void> _startup() async {
    await _entitlement.applyLegacyGrant();
    await loadProduct();
    // Android: ask Google Play what is owned (quiet). On iOS the purchase
    // stream delivers unfinished transactions by itself, and a restore asks
    // for the Apple ID, so it stays behind the "Aankopen herstellen" button.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _gateway.restore();
    }
  }

  Future<void> loadProduct() async {
    state = state.copyWith(loadingProduct: true, productFailed: false);
    final product = await _gateway.loadProduct();
    state = product == null
        ? state.copyWith(loadingProduct: false, productFailed: true)
        : state.copyWith(
            product: product,
            loadingProduct: false,
            productFailed: false,
          );
  }

  Future<void> buy() async {
    if (state.phase != PurchasePhase.idle || state.product == null) return;
    state = state.copyWith(phase: PurchasePhase.purchasing, notice: PurchaseNotice.none);
    if (!await _gateway.buy()) {
      state = state.copyWith(phase: PurchasePhase.idle, notice: PurchaseNotice.failed);
    }
  }

  Future<void> restore() async {
    if (state.phase == PurchasePhase.purchasing) return;
    state = state.copyWith(phase: PurchasePhase.restoring, notice: PurchaseNotice.none);
    await _gateway.restore();
    await Future<void>.delayed(restoreWait);
    if (state.phase == PurchasePhase.restoring) {
      state = state.copyWith(phase: PurchasePhase.idle, notice: PurchaseNotice.restoreNone);
    }
  }

  void clearNotice() => state = state.copyWith(notice: PurchaseNotice.none);

  Future<void> _onUpdates(List<PurchaseUpdate> updates) async {
    for (final u in updates) {
      await _handle(u);
    }
  }

  Future<void> _handle(PurchaseUpdate u) async {
    if (u.productId != proProductId) {
      await _gateway.complete(u);
      return;
    }
    // Only people who started this (button) get a message; a quiet purchase
    // or restore at startup just unlocks.
    final asked = state.phase != PurchasePhase.idle;
    switch (u.kind) {
      case PurchaseKind.pending:
        state = state.copyWith(
          phase: PurchasePhase.pending,
          notice: PurchaseNotice.pending,
        );
      case PurchaseKind.purchased:
      case PurchaseKind.restored:
        await _entitlement.grantPurchase();
        await _gateway.complete(u);
        state = state.copyWith(
          phase: PurchasePhase.idle,
          notice: asked ? PurchaseNotice.thanks : PurchaseNotice.none,
        );
      case PurchaseKind.canceled:
        await _gateway.complete(u);
        state = state.copyWith(phase: PurchasePhase.idle, notice: PurchaseNotice.none);
      case PurchaseKind.alreadyOwned:
        // bought before: restore it by itself
        state = state.copyWith(phase: PurchasePhase.restoring, notice: PurchaseNotice.none);
        await _gateway.restore();
      case PurchaseKind.error:
        await _gateway.complete(u);
        state = state.copyWith(
          phase: PurchasePhase.idle,
          notice: asked ? PurchaseNotice.failed : PurchaseNotice.none,
        );
    }
  }
}

final purchaseControllerProvider =
    NotifierProvider<PurchaseController, PurchaseState>(
      PurchaseController.new,
    );
