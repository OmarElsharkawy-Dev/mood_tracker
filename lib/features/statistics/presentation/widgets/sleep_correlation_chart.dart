import 'package:flutter/material.dart';

import '../../domain/correlation.dart';
import 'correlation_chart.dart';

class SleepCorrelationChart extends StatelessWidget {
  const SleepCorrelationChart({super.key, required this.data});
  final CorrelationView data;

  @override
  Widget build(BuildContext context) => CorrelationChart(data: data);
}
