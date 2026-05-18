import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/entities/tag.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'insights_range.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';

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

TopTagsView computeTopTags(List<MoodEntry> entries, {int limit = 10}) {
  final counts = <String, ({String slug, String label, int count, String tagId})>{};
  var tagged = 0;
  for (final e in entries) {
    if (e.tags.isEmpty) continue;
    tagged++;
    for (final t in e.tags) {
      final cur = counts[t.id];
      counts[t.id] = (
        slug: t.slug,
        label: t.label,
        count: (cur?.count ?? 0) + 1,
        tagId: t.id,
      );
    }
  }
  final sorted = counts.values.toList()
    ..sort((a, b) {
      final c = b.count.compareTo(a.count);
      if (c != 0) return c;
      return a.slug.compareTo(b.slug);
    });
  final capped = sorted.take(limit).toList();
  return TopTagsView(
    entries: [
      for (final r in capped)
        TopTagEntry(
          tag: Tag(id: r.tagId, slug: r.slug, label: r.label),
          count: r.count,
        ),
    ],
    totalTaggedEntries: tagged,
  );
}
