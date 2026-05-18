import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../search/providers/entry_filter_controller.dart';

class ActiveFilterBanner extends ConsumerWidget {
  const ActiveFilterBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(entryFilterProvider);
    if (!filter.isActive) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colors = context.appColors;

    return Container(
      color: colors.muted,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 18, color: colors.onMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.filterActiveCount(filter.activeCount),
              style: AppTextStyles.bodySmall.copyWith(color: colors.onMuted),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(entryFilterProvider.notifier).clear(),
            child: Text(l10n.filterClear),
          ),
        ],
      ),
    );
  }
}
