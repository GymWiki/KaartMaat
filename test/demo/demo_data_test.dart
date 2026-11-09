import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/demo/demo_data.dart';
import 'package:kaartmaat/features/games/data/game_repository.dart';
import 'package:kaartmaat/features/games/rules/rules_registry.dart';

Future<List<String>> _dump(AppDatabase db) async {
  final repo = GameRepository(db);
  final ids = [for (final g in await db.select(db.games).get()) g.id];
  return [
    for (final id in ids)
      () {
        return id;
      }().toString(),
    for (final r in await db.select(db.rounds).get()) r.entries,
    for (final p in await db.select(db.players).get()) p.name,
    '${(await repo.load(ids.first))!.rounds.length}',
  ];
}

void main() {
  final today = DateTime(2026, 11, 9);

  test('demo mode is off in tests (needs --dart-define=DEMO=true)', () {
    expect(demoModeEnabled, isFalse);
  });

  test('demo data is complete, valid and the same every run', () async {
    final a = AppDatabase(NativeDatabase.memory());
    final b = AppDatabase(NativeDatabase.memory());
    addTearDown(a.close);
    addTearDown(b.close);
    await seedDemoData(a, today: today);
    await seedDemoData(b, today: today);
    expect(await _dump(a), await _dump(b));

    final names = [for (final p in await a.select(a.players).get()) p.name];
    expect(names, ['Anna', 'Bram', 'Chantal', 'Daan', 'Eva', 'Joost', 'Lieke']);
    final groups = [for (final g in await a.select(a.groups).get()) g.name];
    expect(groups, ['Vrijdagavond', 'Familie']);

    final repo = GameRepository(a);
    var running = 0;
    var finished = 0;
    for (final row in await a.select(a.games).get()) {
      final state = (await repo.load(row.id))!;
      final rules = rulesFor(state.type);
      final complete = state.rounds.where(
        (r) =>
            !(state.type == 'boerenbridge' &&
                !state.isFinished &&
                r.number == state.rounds.length),
      );
      for (final r in complete) {
        expect(
          rules.validateRound(state.config, r),
          isNull,
          reason: '${state.type} round ${r.number}',
        );
      }
      state.isFinished ? finished++ : running++;
    }
    expect(running, 3);
    expect(finished, 8);

    final pro = await (a.select(
      a.appSettings,
    )..where((s) => s.key.equals('pro.debugOverride'))).getSingle();
    expect(pro.value, 'on');
  });
}
