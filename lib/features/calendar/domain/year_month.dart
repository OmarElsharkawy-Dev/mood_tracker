import 'package:flutter/foundation.dart';

@immutable
class YearMonth {
  const YearMonth(this.year, this.month);

  factory YearMonth.fromDate(DateTime d) => YearMonth(d.year, d.month);

  final int year;
  final int month;

  YearMonth get next =>
      month == 12 ? YearMonth(year + 1, 1) : YearMonth(year, month + 1);

  YearMonth get previous =>
      month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);

  DateTime get firstDay => DateTime(year, month);
  DateTime get lastDay => DateTime(year, month + 1, 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearMonth && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'YearMonth($year, $month)';
}
