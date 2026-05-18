// test/features/statistics/domain/mood_trend_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';

MoodEntry _entry({
  required String id,
  required DateTime occurredAt,
  Mood mood = Mood.okay,
}) {
  return MoodEntry(
    id: id,
    occurredAt: occurredAt,
    mood: mood,
    intensity: 5,
    note: null,
    tags: const [],
    sleepHours: null,
    energy: EnergyLevel.medium,
    createdAt: occurredAt,
    updatedAt: occurredAt,
  );
}

void main() {
  final now = DateTime(2026, 5, 18, 14);

  group('computeMoodTrend', () {
    test('empty entries → dense gap series of correct length', () {
      final series = computeMoodTrend(
        entries: const [],
        range: InsightsRange.d7,
        now: now,
      );
      expect(series.points.length, 7);
      expect(series.points.every((p) => p.averageMood == null), isTrue);
      expect(series.daysWithData, 0);
      expect(series.overallAverage, isNull);
    });

    test('single entry → that day has averageMood, others null', () {
      final series = computeMoodTrend(
        entries: [_entry(id: '1', occurredAt: DateTime(2026, 5, 16, 10), mood: Mood.good)],
        range: InsightsRange.d7,
        now: now,
      );
      expect(series.points.length, 7);
      final filled = series.points.where((p) => p.averageMood != null).toList();
      expect(filled.length, 1);
      expect(filled.single.day, DateTime(2026, 5, 16));
      expect(filled.single.averageMood, Mood.good.score.toDouble());
      expect(filled.single.entryCount, 1);
    });

    test('two same-day entries average mood ordinals', () {
      final series = computeMoodTrend(
        entries: [
          _entry(id: 'a', occurredAt: DateTime(2026, 5, 16, 8), mood: Mood.awful),
          _entry(id: 'b', occurredAt: DateTime(2026, 5, 16, 20), mood: Mood.great),
        ],
        range: InsightsRange.d7,
        now: now,
      );
      final filled = series.points.singleWhere((p) => p.averageMood != null);
      expect(filled.entryCount, 2);
      expect(filled.averageMood, (1 + 5) / 2);
    });

    test('series spans range.start..today inclusive', () {
      final series = computeMoodTrend(
        entries: const [],
        range: InsightsRange.d30,
        now: now,
      );
      expect(series.points.first.day, DateTime(2026, 4, 19));
      expect(series.points.last.day, DateTime(2026, 5, 18));
      expect(series.points.length, 30);
    });

    test('all-range with no entries → empty series', () {
      final series = computeMoodTrend(
        entries: const [],
        range: InsightsRange.all,
        now: now,
      );
      expect(series.points, isEmpty);
    });

    test('all-range with entries → spans first-entry-day to today', () {
      final series = computeMoodTrend(
        entries: [
          _entry(id: 'old', occurredAt: DateTime(2026, 5, 15, 9), mood: Mood.okay),
          _entry(id: 'new', occurredAt: DateTime(2026, 5, 17, 9), mood: Mood.good),
        ],
        range: InsightsRange.all,
        now: now,
      );
      expect(series.points.first.day, DateTime(2026, 5, 15));
      expect(series.points.last.day, DateTime(2026, 5, 18));
      expect(series.points.length, 4);
      expect(series.daysWithData, 2);
    });

    test('overallAverage, minDay, maxDay, lowestDay populated', () {
      final series = computeMoodTrend(
        entries: [
          _entry(id: 'a', occurredAt: DateTime(2026, 5, 16, 9), mood: Mood.bad),  // 2
          _entry(id: 'b', occurredAt: DateTime(2026, 5, 17, 9), mood: Mood.great), // 5
        ],
        range: InsightsRange.d7,
        now: now,
      );
      expect(series.overallAverage, (2 + 5) / 2);
      expect(series.minDay, 2);
      expect(series.maxDay, 5);
      expect(series.lowestDay, DateTime(2026, 5, 16));
    });
  });
}
