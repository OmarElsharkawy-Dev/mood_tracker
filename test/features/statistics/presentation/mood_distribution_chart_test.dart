import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/mood_distribution.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/mood_distribution_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders 5 bars including zero-count buckets', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final d = MoodDistribution(counts: const {
      Mood.awful: 0,
      Mood.bad: 1,
      Mood.okay: 2,
      Mood.good: 3,
      Mood.great: 4,
    }, total: 10);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: MoodDistributionChart(data: d))),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
