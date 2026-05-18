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
      backgroundColor: context.appColors.surface,
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.filterTitle,
              style:
                  AppTextStyles.headline.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _textController,
              style: AppTextStyles.body.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceVariant,
                hintText: l10n.filterTextHint,
                hintStyle: AppTextStyles.body
                    .copyWith(color: colors.onSurfaceVariant),
                prefixIcon:
                    Icon(Icons.search, color: colors.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide:
                      BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() =>
                  _draft = _draft.copyWith(text: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: l10n.filterMoodRange),
            const SizedBox(height: AppSpacing.xs),
            MoodRangeSlider(
              range: _draft.moodRange,
              onChanged: (v) => setState(
                () => _draft = _draft.copyWith(moodRange: v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: l10n.filterDateRange),
            const SizedBox(height: AppSpacing.xs),
            DateRangeField(
              range: _draft.dateRange,
              onChanged: (v) => setState(
                () => _draft = _draft.copyWith(dateRange: v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(text: l10n.filterTags),
            const SizedBox(height: AppSpacing.xs),
            TagFilterChips(
              selectedIds: _draft.tagIds,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(tagIds: v)),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                onPressed: _apply,
                child: Text(
                  l10n.filterApply,
                  style: AppTextStyles.label
                      .copyWith(color: colors.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _clear,
                style:
                    TextButton.styleFrom(foregroundColor: colors.error),
                child: Text(
                  l10n.filterClear,
                  style:
                      AppTextStyles.label.copyWith(color: colors.error),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      text,
      style: AppTextStyles.label.copyWith(color: colors.onSurface),
    );
  }
}
