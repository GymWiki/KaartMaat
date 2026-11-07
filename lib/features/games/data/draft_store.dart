import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/settings_repository.dart';

/// Keeps a half-filled input panel per game, so a phone call or a killed app
/// never costs the entry. Stored as JSON in the settings table under
/// `draft.<gameId>`; no schema change.
class DraftStore {
  DraftStore(this._settings);
  final SettingsRepository _settings;

  static String key(int gameId) => 'draft.$gameId';

  Future<Map<String, Object?>?> load(int gameId) async {
    final raw = await _settings.get(key(gameId));
    if (raw == null) return null;
    try {
      return Map<String, Object?>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null; // unreadable draft: start with an empty panel
    }
  }

  Future<void> save(int gameId, Map<String, Object?> draft) =>
      _settings.set(key(gameId), jsonEncode(draft));

  Future<void> clear(int gameId) => _settings.remove(key(gameId));
}

/// Saves a draft shortly after the last change, and right away on [flush]
/// (call it when the app goes to the background and when the panel closes).
class DraftSaver {
  DraftSaver(this.store, this.gameId, {this.delay = const Duration(milliseconds: 300)});

  final DraftStore store;
  final int gameId;
  final Duration delay;

  Timer? _timer;
  Map<String, Object?>? _pending;

  void schedule(Map<String, Object?> draft) {
    _pending = draft;
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    final pending = _pending;
    _pending = null;
    if (pending != null) await store.save(gameId, pending);
  }

  /// The round was confirmed or cancelled: forget the draft.
  Future<void> discard() async {
    _timer?.cancel();
    _pending = null;
    await store.clear(gameId);
  }

  void dispose() => _timer?.cancel();
}

final draftStoreProvider =
    Provider((ref) => DraftStore(ref.watch(settingsRepositoryProvider)));
