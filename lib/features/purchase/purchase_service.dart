import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plug the real in-app purchase in here later (same interface).
abstract class PurchaseService {
  bool get isUnlocked;
  Stream<bool> get unlockedChanges;

  /// Localized price label shown on the unlock sheet.
  String get priceLabel;

  /// Returns true when the user ends up unlocked.
  Future<bool> purchase();
  Future<bool> restore();
}

class FakePurchaseService implements PurchaseService {
  final _controller = StreamController<bool>.broadcast();
  bool _unlocked = false;

  @override
  bool get isUnlocked => _unlocked;

  @override
  Stream<bool> get unlockedChanges => _controller.stream;

  @override
  String get priceLabel => '€ 1,99';

  /// Debug switch (settings screen, debug builds only).
  void setUnlocked(bool value) {
    _unlocked = value;
    _controller.add(value);
  }

  @override
  Future<bool> purchase() async {
    setUnlocked(true);
    return true;
  }

  @override
  Future<bool> restore() async => _unlocked;
}

final purchaseServiceProvider =
    Provider<PurchaseService>((ref) => FakePurchaseService());

final isUnlockedProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(purchaseServiceProvider);
  yield service.isUnlocked;
  yield* service.unlockedChanges;
});
