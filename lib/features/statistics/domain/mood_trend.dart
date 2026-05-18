import 'package:flutter/foundation.dart';

import 'insights_range.dart';

@immutable
class MoodTrendPoint {
  const MoodTrendPoint({
    required this.day,
    required this.averageMood,
    required this.entryCount,
  });

  final DateTime day;
  final double? averageMood;
  final int entryCount;
}

@immutable
class MoodTrendSeries {
  const MoodTrendSeries({required this.points, required this.range});

  final List<MoodTrendPoint> points;
  final InsightsRange range;

  static bool _hasData(MoodTrendPoint p) => p.averageMood != null;

  int get daysWithData =>
      points.where(_hasData).length;

  double? get overallAverage {
    final filled = points.where(_hasData).toList();
    if (filled.isEmpty) return null;
    final sum = filled.fold<double>(0, (acc, p) => acc + p.averageMood!);
    return sum / filled.length;
  }

  double? get minDay {
    final filled =
        points.where(_hasData).map((p) => p.averageMood!);
    if (filled.isEmpty) return null;
    return filled.reduce((a, b) => a < b ? a : b);
  }

  double? get maxDay {
    final filled =
        points.where(_hasData).map((p) => p.averageMood!);
    if (filled.isEmpty) return null;
    return filled.reduce((a, b) => a > b ? a : b);
  }

  DateTime? get lowestDay {
    MoodTrendPoint? best;
    for (final p in points) {
      if (p.averageMood == null) continue;
      if (best == null || p.averageMood! < best.averageMood!) best = p;
    }
    return best?.day;
  }
}
