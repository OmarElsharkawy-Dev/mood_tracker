import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/accessibility_summaries.dart';
import 'package:mood_tracker/features/statistics/domain/correlation.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/domain/mood_distribution.dart';
import 'package:mood_tracker/features/statistics/domain/mood_trend.dart';
import 'package:mood_tracker/features/statistics/domain/top_tags_view.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

Future<AppLocalizations> _loadEn() =>
    AppLocalizations.delegate.load(const Locale('en'));

Future<AppLocalizations> _loadEs() =>
    AppLocalizations.delegate.load(const Locale('es'));

void main() {
  test('trend summary EN', () async {
    final l = await _loadEn();
    final series = MoodTrendSeries(
      range: InsightsRange.d7,
      points: [
        MoodTrendPoint(day: DateTime(2026, 5, 12), averageMood: 3, entryCount: 1),
        MoodTrendPoint(day: DateTime(2026, 5, 13), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 14), averageMood: 5, entryCount: 1),
        MoodTrendPoint(day: DateTime(2026, 5, 15), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 16), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 17), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 18), averageMood: null, entryCount: 0),
      ],
    );
    expect(trendSummary(series, l), 'Mood trend over 2 days. Average 4.0. Range 3.0 to 5.0.');
  });

  test('distribution summary EN', () async {
    final l = await _loadEn();
    final d = MoodDistribution(counts: const {
      Mood.awful: 0,
      Mood.bad: 1,
      Mood.okay: 2,
      Mood.good: 3,
      Mood.great: 4,
    }, total: 10);
    expect(distributionSummary(d, l), '4 great, 3 good, 2 okay, 1 bad, 0 awful.');
  });

  test('top tags summary EN', () async {
    final l = await _loadEn();
    final v = TopTagsView(entries: [
      TopTagEntry(tag: const Tag(id: '1', slug: 'work', label: 'work'), count: 5),
      TopTagEntry(tag: const Tag(id: '2', slug: 'run', label: 'run'), count: 2),
    ], totalTaggedEntries: 7);
    expect(topTagsSummary(v, l), 'Top tags: work 5, run 2.');
  });

  test('top tags summary empty EN', () async {
    final l = await _loadEn();
    const v = TopTagsView(entries: [], totalTaggedEntries: 0);
    expect(topTagsSummary(v, l), 'Top tags: .');
  });

  test('sleep correlation summary ES', () async {
    final l = await _loadEs();
    const v = CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucketUnder6', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket6to7', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket7to8', sampleSize: 2, averageMood: 3.5),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket8to9', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket9plus', sampleSize: 0, averageMood: null),
    ]);
    expect(sleepSummary(v, l), 'Sueño vs. ánimo: 7–8h prom. 3.5.');
  });

  test('energy correlation summary EN', () async {
    final l = await _loadEn();
    const v = CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'energyVeryLow', sampleSize: 1, averageMood: 2.0),
      CorrelationBucket(bucketLabelKey: 'energyLow', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyMedium', sampleSize: 3, averageMood: 4.0),
      CorrelationBucket(bucketLabelKey: 'energyHigh', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyVeryHigh', sampleSize: 0, averageMood: null),
    ]);
    expect(energySummary(v, l), 'Energy vs. mood: Very low avg 2.0, Medium avg 4.0.');
  });
}
