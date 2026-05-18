import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../domain/year_month.dart';
import '../../providers/calendar_entries_provider.dart';
import '../../providers/day_summaries_provider.dart';
import 'calendar_day_cell.dart';
import 'calendar_day_sheet.dart';

/// Monday-aligned anchor used to render narrow weekday labels (M T W T F S S).
/// Jan 1, 2024 was a Monday.
final _mondayAnchor = DateTime(2024, 1, 1);

class CalendarMonth extends ConsumerWidget {
  const CalendarMonth({super.key, required this.month});

  final YearMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final summaries = ref.watch(daySummariesProvider);
    final asyncEntries = ref.watch(calendarEntriesProvider);
    final entries = asyncEntries.maybeWhen(
      data: (e) => e,
      orElse: () => const <MoodEntry>[],
    );

    final firstDayOfMonth = month.firstDay;
    final daysInMonth = month.lastDay.day;
    // Monday-first column index of the 1st of the month.
    final weekdayOfFirst = (firstDayOfMonth.weekday - 1) % 7;
    final today = startOfDay(DateTime.now());
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final weekdayLabels = _narrowWeekdayLabels(localeTag);

    final cells = <Widget>[];
    const totalCells = 42;
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
            CalendarDaySheet.show(
              context,
              date: cellDate,
              entries: dayEntries,
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.label
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: AppSpacing.xxs,
            crossAxisSpacing: AppSpacing.xxs,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ),
      ],
    );
  }

  List<String> _narrowWeekdayLabels(String localeTag) {
    final fmt = DateFormat('EEEEE', localeTag);
    return List.generate(
      7,
      (i) => fmt.format(_mondayAnchor.add(Duration(days: i))),
    );
  }
}
