import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/history/presentation/widgets/active_filter_banner.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders nothing when filter is inactive', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ActiveFilterBanner()),
      ),
    ));
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('renders count + Clear button when filter is active', (tester) async {
    final container = ProviderContainer();
    container.read(entryFilterProvider.notifier).setText('hike');
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ActiveFilterBanner()),
      ),
    ));

    expect(find.text('1 filter active'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(container.read(entryFilterProvider).isActive, isFalse);
  });
}
