import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class MoodRangeSlider extends StatelessWidget {
  const MoodRangeSlider({
    super.key,
    required this.range,
    required this.onChanged,
  });

  /// `null` means the full range (filter not active on the mood dimension).
  final ({Mood min, Mood max})? range;
  final ValueChanged<({Mood min, Mood max})?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effective = range ?? (min: Mood.awful, max: Mood.great);
    final values = RangeValues(
      effective.min.index.toDouble(),
      effective.max.index.toDouble(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MoodFace(mood: effective.min, color: colors.onSurface, size: 28),
              Text(
                _label(effective),
                style: AppTextStyles.label.copyWith(color: colors.onSurfaceVariant),
              ),
              MoodFace(mood: effective.max, color: colors.onSurface, size: 28),
            ],
          ),
        ),
        RangeSlider(
          min: 0,
          max: (Mood.values.length - 1).toDouble(),
          divisions: Mood.values.length - 1,
          values: values,
          onChanged: (v) {
            final next = (
              min: Mood.values[v.start.round()],
              max: Mood.values[v.end.round()],
            );
            final isFullRange =
                next.min == Mood.awful && next.max == Mood.great;
            onChanged(isFullRange ? null : next);
          },
        ),
      ],
    );
  }

  String _label(({Mood min, Mood max}) r) {
    if (r.min == r.max) return r.min.name;
    return '${r.min.name} – ${r.max.name}';
  }
}
