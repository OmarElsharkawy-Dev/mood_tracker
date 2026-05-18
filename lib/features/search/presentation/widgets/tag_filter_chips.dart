import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../providers/all_tags_provider.dart';

class TagFilterChips extends ConsumerWidget {
  const TagFilterChips({
    super.key,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allTagsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox(height: AppSpacing.xs);
        return Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            for (final tag in tags)
              AppChip(
                label: tag.label,
                selected: selectedIds.contains(tag.id),
                onTap: () {
                  final next = selectedIds.contains(tag.id)
                      ? selectedIds.where((id) => id != tag.id).toList()
                      : [...selectedIds, tag.id];
                  onChanged(next);
                },
              ),
          ],
        );
      },
    );
  }
}
