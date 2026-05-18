import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
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

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
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
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: true),
          barGroups: [
            for (var i = 0; i < data.buckets.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data.buckets[i].averageMood ?? 0,
                  color: data.buckets[i].sampleSize == 0
                      ? colors.surfaceVariant
                      : colors.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ]),
          ],
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }
}
