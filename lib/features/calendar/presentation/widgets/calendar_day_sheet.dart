import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../history/presentation/widgets/history_row.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';

class CalendarDaySheet extends StatelessWidget {
  const CalendarDaySheet({
    super.key,
    required this.date,
    required this.entries,
  });

  final DateTime date;
  final List<MoodEntry> entries;

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<MoodEntry> entries,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => CalendarDaySheet(date: date, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final fmt =
        DateFormat.yMMMMd(Localizations.localeOf(context).languageCode);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(fmt.format(date), style: AppTextStyles.title),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.calendarDayEmpty,
                  style: AppTextStyles.body.copyWith(color: colors.onMuted),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return HistoryRow(
                      entry: e,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.entryDetailFor(e.id));
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
