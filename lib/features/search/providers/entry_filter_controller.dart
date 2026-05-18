import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/domain/enums/mood.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';
import '../domain/entry_filter.dart';

class EntryFilterController extends Notifier<EntryFilter> {
  @override
  EntryFilter build() => EntryFilter.empty;

  void setText(String? text) {
    final normalized = (text == null || text.isEmpty) ? null : text;
    state = state.copyWith(text: normalized);
  }

  void setMoodRange(({Mood min, Mood max})? range) {
    state = state.copyWith(moodRange: range);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range);
  }

  void setTagIds(List<String> ids) {
    state = state.copyWith(tagIds: ids);
  }

  void replace(EntryFilter filter) {
    state = filter;
  }

  void clear() {
    state = EntryFilter.empty;
  }
}

final entryFilterProvider =
    NotifierProvider<EntryFilterController, EntryFilter>(EntryFilterController.new);
