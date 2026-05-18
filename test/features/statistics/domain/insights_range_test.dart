import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';

void main() {
  // Fixed "now" for deterministic boundary math.
  final now = DateTime(2026, 5, 18, 14, 30); // 2:30pm local

  group('InsightsRangeX.toDateRange', () {
    test('d7 → today inclusive, 7 calendar days', () {
      final r = InsightsRange.d7.toDateRange(now);
      expect(r.start, DateTime(2026, 5, 12));
      expect(r.end, isNull);
    });

    test('d30 → 30 calendar days', () {
      final r = InsightsRange.d30.toDateRange(now);
      expect(r.start, DateTime(2026, 4, 19));
      expect(r.end, isNull);
    });

    test('d90 → 90 calendar days', () {
      final r = InsightsRange.d90.toDateRange(now);
      expect(r.start, DateTime(2026, 2, 18));
      expect(r.end, isNull);
    });

    test('all → both null', () {
      final r = InsightsRange.all.toDateRange(now);
      expect(r.start, isNull);
      expect(r.end, isNull);
    });

    test('d7 from early-of-month date crosses month boundary', () {
      final r = InsightsRange.d7.toDateRange(DateTime(2026, 5, 3, 10));
      expect(r.start, DateTime(2026, 4, 27));
      expect(r.end, isNull);
    });

    test('start aligns to midnight regardless of clock time', () {
      final r = InsightsRange.d7.toDateRange(DateTime(2026, 5, 18, 23, 59));
      expect(r.start!.hour, 0);
      expect(r.start!.minute, 0);
    });
  });

  group('InsightsRangeX.labelKey', () {
    test('returns the right l10n key', () {
      expect(InsightsRange.d7.labelKey, 'insightsRange7d');
      expect(InsightsRange.d30.labelKey, 'insightsRange30d');
      expect(InsightsRange.d90.labelKey, 'insightsRange90d');
      expect(InsightsRange.all.labelKey, 'insightsRangeAll');
    });
  });
}
