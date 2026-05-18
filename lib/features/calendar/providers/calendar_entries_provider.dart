import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';
import '../../search/providers/entry_filter_controller.dart';
import 'selected_month_controller.dart';

/// Entries within the currently-selected month, also respecting the global
/// filter (mood range, tags, text). The selected month's date bounds intersect
/// with the filter's dateRange (if any).
final calendarEntriesProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  final month = ref.watch(selectedMonthControllerProvider);
  final filter = ref.watch(entryFilterProvider);

  final monthStart = month.firstDay;
  final monthEnd =
      DateTime(month.year, month.month, month.lastDay.day, 23, 59, 59, 999);

  final filterRange = filter.dateRange;
  final DateTimeRange combined;
  if (filterRange == null) {
    combined = DateTimeRange(start: monthStart, end: monthEnd);
  } else {
    final start =
        filterRange.start.isAfter(monthStart) ? filterRange.start : monthStart;
    final end =
        filterRange.end.isBefore(monthEnd) ? filterRange.end : monthEnd;
    combined = DateTimeRange(start: start, end: end);
  }

  final query = EntryQuery(
    dateRange: combined,
    moodRange: filter.moodRange,
    tagIds: filter.tagIds.isEmpty ? null : filter.tagIds,
    text: filter.text,
  );

  return repo.watchAll(query: query);
});
