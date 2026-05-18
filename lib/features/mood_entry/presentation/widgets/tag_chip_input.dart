import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/uuid.dart';
import '../../../search/providers/all_tags_provider.dart';
import '../../domain/entities/tag.dart';

class TagChipInput extends ConsumerStatefulWidget {
  const TagChipInput({super.key, required this.tags, required this.onChanged});

  final List<Tag> tags;
  final ValueChanged<List<Tag>> onChanged;

  @override
  ConsumerState<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends ConsumerState<TagChipInput> {
  final _controller = TextEditingController();
  static const _suggestionCap = 8;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final label = raw.trim();
    if (label.isEmpty) return;
    final slug = Tag.slugify(label);
    if (widget.tags.any((t) => t.slug == slug)) {
      _controller.clear();
      return;
    }
    widget.onChanged([
      ...widget.tags,
      Tag(id: generateId(), slug: slug, label: label),
    ]);
    _controller.clear();
  }

  void _addExisting(Tag tag) {
    if (widget.tags.any((t) => t.slug == tag.slug)) return;
    widget.onChanged([...widget.tags, tag]);
  }

  void _remove(Tag tag) {
    widget.onChanged(widget.tags.where((t) => t.id != tag.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final allTagsAsync = ref.watch(allTagsProvider);
    final currentSlugs = widget.tags.map((t) => t.slug).toSet();
    final suggestions = allTagsAsync
        .maybeWhen(data: (list) => list, orElse: () => const <Tag>[])
        .where((t) => !currentSlugs.contains(t.slug))
        .take(_suggestionCap)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.logEntryFieldTags,
          style: AppTextStyles.label.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tag in widget.tags)
              _ActiveTagChip(tag: tag, onRemove: () => _remove(tag)),
            _InlineTagInput(
              controller: _controller,
              hintText: l10n.logEntryTagAddHint,
              onSubmit: _add,
            ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in suggestions)
                _SuggestionTagChip(tag: tag, onAdd: () => _addExisting(tag)),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActiveTagChip extends StatelessWidget {
  const _ActiveTagChip({required this.tag, required this.onRemove});

  final Tag tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.label,
              style: AppTextStyles.label.copyWith(color: colors.onSurface),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Icon(Icons.close, size: 14, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTagChip extends StatelessWidget {
  const _SuggestionTagChip({required this.tag, required this.onAdd});

  final Tag tag;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          tag.label,
          style: AppTextStyles.label.copyWith(color: colors.primary),
        ),
      ),
    );
  }
}

class _InlineTagInput extends StatelessWidget {
  const _InlineTagInput({
    required this.controller,
    required this.hintText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 140,
      child: TextField(
        controller: controller,
        style: AppTextStyles.label.copyWith(color: colors.onSurface),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: AppTextStyles.label.copyWith(color: colors.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.outline),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
        onSubmitted: onSubmit,
      ),
    );
  }
}
