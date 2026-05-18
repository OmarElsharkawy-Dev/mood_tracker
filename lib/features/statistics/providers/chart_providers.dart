import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/aggregators.dart';
import '../domain/correlation.dart';
import '../domain/mood_distribution.dart';
import '../domain/mood_trend.dart';
import '../domain/top_tags_view.dart';
import 'insights_entries_provider.dart';
import 'selected_range_controller.dart';

final moodTrendProvider = Provider<AsyncValue<MoodTrendSeries>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  final range = ref.watch(selectedRangeProvider);
  final now = ref.watch(insightsNowProvider);
  return entries.whenData(
      (data) => computeMoodTrend(entries: data, range: range, now: now));
});

final moodDistributionProvider = Provider<AsyncValue<MoodDistribution>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData(computeDistribution);
});

final topTagsProvider = Provider<AsyncValue<TopTagsView>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData((data) => computeTopTags(data));
});

final sleepCorrelationProvider = Provider<AsyncValue<CorrelationView>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData(computeSleepCorrelation);
});

final energyCorrelationProvider = Provider<AsyncValue<CorrelationView>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData(computeEnergyCorrelation);
});
