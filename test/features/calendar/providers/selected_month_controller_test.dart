import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/calendar/providers/selected_month_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('initial state matches current month', () {
    final now = DateTime.now();
    expect(
      container.read(selectedMonthControllerProvider),
      YearMonth(now.year, now.month),
    );
  });

  test('nextMonth advances state', () {
    final n = container.read(selectedMonthControllerProvider.notifier);
    n.setMonth(const YearMonth(2026, 5));
    n.nextMonth();
    expect(container.read(selectedMonthControllerProvider),
        const YearMonth(2026, 6));
  });

  test('previousMonth moves back across year boundary', () {
    final n = container.read(selectedMonthControllerProvider.notifier);
    n.setMonth(const YearMonth(2026, 1));
    n.previousMonth();
    expect(container.read(selectedMonthControllerProvider),
        const YearMonth(2025, 12));
  });

  test('jumpToToday resets to current month', () {
    final n = container.read(selectedMonthControllerProvider.notifier);
    n.setMonth(const YearMonth(2020, 7));
    n.jumpToToday();
    final now = DateTime.now();
    expect(container.read(selectedMonthControllerProvider),
        YearMonth(now.year, now.month));
  });
}
