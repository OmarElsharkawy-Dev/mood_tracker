import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../providers/selected_month_controller.dart';
import '../widgets/calendar_month.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedMonthControllerProvider);
    final notifier = ref.read(selectedMonthControllerProvider.notifier);
    final locale = Localizations.localeOf(context).languageCode;
    final title = DateFormat.yMMMM(locale).format(month.firstDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.calendarPrevMonth,
            onPressed: notifier.previousMonth,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.calendarNextMonth,
            onPressed: notifier.nextMonth,
          ),
          PopupMenuButton<String>(
            onSelected: (_) => notifier.jumpToToday(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'today',
                child: Text(l10n.calendarJumpToToday),
              ),
            ],
          ),
        ],
      ),
      body: CalendarMonth(month: month),
    );
  }
}
