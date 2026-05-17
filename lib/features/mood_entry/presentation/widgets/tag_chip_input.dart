import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/uuid.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/entities/tag.dart';

class TagChipInput extends StatefulWidget {
  const TagChipInput({super.key, required this.tags, required this.onChanged});

  final List<Tag> tags;
  final ValueChanged<List<Tag>> onChanged;

  @override
  State<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends State<TagChipInput> {
  final _controller = TextEditingController();

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

  void _remove(Tag tag) {
    widget.onChanged(widget.tags.where((t) => t.id != tag.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.logEntryFieldTags, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            for (final t in widget.tags)
              AppChip(
                label: t.label,
                selected: true,
                onTap: () => _remove(t),
                trailing: const Icon(Icons.close, size: 14),
              ),
          ],
        ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: '+'),
          onSubmitted: _add,
        ),
      ],
    );
  }
}
