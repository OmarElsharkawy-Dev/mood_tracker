import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../domain/accessibility_summaries.dart';
import '../../domain/correlation.dart';

class CorrelationChart extends StatelessWidget {
  const CorrelationChart({super.key, required this.data});

  final CorrelationView data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxAvg = data.buckets.fold<double>(
        0, (a, b) => (b.averageMood ?? 0) > a ? b.averageMood! : a);
    final maxY = maxAvg < 5 ? 5.0 : maxAvg;

    final axisStyle = AppTextStyles.caption.copyWith(
      color: colors.onSurfaceVariant,
      fontSize: 11,
    );

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.outline.withValues(alpha: 0.4),
              strokeWidth: 1,
              dashArray: const [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: axisStyle,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labelForBucketKey(
                        data.buckets[i].bucketLabelKey, context.l10n),
                    style: axisStyle,
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.surfaceVariant,
              tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
              getTooltipItem: (group, gIdx, rod, rIdx) => BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                AppTextStyles.bodySmall.copyWith(color: colors.onSurface),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.buckets.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data.buckets[i].averageMood ?? 0,
                  color: data.buckets[i].sampleSize == 0
                      ? colors.surfaceVariant
                      : colors.moodColor(_moodFromScore(
                          data.buckets[i].averageMood ?? 3.0)),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sm),
                  ),
                ),
              ]),
          ],
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }

  static Mood _moodFromScore(double score) {
    final i = score.round().clamp(1, 5) - 1;
    return Mood.values[i];
  }
}

/// Mood-color legend rendered under the sleep/energy correlation charts.
class MoodLegend extends StatelessWidget {
  const MoodLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xxs,
      alignment: WrapAlignment.center,
      children: [
        for (final mood in Mood.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.moodColor(mood),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                _label(l10n, mood),
                style: AppTextStyles.caption
                    .copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
      ],
    );
  }

  String _label(AppLocalizations l10n, Mood mood) => switch (mood) {
        Mood.awful => l10n.moodAwful,
        Mood.bad => l10n.moodBad,
        Mood.okay => l10n.moodOkay,
        Mood.good => l10n.moodGood,
        Mood.great => l10n.moodGreat,
      };
}
