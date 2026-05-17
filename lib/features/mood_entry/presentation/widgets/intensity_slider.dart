import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class IntensitySlider extends StatelessWidget {
  const IntensitySlider({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.logEntryFieldIntensity,
                style: AppTextStyles.label.copyWith(color: colors.onMuted)),
            Text('$value',
                style: AppTextStyles.title.copyWith(color: colors.onSurface)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Slider(
          min: 1,
          max: 10,
          divisions: 9,
          value: value.toDouble(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
