import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/insight_section_card.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(child: Scaffold(body: card)),
    ));
    await tester.pump();
  }

  testWidgets('loading state renders title but not value', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: const AsyncValue.loading(),
        isEmpty: (v) => false,
        emptyMessage: 'empty',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.text('T'), findsOneWidget);
    expect(find.text('value: 0'), findsNothing);
  });

  testWidgets('error state shows error icon', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: AsyncValue.error(const DatabaseFailure(), StackTrace.empty),
        isEmpty: (v) => false,
        emptyMessage: 'empty',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('empty state shows the emptyMessage', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: const AsyncValue.data(0),
        isEmpty: (v) => true,
        emptyMessage: 'empty message',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.text('empty message'), findsOneWidget);
  });

  testWidgets('data state calls builder', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: const AsyncValue.data(42),
        isEmpty: (v) => false,
        emptyMessage: 'empty',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.text('value: 42'), findsOneWidget);
  });
}
