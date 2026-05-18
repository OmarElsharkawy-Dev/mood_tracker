import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/year_month.dart';

class SelectedMonthController extends Notifier<YearMonth> {
  @override
  YearMonth build() => YearMonth.fromDate(DateTime.now());

  void setMonth(YearMonth month) => state = month;
  void nextMonth() => state = state.next;
  void previousMonth() => state = state.previous;
  void jumpToToday() => state = YearMonth.fromDate(DateTime.now());
}

final selectedMonthControllerProvider =
    NotifierProvider<SelectedMonthController, YearMonth>(SelectedMonthController.new);
