import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a game is open. Behind a provider so tests can
/// see what was asked of it.
class WakelockController {
  const WakelockController();

  Future<void> set(bool on) async {
    try {
      if (on) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // no wakelock support (tests, desktop): the game still works
    }
  }
}

final wakelockProvider = Provider((ref) => const WakelockController());
