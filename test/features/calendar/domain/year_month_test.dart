import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';

void main() {
  test('fromDate extracts year and month', () {
    expect(YearMonth.fromDate(DateTime(2026, 5, 18)), const YearMonth(2026, 5));
  });

  test('next wraps Dec → Jan + year++', () {
    expect(const YearMonth(2026, 12).next, const YearMonth(2027, 1));
    expect(const YearMonth(2026, 5).next, const YearMonth(2026, 6));
  });

  test('previous wraps Jan → Dec + year--', () {
    expect(const YearMonth(2026, 1).previous, const YearMonth(2025, 12));
    expect(const YearMonth(2026, 5).previous, const YearMonth(2026, 4));
  });

  test('firstDay is day 1 at midnight', () {
    expect(const YearMonth(2026, 2).firstDay, DateTime(2026, 2, 1));
  });

  test('lastDay handles February in a non-leap year (2026)', () {
    expect(const YearMonth(2026, 2).lastDay, DateTime(2026, 2, 28));
  });

  test('lastDay handles February in a leap year (2024)', () {
    expect(const YearMonth(2024, 2).lastDay, DateTime(2024, 2, 29));
  });

  test('lastDay handles December', () {
    expect(const YearMonth(2026, 12).lastDay, DateTime(2026, 12, 31));
  });

  test('equality is by year and month', () {
    expect(const YearMonth(2026, 5), const YearMonth(2026, 5));
    expect(const YearMonth(2026, 5) == const YearMonth(2026, 6), isFalse);
  });
}
