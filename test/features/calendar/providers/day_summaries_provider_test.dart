import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/calendar/providers/calendar_entries_provider.dart';
import 'package:mood_tracker/features/calendar/providers/day_summaries_provider.dart';
import 'package:mood_tracker/features/calendar/providers/selected_month_controller.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';

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

MoodEntry _entry({required String id, required DateTime at, required Mood mood}) {
  return MoodEntry(
    id: id,
    occurredAt: at,
    mood: mood,
    intensity: 5,
    note: null,
    tags: const <Tag>[],
    sleepHours: null,
    energy: EnergyLevel.medium,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  test('groups entries by startOfDay with rounded average mood', () async {
    final day1 = DateTime(2026, 5, 17, 9);
    final day1Evening = DateTime(2026, 5, 17, 21);
    final day2 = DateTime(2026, 5, 18, 12);

    final repo = _StubRepo([
      _entry(id: 'a', at: day1, mood: Mood.good),
      _entry(id: 'b', at: day1Evening, mood: Mood.okay),
      _entry(id: 'c', at: day2, mood: Mood.bad),
    ]);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));

    // Subscribe to the stream provider so it begins emitting, then wait for
    // the first data event before reading the synchronous derived provider.
    await container.read(calendarEntriesProvider.future);

    final summaries = container.read(daySummariesProvider);
    final day1Key = DateTime(2026, 5, 17);
    final day2Key = DateTime(2026, 5, 18);

    expect(summaries[day1Key]?.entryCount, 2);
    expect(summaries[day1Key]?.averageMood, Mood.good);
    expect(summaries[day2Key]?.entryCount, 1);
    expect(summaries[day2Key]?.averageMood, Mood.bad);
  });

  test('empty entries → empty map', () async {
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo(const [])),
    ]);
    addTearDown(container.dispose);
    await container.read(calendarEntriesProvider.future);
    expect(container.read(daySummariesProvider), isEmpty);
  });
}
