import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../mood_entry/domain/enums/mood.dart';
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

    final axisStyle = AppTextStyles.caption.copyWith(
      color: colors.onSurfaceVariant,
      fontSize: 11,
    );

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          minX: 0,
          maxX: maxX,
          gridData: _dashedGrid(colors),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
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
                  return Text('${d.month}/${d.day}', style: axisStyle);
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
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3.5,
                    color: colors.moodColor(_moodFromScore(spot.y)),
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: colors.primary.withValues(alpha: 0.08),
                ),
              ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colors.surfaceVariant,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        s.y.toStringAsFixed(1),
                        AppTextStyles.bodySmall
                            .copyWith(color: colors.onSurface),
                      ))
                  .toList(),
            ),
          ),
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }

  static Mood _moodFromScore(double score) {
    final i = score.round().clamp(1, 5) - 1;
    return Mood.values[i];
  }

  static FlGridData _dashedGrid(AppColors colors) => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colors.outline.withValues(alpha: 0.4),
          strokeWidth: 1,
          dashArray: const [4, 4],
        ),
      );

  static double _bottomInterval(int days) {
    if (days <= 8) return 1;
    if (days <= 32) return (days / 4).floorToDouble();
    return (days / 6).floorToDouble();
  }
}
