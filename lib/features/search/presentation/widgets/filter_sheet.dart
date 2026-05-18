import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entry_filter.dart';
import '../../providers/entry_filter_controller.dart';
import 'date_range_field.dart';
import 'mood_range_slider.dart';
import 'tag_filter_chips.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late EntryFilter _draft;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(entryFilterProvider);
    _textController = TextEditingController(text: _draft.text ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(entryFilterProvider.notifier).replace(_draft);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _draft = EntryFilter.empty;
      _textController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.filterTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.filterTextHint,
              ),
              onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(text: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.filterMoodRange, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            MoodRangeSlider(
              range: _draft.moodRange,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(moodRange: v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.filterDateRange, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            DateRangeField(
              range: _draft.dateRange,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(dateRange: v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.filterTags, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            TagFilterChips(
              selectedIds: _draft.tagIds,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(tagIds: v)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                TextButton(
                  onPressed: _clear,
                  child: Text(l10n.filterClear),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _apply,
                  child: Text(l10n.filterApply),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
