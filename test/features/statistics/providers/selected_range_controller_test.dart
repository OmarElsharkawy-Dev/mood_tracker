import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/providers/selected_range_controller.dart';

void main() {
  test('default is d30', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(selectedRangeProvider), InsightsRange.d30);
  });

  test('setter updates state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d90);
    expect(container.read(selectedRangeProvider), InsightsRange.d90);
  });
}
