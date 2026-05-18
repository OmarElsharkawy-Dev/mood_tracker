import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';

MoodEntry _e({required String id, required double? sleep, required Mood mood}) =>
    MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: mood,
      intensity: 5,
      note: null,
      tags: const [],
      sleepHours: sleep,
      energy: EnergyLevel.medium,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeSleepCorrelation', () {
    test('empty → 5 empty buckets in fixed order', () {
      final v = computeSleepCorrelation(const []);
      expect(v.buckets.length, 5);
      expect(v.buckets.map((b) => b.bucketLabelKey).toList(), [
        'insightsSleepBucketUnder6',
        'insightsSleepBucket6to7',
        'insightsSleepBucket7to8',
        'insightsSleepBucket8to9',
        'insightsSleepBucket9plus',
      ]);
      expect(v.buckets.every((b) => b.averageMood == null), isTrue);
      expect(v.nonEmptyBucketCount, 0);
    });

    test('null sleep entries are excluded', () {
      final v = computeSleepCorrelation([
        _e(id: 'a', sleep: null, mood: Mood.great),
        _e(id: 'b', sleep: 7.5, mood: Mood.good),
      ]);
      expect(v.buckets[0].sampleSize, 0);
      expect(v.buckets[2].sampleSize, 1); // 7-8
      expect(v.buckets[2].averageMood, Mood.good.score.toDouble());
      expect(v.nonEmptyBucketCount, 1);
    });

    test('boundary tests on half-open intervals', () {
      final entries = [
        _e(id: '0', sleep: 5.99, mood: Mood.okay),  // <6
        _e(id: '1', sleep: 6.0, mood: Mood.okay),   // 6-7
        _e(id: '2', sleep: 6.99, mood: Mood.okay),  // 6-7
        _e(id: '3', sleep: 7.0, mood: Mood.okay),   // 7-8
        _e(id: '4', sleep: 7.99, mood: Mood.okay),  // 7-8
        _e(id: '5', sleep: 8.0, mood: Mood.okay),   // 8-9
        _e(id: '6', sleep: 8.99, mood: Mood.okay),  // 8-9
        _e(id: '7', sleep: 9.0, mood: Mood.okay),   // 9+
        _e(id: '8', sleep: 12.0, mood: Mood.okay),  // 9+
      ];
      final v = computeSleepCorrelation(entries);
      expect(v.buckets[0].sampleSize, 1); // <6
      expect(v.buckets[1].sampleSize, 2); // 6-7
      expect(v.buckets[2].sampleSize, 2); // 7-8
      expect(v.buckets[3].sampleSize, 2); // 8-9
      expect(v.buckets[4].sampleSize, 2); // 9+
    });

    test('averageMood is mean of mood scores within bucket', () {
      final v = computeSleepCorrelation([
        _e(id: 'a', sleep: 7.5, mood: Mood.awful),  // 1
        _e(id: 'b', sleep: 7.2, mood: Mood.great),  // 5
      ]);
      expect(v.buckets[2].sampleSize, 2);
      expect(v.buckets[2].averageMood, 3.0);
    });
  });
}
