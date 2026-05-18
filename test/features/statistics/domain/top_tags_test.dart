import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';

Tag _tag(String slug) => Tag(id: 't_$slug', slug: slug, label: slug);

MoodEntry _entry(String id, List<Tag> tags) => MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: Mood.okay,
      intensity: 5,
      note: null,
      tags: tags,
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeTopTags', () {
    test('empty input → empty entries, totalTaggedEntries 0', () {
      final v = computeTopTags(const []);
      expect(v.entries, isEmpty);
      expect(v.totalTaggedEntries, 0);
    });

    test('counts and sorts desc by count', () {
      final work = _tag('work');
      final family = _tag('family');
      final run = _tag('run');
      final v = computeTopTags([
        _entry('a', [work, family]),
        _entry('b', [work]),
        _entry('c', [run]),
      ]);
      expect(v.entries.map((e) => e.tag.slug).toList(), ['work', 'family', 'run']);
      expect(v.entries.map((e) => e.count).toList(), [2, 1, 1]);
      expect(v.totalTaggedEntries, 3);
    });

    test('ties broken alphabetically by slug', () {
      final b = _tag('beta');
      final a = _tag('alpha');
      final v = computeTopTags([
        _entry('x', [b, a]),
      ]);
      expect(v.entries.map((e) => e.tag.slug).toList(), ['alpha', 'beta']);
    });

    test('caps at limit (default 10)', () {
      final tags = List.generate(15, (i) => _tag('t${i.toString().padLeft(2, '0')}'));
      final entries = [for (final t in tags) _entry(t.slug, [t])];
      final v = computeTopTags(entries);
      expect(v.entries.length, 10);
      expect(v.entries.map((e) => e.tag.slug).toList(),
          ['t00', 't01', 't02', 't03', 't04', 't05', 't06', 't07', 't08', 't09']);
    });

    test('untagged entries excluded from totalTaggedEntries', () {
      final v = computeTopTags([
        _entry('a', [_tag('x')]),
        _entry('b', const []),
      ]);
      expect(v.totalTaggedEntries, 1);
    });
  });
}
