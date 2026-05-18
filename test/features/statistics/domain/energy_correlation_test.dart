import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';

MoodEntry _e(String id, EnergyLevel lvl, Mood mood) => MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: mood,
      intensity: 5,
      note: null,
      tags: const [],
      sleepHours: null,
      energy: lvl,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeEnergyCorrelation', () {
    test('empty → 5 empty buckets in EnergyLevel order', () {
      final v = computeEnergyCorrelation(const []);
      expect(v.buckets.length, 5);
      expect(v.buckets.map((b) => b.bucketLabelKey).toList(),
          ['energyVeryLow', 'energyLow', 'energyMedium', 'energyHigh', 'energyVeryHigh']);
      expect(v.nonEmptyBucketCount, 0);
    });

    test('buckets carry sample size and avg mood', () {
      final v = computeEnergyCorrelation([
        _e('a', EnergyLevel.medium, Mood.good),    // 4
        _e('b', EnergyLevel.medium, Mood.great),   // 5
        _e('c', EnergyLevel.veryLow, Mood.awful),  // 1
      ]);
      expect(v.buckets[0].sampleSize, 1);
      expect(v.buckets[0].averageMood, 1.0);
      expect(v.buckets[2].sampleSize, 2);
      expect(v.buckets[2].averageMood, 4.5);
      expect(v.buckets[4].averageMood, isNull);
      expect(v.nonEmptyBucketCount, 2);
    });
  });
}
