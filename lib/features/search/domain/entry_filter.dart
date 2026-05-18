import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/enums/mood.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';

@immutable
class EntryFilter {
  const EntryFilter({
    this.text,
    this.moodRange,
    this.dateRange,
    this.tagIds = const [],
  });

  static const EntryFilter empty = EntryFilter();

  final String? text;
  final ({Mood min, Mood max})? moodRange;
  final DateTimeRange? dateRange;
  final List<String> tagIds;

  bool get isActive =>
      (text != null && text!.isNotEmpty) ||
      moodRange != null ||
      dateRange != null ||
      tagIds.isNotEmpty;

  int get activeCount {
    var n = 0;
    if (text != null && text!.isNotEmpty) n++;
    if (moodRange != null) n++;
    if (dateRange != null) n++;
    if (tagIds.isNotEmpty) n++;
    return n;
  }

  EntryQuery toEntryQuery() => EntryQuery(
        text: text,
        moodRange: moodRange,
        dateRange: dateRange,
        tagIds: tagIds.isEmpty ? null : tagIds,
      );

  EntryFilter copyWith({
    Object? text = _unset,
    Object? moodRange = _unset,
    Object? dateRange = _unset,
    List<String>? tagIds,
  }) {
    return EntryFilter(
      text: identical(text, _unset) ? this.text : text as String?,
      moodRange: identical(moodRange, _unset)
          ? this.moodRange
          : moodRange as ({Mood min, Mood max})?,
      dateRange: identical(dateRange, _unset)
          ? this.dateRange
          : dateRange as DateTimeRange?,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryFilter &&
          text == other.text &&
          moodRange == other.moodRange &&
          dateRange == other.dateRange &&
          listEquals(tagIds, other.tagIds);

  @override
  int get hashCode =>
      Object.hash(text, moodRange, dateRange, Object.hashAll(tagIds));
}

const Object _unset = Object();
