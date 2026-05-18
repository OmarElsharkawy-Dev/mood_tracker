import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/insights_range.dart';
import '../../providers/selected_range_controller.dart';

class RangeSelector extends ConsumerWidget {
  const RangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selected = ref.watch(selectedRangeProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (final r in InsightsRange.values)
            Expanded(
              child: _RangeSegment(
                label: _label(context, r),
                isSelected: r == selected,
                onTap: () =>
                    ref.read(selectedRangeProvider.notifier).set(r),
              ),
            ),
        ],
      ),
    );
  }

  String _label(BuildContext context, InsightsRange r) {
    final l = context.l10n;
    switch (r) {
      case InsightsRange.d7:
        return l.insightsRange7d;
      case InsightsRange.d30:
        return l.insightsRange30d;
      case InsightsRange.d90:
        return l.insightsRange90d;
      case InsightsRange.all:
        return l.insightsRangeAll;
    }
  }
}

class _RangeSegment extends StatelessWidget {
  const _RangeSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
