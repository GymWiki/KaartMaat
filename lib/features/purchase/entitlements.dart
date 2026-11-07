import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'purchase_service.dart';

/// The ONLY place that looks at isUnlocked. Gate features through this.
class Entitlements {
  const Entitlements(this.isUnlocked);
  final bool isUnlocked;

  static const freeHistoryLimit = 5;

  bool canPlay({required bool isFreeGame}) => isUnlocked || isFreeGame;
  int? get historyLimit => isUnlocked ? null : freeHistoryLimit;
  bool get canViewStats => isUnlocked;
  bool get canShare => isUnlocked;
}

final entitlementsProvider = Provider(
    (ref) => Entitlements(ref.watch(isUnlockedProvider).value ?? false));
