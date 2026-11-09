import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'entitlement_service.dart';

/// What the store told us about the Pro product.
class ProProduct {
  const ProProduct({required this.id, required this.price});
  final String id;

  /// The price as the store formats it (for example "€ 3,99").
  final String price;
}

enum PurchaseKind { pending, purchased, restored, canceled, alreadyOwned, error }

/// One update from the store, in app terms. [handle] is whatever the gateway
/// needs to finish the purchase afterwards.
class PurchaseUpdate {
  const PurchaseUpdate(
    this.kind, {
    this.productId = proProductId,
    this.message,
    this.handle,
  });
  final PurchaseKind kind;
  final String productId;
  final String? message;
  final Object? handle;
}

/// The app's view on the store. The real one wraps `in_app_purchase`; the
/// tests use a fake. Nothing else in the app talks to the store.
abstract class PurchaseGateway {
  /// Updates for purchases, from the moment the app starts (also purchases
  /// that were interrupted when the app was closed).
  Stream<List<PurchaseUpdate>> get updates;

  /// The Pro product, or null when the store cannot be reached.
  Future<ProProduct?> loadProduct();

  /// Starts the purchase flow; false when it could not be started.
  Future<bool> buy();

  Future<void> restore();

  /// Tells the store the purchase has been delivered (required, or it is
  /// refunded / re-delivered).
  Future<void> complete(PurchaseUpdate update);
}

class StorePurchaseGateway implements PurchaseGateway {
  StorePurchaseGateway([InAppPurchase? iap]) : _injected = iap;
  final InAppPurchase? _injected;

  /// Looked up on first use: on platforms without a store (tests, desktop)
  /// the app still starts, everything just reports "store not available".
  InAppPurchase get _iap => _injected ?? InAppPurchase.instance;
  ProductDetails? _details;

  @override
  Stream<List<PurchaseUpdate>> get updates {
    try {
      return _iap.purchaseStream.map((list) => [for (final p in list) _map(p)]);
    } catch (_) {
      return const Stream.empty();
    }
  }

  PurchaseUpdate _map(PurchaseDetails p) {
    switch (p.status) {
      case PurchaseStatus.pending:
        return PurchaseUpdate(PurchaseKind.pending, productId: p.productID, handle: p);
      case PurchaseStatus.purchased:
        return PurchaseUpdate(PurchaseKind.purchased, productId: p.productID, handle: p);
      case PurchaseStatus.restored:
        return PurchaseUpdate(PurchaseKind.restored, productId: p.productID, handle: p);
      case PurchaseStatus.canceled:
        return PurchaseUpdate(PurchaseKind.canceled, productId: p.productID, handle: p);
      case PurchaseStatus.error:
        final code = '${p.error?.code}'.toLowerCase();
        return PurchaseUpdate(
          code.contains('owned')
              ? PurchaseKind.alreadyOwned
              : code.contains('cancel') || code.contains('usercanceled')
              ? PurchaseKind.canceled
              : PurchaseKind.error,
          productId: p.productID,
          message: p.error?.message,
          handle: p,
        );
    }
  }

  @override
  Future<ProProduct?> loadProduct() async {
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({proProductId});
      if (response.error != null || response.productDetails.isEmpty) return null;
      final d = _details = response.productDetails.first;
      return ProProduct(id: d.id, price: d.price);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> buy() async {
    final d = _details;
    if (d == null) return false;
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: d),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  @override
  Future<void> complete(PurchaseUpdate update) async {
    final h = update.handle;
    if (h is PurchaseDetails && h.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(h);
      } catch (_) {}
    }
  }
}
