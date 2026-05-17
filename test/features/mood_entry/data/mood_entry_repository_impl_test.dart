import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_impl.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

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
}
