import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/providers.dart';
import '../../games/rules/game_rules.dart';

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

  /// Stores the default rule options for [type], used for new games.
  Future<void> setRuleOption(
    GameRules rules,
    Map<String, Object?> current,
    String key,
    Object? value,
  ) =>
      set('rules.${rules.type}', jsonEncode({...current, key: value}));
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

/// Light tap feedback, if enabled in settings.
void haptic(WidgetRef ref) {
  if (ref.read(prefsProvider).haptics) HapticFeedback.selectionClick();
}
