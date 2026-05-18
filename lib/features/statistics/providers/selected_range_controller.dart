import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/insights_range.dart';

class SelectedRangeController extends Notifier<InsightsRange> {
  @override
  InsightsRange build() => InsightsRange.d30;

  void set(InsightsRange range) => state = range;
}

final selectedRangeProvider =
    NotifierProvider<SelectedRangeController, InsightsRange>(
        SelectedRangeController.new);
