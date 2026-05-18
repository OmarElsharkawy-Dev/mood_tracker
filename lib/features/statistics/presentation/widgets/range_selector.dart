import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/insights_range.dart';
import '../../providers/selected_range_controller.dart';

class RangeSelector extends ConsumerWidget {
  const RangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedRangeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final r in InsightsRange.values) ...[
            AppChip(
              label: _label(context, r),
              selected: r == selected,
              onTap: () => ref.read(selectedRangeProvider.notifier).set(r),
            ),
            if (r != InsightsRange.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
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
