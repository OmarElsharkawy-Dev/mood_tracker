import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/enums/mood.dart';

class IntensitySlider extends StatelessWidget {
  const IntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.mood,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final Mood? mood;

  static const double _trackHeight = 4;
  static const double _thumbRadius = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trackColor =
        mood == null ? colors.primary : colors.moodColor(mood!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            '${context.l10n.logEntryFieldIntensity}: $value/10',
            style: AppTextStyles.label.copyWith(color: colors.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: trackColor,
            inactiveTrackColor: colors.surfaceVariant,
            thumbColor: trackColor,
            overlayColor: trackColor.withValues(alpha: 0.15),
            trackHeight: _trackHeight,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: _thumbRadius),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: _thumbRadius + 8),
            valueIndicatorColor: trackColor,
          ),
          child: Slider(
            min: 1,
            max: 10,
            divisions: 9,
            value: value.toDouble(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
