import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/enums/mood.dart';

@immutable
class MoodDistribution {
  const MoodDistribution({required this.counts, required this.total});

  final Map<Mood, int> counts;
  final int total;

  double percentage(Mood m) {
    if (total == 0) return 0;
    return (counts[m] ?? 0) / total;
  }
}
