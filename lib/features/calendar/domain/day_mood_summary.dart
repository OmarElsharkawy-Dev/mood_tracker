import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/enums/mood.dart';

@immutable
class DayMoodSummary {
  const DayMoodSummary({
    required this.date,
    required this.averageMood,
    required this.entryCount,
  });

  final DateTime date;
  final Mood averageMood;
  final int entryCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayMoodSummary &&
          date == other.date &&
          averageMood == other.averageMood &&
          entryCount == other.entryCount;

  @override
  int get hashCode => Object.hash(date, averageMood, entryCount);
}
