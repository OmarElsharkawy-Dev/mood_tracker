import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/selected_month_controller.dart';
import '../widgets/calendar_month.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final month = ref.watch(selectedMonthControllerProvider);
    final notifier = ref.read(selectedMonthControllerProvider.notifier);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat.yMMMM(localeTag).format(month.firstDay);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.navCalendar,
          style:
              AppTextStyles.headline.copyWith(color: colors.onBackground),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              _MonthNavRow(
                monthLabel: monthLabel,
                onPrev: notifier.previousMonth,
                onNext: notifier.nextMonth,
                onJumpToToday: notifier.jumpToToday,
                prevTooltip: l10n.calendarPrevMonth,
                nextTooltip: l10n.calendarNextMonth,
                todayLabel: l10n.calendarTodayButton,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: CalendarMonth(month: month)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthNavRow extends StatelessWidget {
  const _MonthNavRow({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
    required this.onJumpToToday,
    required this.prevTooltip,
    required this.nextTooltip,
    required this.todayLabel,
  });

  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onJumpToToday;
  final String prevTooltip;
  final String nextTooltip;
  final String todayLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: colors.primary,
          tooltip: prevTooltip,
          onPressed: onPrev,
        ),
        Text(
          monthLabel,
          style: AppTextStyles.title.copyWith(color: colors.onBackground),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: colors.primary,
          tooltip: nextTooltip,
          onPressed: onNext,
        ),
        const Spacer(),
        TextButton(
          onPressed: onJumpToToday,
          style: TextButton.styleFrom(foregroundColor: colors.primary),
          child: Text(
            todayLabel,
            style: AppTextStyles.label.copyWith(color: colors.primary),
          ),
        ),
      ],
    );
  }
}
