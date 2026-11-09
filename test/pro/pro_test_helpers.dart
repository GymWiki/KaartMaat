import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

/// A settings store in memory that announces changes like the database does.
class MemorySettings extends SettingsRepository {
  MemorySettings(AppDatabase db, [Map<String, String>? initial])
    : values = {...?initial},
      super(db);

  final Map<String, String> values;
  final _changes = StreamController<Map<String, String>>.broadcast();

  @override
  Stream<Map<String, String>> watchAll() async* {
    yield {...values};
    yield* _changes.stream;
  }

  @override
  Future<void> set(String key, String value) async {
    values[key] = value;
    _changes.add({...values});
  }

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
    _changes.add({...values});
  }
}

/// A container with settings in memory, listened to so values stay live.
ProviderContainer containerWith(
  MemorySettings settings, {
  List<Override> overrides = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settings),
      ...overrides,
    ],
  );
  c.listen(settingsProvider, (_, _) {});
  return c;
}

AppDatabase memoryDb() => AppDatabase(NativeDatabase.memory());

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));
