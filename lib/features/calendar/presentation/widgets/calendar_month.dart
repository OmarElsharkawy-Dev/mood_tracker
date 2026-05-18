import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../domain/year_month.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../providers/calendar_entries_provider.dart';
import '../../providers/day_summaries_provider.dart';
import 'calendar_day_cell.dart';
import 'calendar_day_sheet.dart';

class CalendarMonth extends ConsumerWidget {
  const CalendarMonth({super.key, required this.month});

  final YearMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(daySummariesProvider);
    final asyncEntries = ref.watch(calendarEntriesProvider);
    final entries = asyncEntries.maybeWhen(
      data: (e) => e,
      orElse: () => const <MoodEntry>[],
    );

    final firstDayOfMonth = month.firstDay;
    final daysInMonth = month.lastDay.day;
    final weekdayOfFirst = firstDayOfMonth.weekday % 7; // Sun = 0
    final today = startOfDay(DateTime.now());
    final locale = Localizations.localeOf(context).languageCode;
    final weekdayLabels = _weekdayLabels(locale);

    final cells = <Widget>[];
    const totalCells = 42; // 6 rows × 7 cols
    for (var i = 0; i < totalCells; i++) {
      final dayOffset = i - weekdayOfFirst;
      final cellDate = firstDayOfMonth.add(Duration(days: dayOffset));
      final isCurrentMonth = dayOffset >= 0 && dayOffset < daysInMonth;
      final isToday = cellDate.year == today.year &&
          cellDate.month == today.month &&
          cellDate.day == today.day;
      final key = startOfDay(cellDate);
      final summary = isCurrentMonth ? summaries[key] : null;

      cells.add(
        CalendarDayCell(
          date: cellDate,
          summary: summary,
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          onTap: () {
            final dayEntries = entries
                .where((e) => startOfDay(e.occurredAt) == key)
                .toList();
            CalendarDaySheet.show(context,
                date: cellDate, entries: dayEntries);
          },
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map((label) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ))
              .toList(),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            childAspectRatio: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ),
      ],
    );
  }

  List<String> _weekdayLabels(String localeTag) {
    final fmt = DateFormat.E(localeTag);
    final sunday = DateTime(2024, 1, 7); // Jan 7 2024 was a Sunday.
    return List.generate(7, (i) => fmt.format(sunday.add(Duration(days: i))));
  }
}
