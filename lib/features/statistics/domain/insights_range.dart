enum InsightsRange { d7, d30, d90, all }

extension InsightsRangeX on InsightsRange {
  ({DateTime? start, DateTime? end}) toDateRange(DateTime now) {
    DateTime daysAgo(int days) =>
        DateTime(now.year, now.month, now.day - days);
    switch (this) {
      case InsightsRange.d7:
        return (start: daysAgo(6), end: null);
      case InsightsRange.d30:
        return (start: daysAgo(29), end: null);
      case InsightsRange.d90:
        return (start: daysAgo(89), end: null);
      case InsightsRange.all:
        return (start: null, end: null);
    }
  }

  String get labelKey {
    switch (this) {
      case InsightsRange.d7:
        return 'insightsRange7d';
      case InsightsRange.d30:
        return 'insightsRange30d';
      case InsightsRange.d90:
        return 'insightsRange90d';
      case InsightsRange.all:
        return 'insightsRangeAll';
    }
  }
}
