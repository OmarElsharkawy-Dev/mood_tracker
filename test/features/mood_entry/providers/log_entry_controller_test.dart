import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/mood_entry/providers/log_entry_controller.dart';

class _FakeRepo implements MoodEntryRepository {
  final List<MoodEntry> created = [];
  MoodEntry? toReturnOnGetById;

  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async {
    created.add(entry);
    return (entry, null);
  }

  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async => (entry, null);

  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);

  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      toReturnOnGetById == null
          ? (null, NotFoundFailure(id: id))
          : (toReturnOnGetById, null);

  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => const Stream.empty();

  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const <MoodEntry>[], null);
}

void main() {
  late ProviderContainer container;
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial state is blank LogEntryFormState wrapped in AsyncData', () async {
    final s = await container.read(logEntryControllerProvider(null).future);
    expect(s.mood, isNull);
  });

  test('selectMood updates state', () async {
    final notifier =
        container.read(logEntryControllerProvider(null).notifier);
    await container.read(logEntryControllerProvider(null).future);
    notifier.selectMood(Mood.good);
    final state = container.read(logEntryControllerProvider(null)).value!;
    expect(state.mood, Mood.good);
  });

  test('submit persists when valid', () async {
    final notifier =
        container.read(logEntryControllerProvider(null).notifier);
    await container.read(logEntryControllerProvider(null).future);
    notifier.selectMood(Mood.good);
    final ok = await notifier.submit();
    expect(ok, isTrue);
    expect(repo.created, hasLength(1));
    expect(repo.created.single.mood, Mood.good);
  });

  test('submit returns false and does not call repo when invalid', () async {
    final notifier =
        container.read(logEntryControllerProvider(null).notifier);
    await container.read(logEntryControllerProvider(null).future);
    final ok = await notifier.submit(); // mood not set
    expect(ok, isFalse);
    expect(repo.created, isEmpty);
  });

  test('edit mode loads existing entry', () async {
    final now = DateTime(2026, 5, 17);
    repo.toReturnOnGetById = MoodEntry(
      id: 'e1',
      occurredAt: now,
      mood: Mood.bad,
      intensity: 3,
      note: 'meh',
      tags: const [],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: now,
      updatedAt: now,
    );
    final s = await container.read(logEntryControllerProvider('e1').future);
    expect(s.mood, Mood.bad);
    expect(s.intensity, 3);
  });
}
