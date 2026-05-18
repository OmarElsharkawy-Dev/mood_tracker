import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';
import '../../search/providers/entry_filter_controller.dart';
import '../domain/insights_range.dart';
import 'selected_range_controller.dart';

/// Overridable for tests; in production reads `DateTime.now()`.
final insightsNowProvider = Provider<DateTime>((_) => DateTime.now());

final insightsEntriesProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  final filter = ref.watch(entryFilterProvider);
  final range = ref.watch(selectedRangeProvider);
  final now = ref.watch(insightsNowProvider);

  final base = filter.toEntryQuery();
  final rangeDates = range.toDateRange(now);

  // For finite ranges, end-of-window = start-of-tomorrow so today's entries
  // are included regardless of clock time. For range == all, leave end null.
  final inclusiveEnd = rangeDates.start == null
      ? null
      : DateTime(now.year, now.month, now.day + 1);

  DateTimeRange? merged;
  if (rangeDates.start == null) {
    merged = base.dateRange;
  } else if (base.dateRange == null) {
    merged = DateTimeRange(start: rangeDates.start!, end: inclusiveEnd!);
  } else {
    final start = base.dateRange!.start.isAfter(rangeDates.start!)
        ? base.dateRange!.start
        : rangeDates.start!;
    final end = base.dateRange!.end.isBefore(inclusiveEnd!)
        ? base.dateRange!.end
        : inclusiveEnd;
    merged = DateTimeRange(start: start, end: end);
  }

  return repo.watchAll(
    query: EntryQuery(
      dateRange: merged,
      moodRange: base.moodRange,
      tagIds: base.tagIds,
      text: base.text,
    ),
  );
});
