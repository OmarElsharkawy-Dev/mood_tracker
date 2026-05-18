import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../domain/day_mood_summary.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.summary,
    required this.isCurrentMonth,
    required this.isToday,
    this.onTap,
  });

  final DateTime date;
  final DayMoodSummary? summary;
  final bool isCurrentMonth;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final opacity = isCurrentMonth ? 1.0 : 0.4;
    final dayNumberStyle = AppTextStyles.caption.copyWith(
      color: colors.onSurface,
      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
    );

    return InkWell(
      onTap: (isCurrentMonth && summary != null) ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 6,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.primary, width: 1.5),
                      )
                    : null,
                child: Text('${date.day}', style: dayNumberStyle),
              ),
            ),
            if (summary != null) ...[
              Center(child: MoodDot(mood: summary!.averageMood, size: 12)),
              if (summary!.entryCount > 1)
                Positioned(
                  top: 4,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${summary!.entryCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
