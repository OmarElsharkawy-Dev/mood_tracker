import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../domain/mood_distribution.dart';

class MoodDistributionChart extends StatelessWidget {
  const MoodDistributionChart({super.key, required this.data});

  final MoodDistribution data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxCount =
        data.counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxCount == 0 ? 1 : maxCount).toDouble();

    Color barColor(Mood m) => colors.moodColor(m);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= Mood.values.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _label(Mood.values[i]),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: true),
          barGroups: [
            for (var i = 0; i < Mood.values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (data.counts[Mood.values[i]] ?? 0).toDouble(),
                  color: data.counts[Mood.values[i]] == 0
                      ? colors.surfaceVariant
                      : barColor(Mood.values[i]),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ]),
          ],
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }

  static String _label(Mood m) {
    switch (m) {
      case Mood.awful:
        return '1';
      case Mood.bad:
        return '2';
      case Mood.okay:
        return '3';
      case Mood.good:
        return '4';
      case Mood.great:
        return '5';
    }
  }
}
