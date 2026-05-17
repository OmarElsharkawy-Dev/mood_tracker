import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';
import 'package:mood_tracker/features/mood_entry/data/mappers/mood_entry_mapper.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  final ts = DateTime(2026, 5, 17, 14).millisecondsSinceEpoch;
  final row = EntryRow(
    id: 'e1',
    occurredAt: ts,
    mood: Mood.good.index,
    intensity: 7,
    note: 'fine',
    sleepHours: 7.5,
    energy: EnergyLevel.high.index,
    createdAt: ts,
    updatedAt: ts,
  );

  test('rowToEntity maps fields + tags', () {
    final entity = rowToEntity(row, tags: const [
      Tag(id: 't1', slug: 'work', label: 'Work'),
    ]);
    expect(entity.id, 'e1');
    expect(entity.mood, Mood.good);
    expect(entity.intensity, 7);
    expect(entity.tags.single.slug, 'work');
  });

  test('entityToRow round-trips', () {
    final entity = MoodEntry(
      id: 'e1',
      occurredAt: DateTime.fromMillisecondsSinceEpoch(ts),
      mood: Mood.good,
      intensity: 7,
      note: 'fine',
      tags: const [],
      sleepHours: 7.5,
      energy: EnergyLevel.high,
      createdAt: DateTime.fromMillisecondsSinceEpoch(ts),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(ts),
    );
    final converted = entityToRow(entity);
    expect(converted.id, 'e1');
    expect(converted.mood, Mood.good.index);
    expect(converted.energy, EnergyLevel.high.index);
  });
}
