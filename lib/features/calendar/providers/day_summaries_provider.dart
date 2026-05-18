import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_helpers.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/enums/mood.dart';
import '../domain/day_mood_summary.dart';
import 'calendar_entries_provider.dart';

/// Map of startOfDay → DayMoodSummary for the currently-selected month's entries.
/// Days without entries are absent from the map.
final daySummariesProvider = Provider<Map<DateTime, DayMoodSummary>>((ref) {
  final asyncEntries = ref.watch(calendarEntriesProvider);
  final entries = asyncEntries.maybeWhen(
    data: (list) => list,
    orElse: () => const <MoodEntry>[],
  );

  final groups = <DateTime, List<MoodEntry>>{};
  for (final e in entries) {
    final key = startOfDay(e.occurredAt);
    (groups[key] ??= <MoodEntry>[]).add(e);
  }

  return {
    for (final entry in groups.entries)
      entry.key: DayMoodSummary(
        date: entry.key,
        averageMood: _averageMood(entry.value),
        entryCount: entry.value.length,
      ),
  };
});

Mood _averageMood(List<MoodEntry> entries) {
  if (entries.isEmpty) return Mood.okay;
  final total = entries.fold<int>(0, (sum, e) => sum + e.mood.score);
  // Rounding to nearest; ties round up (towards great).
  final avg = (total / entries.length + 0.0001).round();
  final clamped = avg.clamp(1, 5);
  return Mood.values[clamped - 1];
}
