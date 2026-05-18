import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/backup/data/backup_codec.dart';
import 'package:mood_tracker/features/backup/domain/backup_envelope.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

MoodEntry _e({String id = 'e1'}) {
  final t = DateTime.utc(2026, 5, 17, 12, 0, 0);
  return MoodEntry(
    id: id,
    occurredAt: t,
    mood: Mood.good,
    intensity: 7,
    note: 'Great hike today',
    tags: [
      const Tag(id: 't1', slug: 'work', label: 'Work'),
      const Tag(id: 't2', slug: 'outside', label: 'Outside'),
    ],
    sleepHours: 7.5,
    energy: EnergyLevel.high,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('round-trip envelope produces equivalent entries', () {
    final original = BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: '1.0.0+1',
      entries: [_e()],
    );
    final json = envelopeToJson(original);
    final restored = envelopeFromJson(json);
    expect(restored.schema, 1);
    expect(restored.exportedAt, original.exportedAt);
    expect(restored.appVersion, '1.0.0+1');
    expect(restored.entries.length, 1);
    final re = restored.entries.first;
    expect(re.id, 'e1');
    expect(re.mood, Mood.good);
    expect(re.energy, EnergyLevel.high);
    expect(re.intensity, 7);
    expect(re.note, 'Great hike today');
    expect(re.sleepHours, 7.5);
    expect(re.tags.map((t) => t.slug).toSet(), {'work', 'outside'});
  });

  test('mood and energy serialize as enum names', () {
    final json = envelopeToJson(BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: 'x',
      entries: [_e()],
    ));
    final entry = (json['entries'] as List).first as Map<String, dynamic>;
    expect(entry['mood'], 'good');
    expect(entry['energy'], 'high');
  });

  test('timestamps serialize as epoch milliseconds', () {
    final json = envelopeToJson(BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: 'x',
      entries: [_e()],
    ));
    final entry = (json['entries'] as List).first as Map<String, dynamic>;
    expect(entry['occurredAt'], DateTime.utc(2026, 5, 17, 12).millisecondsSinceEpoch);
  });

  test('envelopeFromJson rejects invalid entries with BackupFormatException', () {
    final bad = {
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': [
        {
          'id': 'broken',
          'occurredAt': 0,
          'mood': 'goodish',
          'intensity': 5,
          'note': null,
          'tags': <String>[],
          'sleepHours': null,
          'energy': 'medium',
          'createdAt': 0,
          'updatedAt': 0,
        }
      ],
    };
    expect(() => envelopeFromJson(bad), throwsA(isA<BackupFormatException>()));
  });

  test('migrate is identity for current-schema envelope', () {
    final raw = <String, dynamic>{
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': <Map<String, dynamic>>[],
    };
    final migrated = migrate(Map<String, dynamic>.from(raw));
    expect(migrated['schema'], 1);
    expect(migrated['entries'], <Map<String, dynamic>>[]);
  });

  test('migrate bumps unknown older schema to current', () {
    final raw = <String, dynamic>{
      'schema': 0,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': <Map<String, dynamic>>[],
    };
    final migrated = migrate(raw);
    expect(migrated['schema'], 1);
  });
}
