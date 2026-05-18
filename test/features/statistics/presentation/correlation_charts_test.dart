import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/statistics/domain/correlation.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/energy_correlation_chart.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/sleep_correlation_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

CorrelationView _sleepView() => const CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucketUnder6', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket6to7', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket7to8', sampleSize: 2, averageMood: 3.5),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket8to9', sampleSize: 1, averageMood: 4.0),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket9plus', sampleSize: 0, averageMood: null),
    ]);

CorrelationView _energyView() => const CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'energyVeryLow', sampleSize: 1, averageMood: 2.0),
      CorrelationBucket(bucketLabelKey: 'energyLow', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyMedium', sampleSize: 3, averageMood: 4.0),
      CorrelationBucket(bucketLabelKey: 'energyHigh', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyVeryHigh', sampleSize: 0, averageMood: null),
    ]);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> wrap(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: child)),
    ));
    await tester.pump();
  }

  testWidgets('SleepCorrelationChart renders', (tester) async {
    await wrap(tester, SleepCorrelationChart(data: _sleepView()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('EnergyCorrelationChart renders', (tester) async {
    await wrap(tester, EnergyCorrelationChart(data: _energyView()));
    expect(tester.takeException(), isNull);
  });
}
