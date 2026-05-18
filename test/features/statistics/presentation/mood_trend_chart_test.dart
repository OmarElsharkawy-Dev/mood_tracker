import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/domain/mood_trend.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/mood_trend_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders without throwing for non-empty series', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final series = MoodTrendSeries(range: InsightsRange.d7, points: [
      MoodTrendPoint(day: DateTime(2026, 5, 12), averageMood: 3, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 13), averageMood: null, entryCount: 0),
      MoodTrendPoint(day: DateTime(2026, 5, 14), averageMood: 4, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 15), averageMood: 5, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 16), averageMood: null, entryCount: 0),
      MoodTrendPoint(day: DateTime(2026, 5, 17), averageMood: 2, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 18), averageMood: 3, entryCount: 1),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: MoodTrendChart(series: series))),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
