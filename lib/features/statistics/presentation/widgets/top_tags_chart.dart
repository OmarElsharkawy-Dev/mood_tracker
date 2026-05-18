import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/top_tags_view.dart';

class TopTagsChart extends StatelessWidget {
  const TopTagsChart({super.key, required this.data});

  final TopTagsView data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxCount = data.entries.fold<int>(0, (a, e) => a > e.count ? a : e.count);
    final maxY = (maxCount == 0 ? 1 : maxCount).toDouble();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      data.entries[i].tag.label,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: true),
          barGroups: [
            for (var i = 0; i < data.entries.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data.entries[i].count.toDouble(),
                  color: colors.primary,
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]),
          ],
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }
}
