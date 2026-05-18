import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/entities/mood_entry.dart';
import '../domain/entities/tag.dart';
import '../domain/repositories/entry_query.dart';
import '../domain/repositories/mood_entry_repository.dart';
import 'mappers/mood_entry_mapper.dart';

class MoodEntryRepositoryImpl implements MoodEntryRepository {
  MoodEntryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async {
    try {
      await _db.transaction(() async {
        await _db.into(_db.entries).insert(entityToRow(entry));
        await _upsertTags(entry.tags);
        await _replaceEntryTags(entry.id, entry.tags);
      });
      return (entry, null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async {
    try {
      await _db.transaction(() async {
        await (_db.update(_db.entries)..where((t) => t.id.equals(entry.id)))
            .write(_entryCompanion(entry, isInsert: false));
        await _upsertTags(entry.tags);
        await _replaceEntryTags(entry.id, entry.tags);
      });
      return (entry, null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<(Unit?, Failure?)> delete(String id) async {
    try {
      final removed = await (_db.delete(_db.entries)
            ..where((t) => t.id.equals(id)))
          .go();
      if (removed == 0) return (null, NotFoundFailure(id: id));
      return (Unit.value, null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async {
    try {
      final row = await (_db.select(_db.entries)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) return (null, NotFoundFailure(id: id));
      final tags = await _tagsForEntry(id);
      return (rowToEntity(row, tags: tags), null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) {
    final select = _db.select(_db.entries)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    if (query != null) _applyQuery(select, query);
    if (query?.limit != null) select.limit(query!.limit!);
    return select.watch().asyncMap(_hydrate);
  }

  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async {
    try {
      final select = _db.select(_db.entries)
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
      if (query != null) _applyQuery(select, query);
      if (query?.limit != null) select.limit(query!.limit!);
      final rows = await select.get();
      return (await _hydrate(rows), null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  void _applyQuery(
    SimpleSelectStatement<$EntriesTable, EntryRow> select,
    EntryQuery query,
  ) {
    final r = query.dateRange;
    if (r != null) {
      select.where((t) => t.occurredAt.isBetweenValues(
            r.start.millisecondsSinceEpoch,
            r.end.millisecondsSinceEpoch,
          ));
    }
    final m = query.moodRange;
    if (m != null) {
      select.where((t) => t.mood.isBetweenValues(m.min.index, m.max.index));
    }
    final t = query.tagIds;
    if (t != null && t.isNotEmpty) {
      final sub = _db.selectOnly(_db.entryTags)
        ..addColumns([_db.entryTags.entryId])
        ..where(_db.entryTags.tagId.isIn(t));
      select.where((row) => row.id.isInQuery(sub));
    }
    final text = query.text;
    if (text != null && text.isNotEmpty) {
      select.where((row) => row.note.like('%$text%'));
    }
  }

  Future<List<MoodEntry>> _hydrate(List<EntryRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final joinRows = await (_db.select(_db.entryTags)
          ..where((t) => t.entryId.isIn(ids)))
        .get();
    final tagIds = joinRows.map((j) => j.tagId).toSet();
    final tagRows = tagIds.isEmpty
        ? const <TagRow>[]
        : await (_db.select(_db.tags)..where((t) => t.id.isIn(tagIds))).get();
    final tagsById = {for (final t in tagRows) t.id: rowToTag(t)};
    final tagsByEntry = <String, List<Tag>>{};
    for (final j in joinRows) {
      final tag = tagsById[j.tagId];
      if (tag != null) {
        (tagsByEntry[j.entryId] ??= <Tag>[]).add(tag);
      }
    }
    return [
      for (final r in rows) rowToEntity(r, tags: tagsByEntry[r.id] ?? const [])
    ];
  }

  Future<List<Tag>> _tagsForEntry(String entryId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(
        _db.entryTags,
        _db.entryTags.tagId.equalsExp(_db.tags.id) &
            _db.entryTags.entryId.equals(entryId),
      ),
    ]);
    final rows = await query.get();
    return rows.map((r) => rowToTag(r.readTable(_db.tags))).toList();
  }

  Future<void> _upsertTags(List<Tag> tags) async {
    for (final t in tags) {
      await _db.into(_db.tags).insertOnConflictUpdate(tagToRow(t));
    }
  }

  Future<void> _replaceEntryTags(String entryId, List<Tag> tags) async {
    await (_db.delete(_db.entryTags)..where((t) => t.entryId.equals(entryId)))
        .go();
    for (final t in tags) {
      await _db.into(_db.entryTags).insert(
            EntryTagsCompanion.insert(entryId: entryId, tagId: t.id),
          );
    }
  }

  EntriesCompanion _entryCompanion(MoodEntry entry, {required bool isInsert}) {
    return EntriesCompanion(
      id: Value(entry.id),
      occurredAt: Value(entry.occurredAt.millisecondsSinceEpoch),
      mood: Value(entry.mood.index),
      intensity: Value(entry.intensity),
      note: Value(entry.note),
      sleepHours: Value(entry.sleepHours),
      energy: Value(entry.energy.index),
      createdAt: isInsert
          ? Value(entry.createdAt.millisecondsSinceEpoch)
          : const Value.absent(),
      updatedAt: Value(entry.updatedAt.millisecondsSinceEpoch),
    );
  }
}
