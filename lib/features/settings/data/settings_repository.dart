import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/providers.dart';
import '../../games/rules/game_rules.dart';
import '../../pro/entitlement_service.dart' show ProOverride;

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDatabase db;

  Stream<Map<String, String>> watchAll() => db
      .select(db.appSettings)
      .watch()
      .map((rows) => {for (final r in rows) r.key: r.value});

  Future<void> set(String key, String value) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<String?> get(String key) async {
    final row = await (db.select(db.appSettings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> remove(String key) =>
      (db.delete(db.appSettings)..where((s) => s.key.equals(key))).go();

  /// Stores the default rule options for [type], used for new games.
  Future<void> setRuleOption(
    GameRules rules,
    Map<String, Object?> current,
    String key,
    Object? value,
  ) =>
      set('rules.${rules.type}', jsonEncode({...current, key: value}));

  /// Puts the default rule options of one game back (other games stay as
  /// they are). Returns what was stored before, to hand to [restoreRuleOptions]
  /// for an undo.
  Future<String?> resetRuleOptions(GameRules rules) async {
    final previous = await get('rules.${rules.type}');
    await remove('rules.${rules.type}');
    return previous;
  }

  /// Undo of [resetRuleOptions].
  Future<void> restoreRuleOptions(GameRules rules, String? previous) =>
      previous == null ? remove('rules.${rules.type}') : set('rules.${rules.type}', previous);
}

enum ThemeChoice { system, light, dark, oled }

/// Typed view over the raw key/value settings.
class AppPrefs {
  const AppPrefs(this._values);
  final Map<String, String> _values;

  ThemeChoice get themeChoice => ThemeChoice.values.firstWhere(
        (c) => c.name == _values['theme'],
        orElse: () => ThemeChoice.system,
      );

  bool get haptics => _values['haptics'] != '0';

  /// Pro was bought (kept locally so it works offline).
  bool get proPurchased => _values['pro.purchased'] == '1';

  /// Debug-only override of the Pro status.
  ProOverride get proOverride => ProOverride.values.firstWhere(
    (o) => o.name == _values['pro.debugOverride'],
    orElse: () => ProOverride.auto,
  );

  /// Start every game with the screen kept on (off unless chosen).
  bool get keepAwakeByDefault => _values['keepAwake'] == '1';

  Map<String, Object?> ruleOptions(GameRules rules) {
    final stored = _values['rules.${rules.type}'];
    return {
      ...rules.defaultSettings,
      if (stored != null) ...Map<String, Object?>.from(jsonDecode(stored) as Map),
    };
  }
}

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

final settingsProvider = StreamProvider<Map<String, String>>(
    (ref) => ref.watch(settingsRepositoryProvider).watchAll());

final prefsProvider =
    Provider((ref) => AppPrefs(ref.watch(settingsProvider).value ?? const {}));

/// Loads the settings before the first frame so the saved theme applies at
/// once. Riverpod 3 pauses providers nobody listens to, so a plain `read`
/// would never get the database's first value: listen, then wait. If loading
/// fails or hangs, the app starts with the defaults.
Future<void> preloadSettings(ProviderContainer container) async {
  container.listen(settingsProvider, (_, _) {});
  try {
    await container
        .read(settingsProvider.future)
        .timeout(const Duration(seconds: 8));
  } catch (error, stack) {
    debugPrint('Instellingen laden mislukt: $error\n$stack');
  }
}

/// Light tap feedback, if enabled in settings.
void haptic(WidgetRef ref) {
  if (ref.read(prefsProvider).haptics) HapticFeedback.selectionClick();
}
