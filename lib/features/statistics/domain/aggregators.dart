import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'insights_range.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';

DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Returns the number of calendar days from [start] to [end] inclusive,
/// using field-based arithmetic to avoid DST off-by-one errors.
int _dayCountInclusive(DateTime start, DateTime end) {
  var count = 0;
  var d = start;
  while (!d.isAfter(end)) {
    count++;
    d = DateTime(d.year, d.month, d.day + 1);
  }
  return count;
}

MoodTrendSeries computeMoodTrend({
  required List<MoodEntry> entries,
  required InsightsRange range,
  required DateTime now,
}) {
  final today = _startOfDay(now);
  final r = range.toDateRange(now);

  // Group entries by start-of-day.
  final byDay = <DateTime, List<MoodEntry>>{};
  for (final e in entries) {
    final key = _startOfDay(e.occurredAt);
    byDay.putIfAbsent(key, () => []).add(e);
  }

  final DateTime start;
  if (range == InsightsRange.all) {
    if (byDay.isEmpty) {
      return MoodTrendSeries(points: const [], range: range);
    }
    start = byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  } else {
    start = r.start!;
  }

  final dayCount = _dayCountInclusive(start, today);
  final points = <MoodTrendPoint>[];
  for (var i = 0; i < dayCount; i++) {
    final day = DateTime(start.year, start.month, start.day + i);
    final group = byDay[day];
    if (group == null || group.isEmpty) {
      points.add(MoodTrendPoint(day: day, averageMood: null, entryCount: 0));
    } else {
      final sum = group.fold<int>(0, (acc, e) => acc + e.mood.score);
      points.add(MoodTrendPoint(
        day: day,
        averageMood: sum / group.length,
        entryCount: group.length,
      ));
    }
  }
  return MoodTrendSeries(points: points, range: range);
}

MoodDistribution computeDistribution(List<MoodEntry> entries) {
  final counts = <Mood, int>{
    for (final m in Mood.values) m: 0,
  };
  for (final e in entries) {
    counts[e.mood] = counts[e.mood]! + 1;
  }
  return MoodDistribution(counts: counts, total: entries.length);
}
