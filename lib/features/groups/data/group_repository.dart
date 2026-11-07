import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../core/db/providers.dart';

/// A saved card group ("vast kaartgroepje"): a name and its members in order.
class GroupRef {
  const GroupRef({required this.id, required this.name, required this.memberIds});
  final int id;
  final String name;
  final List<int> memberIds;
}

class GroupRepository {
  GroupRepository(this.db);
  final AppDatabase db;

  Stream<List<GroupRef>> watch() => db
      .customSelect('SELECT 1',
          readsFrom: {db.groups, db.groupMembers, db.players})
      .watch()
      .asyncMap((_) => _load());

  Future<List<GroupRef>> _load() async {
    final groups = await (db.select(db.groups)
          ..orderBy([(g) => OrderingTerm.asc(g.name.lower())]))
        .get();
    final members = await (db.select(db.groupMembers).join([
      innerJoin(db.players, db.players.id.equalsExp(db.groupMembers.playerId)),
    ])
          ..where(db.players.deletedAt.isNull())
          ..orderBy([OrderingTerm.asc(db.groupMembers.position)]))
        .get();
    return [
      for (final g in groups)
        GroupRef(
          id: g.id,
          name: g.name,
          memberIds: [
            for (final m in members)
              if (m.readTable(db.groupMembers).groupId == g.id)
                m.readTable(db.groupMembers).playerId,
          ],
        ),
    ];
  }

  /// Creates a group, or updates it when [id] is given.
  Future<int> save({int? id, required String name, required List<int> memberIds}) =>
      db.transaction(() async {
        final trimmed = name.trim();
        final groupId = id ??
            await db.into(db.groups).insert(GroupsCompanion.insert(name: trimmed));
        if (id != null) {
          await (db.update(db.groups)..where((g) => g.id.equals(id)))
              .write(GroupsCompanion(name: Value(trimmed)));
          await (db.delete(db.groupMembers)..where((m) => m.groupId.equals(id))).go();
        }
        for (var i = 0; i < memberIds.length; i++) {
          await db.into(db.groupMembers).insert(GroupMembersCompanion.insert(
                groupId: groupId,
                playerId: memberIds[i],
                position: Value(i),
              ));
        }
        return groupId;
      });

  Future<void> delete(int id) => db.transaction(() async {
        await (db.delete(db.groupMembers)..where((m) => m.groupId.equals(id))).go();
        await (db.update(db.games)..where((g) => g.groupId.equals(id)))
            .write(const GamesCompanion(groupId: Value(null)));
        await (db.delete(db.groups)..where((g) => g.id.equals(id))).go();
      });
}

final groupRepositoryProvider =
    Provider((ref) => GroupRepository(ref.watch(databaseProvider)));

final groupsProvider = StreamProvider<List<GroupRef>>(
    (ref) => ref.watch(groupRepositoryProvider).watch());
