import 'package:flutter/foundation.dart';

import '../enums/mood.dart';

@immutable
class EntryQuery {
  const EntryQuery({
    this.dateRange,
    this.moodRange,
    this.tagIds,
    this.text,
    this.limit,
  });

  final DateTimeRange? dateRange;
  final ({Mood min, Mood max})? moodRange;
  final List<String>? tagIds;
  final String? text;
  final int? limit;
}

@immutable
class DateTimeRange {
  const DateTimeRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}
