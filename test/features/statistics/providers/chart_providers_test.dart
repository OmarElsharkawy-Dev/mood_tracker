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
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/providers/chart_providers.dart';
import 'package:mood_tracker/features/statistics/providers/insights_entries_provider.dart';
import 'package:mood_tracker/features/statistics/providers/selected_range_controller.dart';

MoodEntry _e(String id, Mood m, {List<Tag> tags = const [], double? sleep, EnergyLevel energy = EnergyLevel.medium}) {
  final t = DateTime(2026, 5, 18, 10);
  return MoodEntry(
    id: id, occurredAt: t, mood: m, intensity: 5, note: null,
    tags: tags, sleepHours: sleep, energy: energy,
    createdAt: t, updatedAt: t,
  );
}

class _FixedRepo implements MoodEntryRepository {
  _FixedRepo(this.data);
  final List<MoodEntry> data;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(data);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (data, null);
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

ProviderContainer _container(List<MoodEntry> data) {
  final c = ProviderContainer(overrides: [
    moodEntryRepositoryProvider.overrideWithValue(_FixedRepo(data)),
    insightsNowProvider.overrideWithValue(DateTime(2026, 5, 18, 12)),
  ]);
  c.read(selectedRangeProvider.notifier).set(InsightsRange.d7);
  return c;
}

void main() {
  test('moodTrendProvider emits data with daysWithData', () async {
    final c = _container([_e('a', Mood.good)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    final v = c.read(moodTrendProvider).value!;
    expect(v.daysWithData, 1);
  });

  test('moodDistributionProvider returns total', () async {
    final c = _container([_e('a', Mood.great), _e('b', Mood.bad)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    expect(c.read(moodDistributionProvider).value!.total, 2);
  });

  test('topTagsProvider returns entries', () async {
    final c = _container([_e('a', Mood.okay, tags: [const Tag(id: 't', slug: 's', label: 'l')])]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    final v = c.read(topTagsProvider).value!;
    expect(v.entries.single.tag.id, 't');
  });

  test('sleepCorrelationProvider returns view', () async {
    final c = _container([_e('a', Mood.good, sleep: 7.5)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    expect(c.read(sleepCorrelationProvider).value!.nonEmptyBucketCount, 1);
  });

  test('energyCorrelationProvider returns view', () async {
    final c = _container([_e('a', Mood.good, energy: EnergyLevel.high)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    final v = c.read(energyCorrelationProvider).value!;
    expect(v.buckets[3].sampleSize, 1);
  });
}
