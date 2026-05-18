import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/insights_entries_provider.dart';

class InsightSectionCard<T> extends ConsumerWidget {
  const InsightSectionCard({
    super.key,
    required this.title,
    required this.value,
    required this.isEmpty,
    required this.emptyMessage,
    required this.builder,
    this.accessibilitySummary,
  });

  final String title;
  final AsyncValue<T> value;
  final bool Function(T value) isEmpty;
  final String emptyMessage;
  final Widget Function(T value) builder;
  final String? accessibilitySummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBR),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            value.when(
              loading: () => Skeletonizer(
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              error: (err, st) => SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: colors.onSurfaceVariant),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(insightsEntriesProvider),
                        child: Text(context.l10n.errorRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                if (isEmpty(data)) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      emptyMessage,
                      style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
                    ),
                  );
                }
                final child = builder(data);
                if (accessibilitySummary == null) return child;
                return Semantics(
                  label: accessibilitySummary,
                  container: true,
                  child: ExcludeSemantics(child: child),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
