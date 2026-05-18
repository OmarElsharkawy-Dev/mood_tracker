import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/providers/insights_entries_provider.dart';
import 'package:mood_tracker/features/statistics/providers/selected_range_controller.dart';

class _FakeRepo implements MoodEntryRepository {
  EntryQuery? lastQuery;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) {
    lastQuery = query;
    return Stream.value(const []);
  }

  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const <MoodEntry>[], null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async => (entry, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async => (entry, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

void main() {
  test('empty filter + d7 → query carries range.start, end is next-day midnight', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d7);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.dateRange!.start, DateTime(2026, 5, 12));
    expect(repo.lastQuery!.dateRange!.end, DateTime(2026, 5, 19));
    expect(repo.lastQuery!.tagIds, isNull);
    expect(repo.lastQuery!.text, isNull);
    expect(repo.lastQuery!.moodRange, isNull);
  });

  test('filter date range + range → intersection (later start, earlier end)',
      () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(entryFilterProvider.notifier).setDateRange(DateTimeRange(
          start: DateTime(2026, 5, 14),
          end: DateTime(2026, 5, 17),
        ));
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d7);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.dateRange!.start, DateTime(2026, 5, 14));
    expect(repo.lastQuery!.dateRange!.end, DateTime(2026, 5, 17));
  });

  test('filter tags + range → tags pass through', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(entryFilterProvider.notifier).setTagIds(['t1', 't2']);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d30);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.tagIds, ['t1', 't2']);
  });

  test('filter text + mood + range all merged', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(entryFilterProvider.notifier).setText('run');
    container.read(entryFilterProvider.notifier).setMoodRange(
        (min: Mood.okay, max: Mood.great));
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d90);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.text, 'run');
    expect(repo.lastQuery!.moodRange!.min, Mood.okay);
    expect(repo.lastQuery!.moodRange!.max, Mood.great);
    expect(repo.lastQuery!.dateRange!.start, DateTime(2026, 2, 18));
  });

  test('range "all" → no dateRange unless filter provides one', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.all);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.dateRange, isNull);
  });
}
