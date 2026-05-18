import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../../mood_entry/domain/enums/mood.dart';

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
      backgroundColor: context.appColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => CalendarDaySheet(date: date, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final headerFmt = DateFormat('EEEE, MMMM d', localeTag);
    final timeFmt = DateFormat.jm(localeTag);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                headerFmt.format(date),
                style: AppTextStyles.headline
                    .copyWith(color: colors.onSurface),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Text(
                  l10n.calendarDayEmpty,
                  style: AppTextStyles.body
                      .copyWith(color: colors.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => Divider(
                    color: colors.outline,
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return _DayEntryRow(
                      entry: e,
                      timeFmt: timeFmt,
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

class _DayEntryRow extends StatelessWidget {
  const _DayEntryRow({
    required this.entry,
    required this.timeFmt,
    required this.onTap,
  });

  final MoodEntry entry;
  final DateFormat timeFmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final moodColor = colors.moodColor(entry.mood);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            MoodFace(mood: entry.mood, size: 32, color: moodColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _moodLabel(context.l10n, entry.mood),
                style: AppTextStyles.label
                    .copyWith(color: colors.onSurface),
              ),
            ),
            Text(
              timeFmt.format(entry.occurredAt),
              style: AppTextStyles.bodySmall
                  .copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _moodLabel(AppLocalizations l10n, Mood mood) => switch (mood) {
        Mood.awful => l10n.moodAwful,
        Mood.bad => l10n.moodBad,
        Mood.okay => l10n.moodOkay,
        Mood.good => l10n.moodGood,
        Mood.great => l10n.moodGreat,
      };
}
