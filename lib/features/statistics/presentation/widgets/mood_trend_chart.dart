import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../domain/mood_trend.dart';

class MoodTrendChart extends StatelessWidget {
  const MoodTrendChart({super.key, required this.series});

  final MoodTrendSeries series;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Split into contiguous segments at gap days so the line doesn't span gaps.
    final segments = <List<FlSpot>>[];
    var current = <FlSpot>[];
    for (var i = 0; i < series.points.length; i++) {
      final p = series.points[i];
      if (p.averageMood == null) {
        if (current.isNotEmpty) {
          segments.add(current);
          current = [];
        }
      } else {
        current.add(FlSpot(i.toDouble(), p.averageMood!));
      }
    }
    if (current.isNotEmpty) segments.add(current);

    final maxX = series.points.isEmpty
        ? 1.0
        : (series.points.length - 1).toDouble().clamp(1.0, double.infinity);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          minX: 0,
          maxX: maxX,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _bottomInterval(series.points.length),
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= series.points.length) {
                    return const SizedBox.shrink();
                  }
                  final d = series.points[idx].day;
                  return Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final seg in segments)
              LineChartBarData(
                spots: seg,
                isCurved: true,
                color: colors.primary,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
          ],
          lineTouchData: const LineTouchData(enabled: true),
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }

  static double _bottomInterval(int days) {
    if (days <= 8) return 1;
    if (days <= 32) return (days / 4).floorToDouble();
    return (days / 6).floorToDouble();
  }
}
