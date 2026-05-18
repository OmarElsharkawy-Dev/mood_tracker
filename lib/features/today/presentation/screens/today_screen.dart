import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../providers/today_controller.dart';
import '../widgets/quick_log_row.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final now = DateTime.now();
    final greeting = switch (greetingFor(now)) {
      'morning' => l10n.todayGreetingMorning,
      'afternoon' => l10n.todayGreetingAfternoon,
      _ => l10n.todayGreetingEvening,
    };
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateText = DateFormat.yMMMMEEEEd(localeTag).format(now);
    final async = ref.watch(recentEntriesProvider);
    final todayMood = _todaysMood(async.value, now);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        onPressed: () => context.push(AppRoutes.log),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTextStyles.headline
                    .copyWith(color: colors.onBackground),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                dateText,
                style: AppTextStyles.bodySmall
                    .copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm),
                      child: Text(l10n.todayPrompt, style: AppTextStyles.body),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    QuickLogRow(
                      selectedMood: todayMood,
                      onPick: (mood) =>
                          context.push(AppRoutes.logWithMood(mood)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.todayRecentTitle, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              async.when(
                loading: () => Skeletonizer(
                  child: Column(
                    children: List.generate(3, (_) => _recentSkeleton()),
                  ),
                ),
                error: (error, stack) => const SizedBox.shrink(),
                data: (entries) {
                  if (entries.isEmpty) {
                    return EmptyStateView(
                      title: '',
                      message: l10n.todayEmptyMessage,
                    );
                  }
                  return Column(
                    children: [
                      for (final e in entries) _recentRow(context, e),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Mood? _todaysMood(List<MoodEntry>? entries, DateTime now) {
    if (entries == null || entries.isEmpty) return null;
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    for (final e in entries) {
      if (!e.occurredAt.isBefore(start) && e.occurredAt.isBefore(end)) {
        return e.mood;
      }
    }
    return null;
  }

  Widget _recentSkeleton() => const ListTile(
        leading: MoodDot(mood: Mood.okay, size: 14),
        title: Text('placeholder time'),
        subtitle: Text('placeholder note'),
      );

  Widget _recentRow(BuildContext context, MoodEntry e) {
    final fmt = DateFormat.MMMd().add_jm();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: MoodDot(mood: e.mood, size: 14),
      title: Text(fmt.format(e.occurredAt), style: AppTextStyles.body),
      subtitle: Text(
        e.note ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall
            .copyWith(color: context.appColors.onSurfaceVariant),
      ),
      onTap: () => context.push(AppRoutes.entryDetailFor(e.id)),
    );
  }
}
