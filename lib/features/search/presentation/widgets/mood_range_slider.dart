import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
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

  static const double _thumbRadius = 10;
  static const double _trackHeight = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
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
              MoodFace(
                mood: effective.min,
                color: colors.moodColor(effective.min),
                size: 28,
              ),
              Text(
                _label(l10n, effective),
                style: AppTextStyles.label
                    .copyWith(color: colors.onSurfaceVariant),
              ),
              MoodFace(
                mood: effective.max,
                color: colors.moodColor(effective.max),
                size: 28,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Gradient track painted behind the (transparent) slider track.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: _thumbRadius),
                  child: Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(_trackHeight / 2),
                      gradient: LinearGradient(
                        colors: [
                          for (final m in Mood.values) colors.moodColor(m),
                        ],
                      ),
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: _trackHeight,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    rangeTrackShape: _NoTrackShape(),
                    rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: _thumbRadius,
                    ),
                    thumbColor: colors.onSurface,
                    overlayColor: colors.primary.withValues(alpha: 0.15),
                    rangeTickMarkShape:
                        const RoundRangeSliderTickMarkShape(tickMarkRadius: 0),
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: RangeSlider(
                    min: 0,
                    max: (Mood.values.length - 1).toDouble(),
                    divisions: Mood.values.length - 1,
                    values: values,
                    onChanged: (v) {
                      final next = (
                        min: Mood.values[v.start.round()],
                        max: Mood.values[v.end.round()],
                      );
                      final isFullRange = next.min == Mood.awful &&
                          next.max == Mood.great;
                      onChanged(isFullRange ? null : next);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _label(AppLocalizations l10n, ({Mood min, Mood max}) r) {
    if (r.min == r.max) return _name(l10n, r.min);
    return '${_name(l10n, r.min)} – ${_name(l10n, r.max)}';
  }

  String _name(AppLocalizations l10n, Mood mood) => switch (mood) {
        Mood.awful => l10n.moodAwful,
        Mood.bad => l10n.moodBad,
        Mood.okay => l10n.moodOkay,
        Mood.good => l10n.moodGood,
        Mood.great => l10n.moodGreat,
      };
}

/// A range-slider track shape that paints nothing — we draw the gradient
/// track in a separate widget below the slider.
class _NoTrackShape extends RangeSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackLeft = offset.dx;
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    // Intentionally paints nothing — gradient is rendered behind by parent.
  }
}
