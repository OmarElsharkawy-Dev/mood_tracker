import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/correlation.dart';
import 'correlation_chart.dart';

class EnergyCorrelationChart extends StatelessWidget {
  const EnergyCorrelationChart({super.key, required this.data});

  final CorrelationView data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CorrelationChart(data: data),
        const SizedBox(height: AppSpacing.sm),
        const MoodLegend(),
      ],
    );
  }
}
