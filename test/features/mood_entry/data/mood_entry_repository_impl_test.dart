import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_impl.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';

void main() {
  late AppDatabase db;
  late MoodEntryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MoodEntryRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  MoodEntry sample({String id = 'e1', List<Tag> tags = const []}) {
    final now = DateTime(2026, 5, 17, 14);
    return MoodEntry(
      id: id,
      occurredAt: now,
      mood: Mood.good,
      intensity: 7,
      note: 'note',
      tags: tags,
      sleepHours: 7.5,
      energy: EnergyLevel.high,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('create then getById returns the entry', () async {
    final entry = sample();
    final (created, err) = await repo.create(entry);
    expect(err, isNull);
    expect(created!.id, 'e1');

    final (fetched, err2) = await repo.getById('e1');
    expect(err2, isNull);
    expect(fetched!.intensity, 7);
  });

  test('getById missing returns NotFoundFailure', () async {
    final (entry, err) = await repo.getById('missing');
    expect(entry, isNull);
    expect(err, isA<NotFoundFailure>());
  });

  test('create persists tags via entry_tags join', () async {
    final tag = Tag(id: 't1', slug: 'work', label: 'Work');
    await repo.create(sample(tags: [tag]));

    final (fetched, _) = await repo.getById('e1');
    expect(fetched!.tags.single.slug, 'work');
  });

  test('delete removes the entry', () async {
    await repo.create(sample());
    final (unit, err) = await repo.delete('e1');
    expect(unit, isNotNull);
    expect(err, isNull);

    final (after, err2) = await repo.getById('e1');
    expect(after, isNull);
    expect(err2, isA<NotFoundFailure>());
  });

  test('watchAll emits when entries change', () async {
    final emissions = <int>[];
    final sub = repo.watchAll().listen((list) => emissions.add(list.length));

    // Allow the initial empty-list emission to arrive before inserting.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await repo.create(sample(id: 'a'));
    await repo.create(sample(id: 'b'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions, contains(0));
    expect(emissions.last, 2);

    await sub.cancel();
  });

  test('update modifies fields', () async {
    await repo.create(sample());
    final (_, _) = await repo.update(sample().copyWith(intensity: 9));
    final (fetched, _) = await repo.getById('e1');
    expect(fetched!.intensity, 9);
  });

  test('watchAll filters by dateRange', () async {
    final base = DateTime(2026, 5, 17, 12);
    await repo.create(sample(id: 'a').copyWith(occurredAt: base.subtract(const Duration(days: 5))));
    await repo.create(sample(id: 'b').copyWith(occurredAt: base));
    await repo.create(sample(id: 'c').copyWith(occurredAt: base.add(const Duration(days: 5))));

    final (entries, err) = await repo.getAll(
      query: EntryQuery(
        dateRange: DateTimeRange(
          start: base.subtract(const Duration(days: 1)),
          end: base.add(const Duration(days: 1)),
        ),
      ),
    );
    expect(err, isNull);
    expect(entries!.length, 1);
    expect(entries.single.id, 'b');
  });

  test('watchAll filters by moodRange', () async {
    await repo.create(sample(id: 'awful').copyWith(mood: Mood.awful));
    await repo.create(sample(id: 'okay').copyWith(mood: Mood.okay));
    await repo.create(sample(id: 'great').copyWith(mood: Mood.great));

    final (entries, _) = await repo.getAll(
      query: const EntryQuery(moodRange: (min: Mood.bad, max: Mood.good)),
    );
    expect(entries!.map((e) => e.id), unorderedEquals(['okay']));
  });

  test('watchAll filters by tagIds (entries containing any of the tags)', () async {
    const work = Tag(id: 't_work', slug: 'work', label: 'Work');
    const sleep = Tag(id: 't_sleep', slug: 'sleep', label: 'Sleep');
    await repo.create(sample(id: 'with_work', tags: [work]));
    await repo.create(sample(id: 'with_sleep', tags: [sleep]));
    await repo.create(sample(id: 'without_tags'));

    final (entries, _) = await repo.getAll(
      query: const EntryQuery(tagIds: ['t_work']),
    );
    expect(entries!.map((e) => e.id), unorderedEquals(['with_work']));
  });

  test('watchAll filters by text (case-insensitive LIKE)', () async {
    await repo.create(sample(id: 'a').copyWith(note: 'Great hike today'));
    await repo.create(sample(id: 'b').copyWith(note: 'work meeting'));
    await repo.create(sample(id: 'c').copyWith(note: null));

    final (entries, _) = await repo.getAll(query: const EntryQuery(text: 'hike'));
    expect(entries!.map((e) => e.id), unorderedEquals(['a']));
  });

  test('watchAll combines filters with AND', () async {
    const work = Tag(id: 't_work', slug: 'work', label: 'Work');
    await repo.create(sample(id: 'm1', tags: [work]).copyWith(mood: Mood.good));
    await repo.create(sample(id: 'm2', tags: [work]).copyWith(mood: Mood.awful));
    await repo.create(sample(id: 'm3').copyWith(mood: Mood.good));

    final (entries, _) = await repo.getAll(
      query: const EntryQuery(
        tagIds: ['t_work'],
        moodRange: (min: Mood.good, max: Mood.great),
      ),
    );
    expect(entries!.map((e) => e.id), unorderedEquals(['m1']));
  });
}
