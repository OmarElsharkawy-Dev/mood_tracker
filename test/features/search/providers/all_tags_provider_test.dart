import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/search/providers/all_tags_provider.dart';

class _StubRepo implements MoodEntryRepository {
  _StubRepo(this._entries);
  final List<MoodEntry> _entries;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) =>
      Stream.value(_entries);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_entries, null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

MoodEntry _entry({required String id, List<Tag> tags = const []}) {
  final now = DateTime(2026, 5, 18);
  return MoodEntry(
    id: id,
    occurredAt: now,
    mood: Mood.good,
    intensity: 5,
    note: null,
    tags: tags,
    sleepHours: null,
    energy: EnergyLevel.medium,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('emits sorted distinct tags across all entries', () async {
    const work = Tag(id: 't_work', slug: 'work', label: 'Work');
    const sleep = Tag(id: 't_sleep', slug: 'sleep', label: 'Sleep');
    const calm = Tag(id: 't_calm', slug: 'calm', label: 'Calm');

    final repo = _StubRepo([
      _entry(id: 'a', tags: [work, calm]),
      _entry(id: 'b', tags: [sleep]),
      _entry(id: 'c', tags: [work]),
    ]);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final tags = await container.read(allTagsProvider.future);
    expect(tags.map((t) => t.label), ['Calm', 'Sleep', 'Work']);
  });

  test('emits empty list when no entries have tags', () async {
    final repo = _StubRepo([_entry(id: 'a'), _entry(id: 'b')]);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final tags = await container.read(allTagsProvider.future);
    expect(tags, isEmpty);
  });
}
