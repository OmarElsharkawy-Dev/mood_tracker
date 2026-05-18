import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';

MoodEntry _entry(String id, Mood m) => MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: m,
      intensity: 5,
      note: null,
      tags: const [],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeDistribution', () {
    test('empty input → all 5 keys present, all zero, total 0', () {
      final d = computeDistribution(const []);
      expect(d.total, 0);
      for (final m in Mood.values) {
        expect(d.counts.containsKey(m), isTrue);
        expect(d.counts[m], 0);
        expect(d.percentage(m), 0);
      }
    });

    test('counts and percentages with mixed input', () {
      final d = computeDistribution([
        _entry('a', Mood.great),
        _entry('b', Mood.great),
        _entry('c', Mood.okay),
        _entry('d', Mood.bad),
      ]);
      expect(d.total, 4);
      expect(d.counts[Mood.great], 2);
      expect(d.counts[Mood.good], 0);
      expect(d.counts[Mood.okay], 1);
      expect(d.counts[Mood.bad], 1);
      expect(d.counts[Mood.awful], 0);
      expect(d.percentage(Mood.great), 0.5);
      expect(d.percentage(Mood.okay), 0.25);
      expect(d.percentage(Mood.awful), 0);
    });
  });
}
