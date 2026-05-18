import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
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

  static const double _dayCircleSize = 24;
  static const double _moodDotSize = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tappable = isCurrentMonth && summary != null;
    final cell = Container(
      decoration: BoxDecoration(
        color: isCurrentMonth ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: _dayCircleSize,
              height: _dayCircleSize,
              alignment: Alignment.center,
              decoration: isToday
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: colors.primary, width: 2),
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: AppTextStyles.label
                    .copyWith(color: colors.onSurface),
              ),
            ),
          ),
          if (summary != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Container(
                  width: _moodDotSize,
                  height: _moodDotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.moodColor(summary!.averageMood),
                  ),
                ),
              ),
            ),
          if (summary != null && summary!.entryCount > 1)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '×${summary!.entryCount}',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Opacity(
      opacity: isCurrentMonth ? 1.0 : 0.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: tappable ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          splashColor: colors.primary.withValues(alpha: 0.1),
          child: cell,
        ),
      ),
    );
  }
}
