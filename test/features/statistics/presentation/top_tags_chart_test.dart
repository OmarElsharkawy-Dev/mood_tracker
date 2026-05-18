import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/statistics/domain/top_tags_view.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/top_tags_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders top tags without throwing', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final v = TopTagsView(entries: [
      TopTagEntry(tag: const Tag(id: 'w', slug: 'work', label: 'work'), count: 5),
      TopTagEntry(tag: const Tag(id: 'f', slug: 'family', label: 'family'), count: 3),
    ], totalTaggedEntries: 8);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: TopTagsChart(data: v))),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('work'), findsOneWidget);
    expect(find.text('family'), findsOneWidget);
  });
}
