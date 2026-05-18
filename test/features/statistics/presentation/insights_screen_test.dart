import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
import 'package:mood_tracker/features/statistics/presentation/screens/insights_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _EmptyRepo implements MoodEntryRepository {
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(const []);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const <MoodEntry>[], null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async => (entry, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async => (entry, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, {ProviderContainer? container}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = container ?? ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InsightsScreen(),
      ),
    ));
    await tester.pump();
  }

  testWidgets('renders title, range selector and 5 section titles', (tester) async {
    await pump(tester);
    expect(find.text('Insights'), findsWidgets);
    expect(find.text('Mood trend'), findsOneWidget);
    expect(find.text('Mood distribution'), findsOneWidget);
    expect(find.text('Top tags'), findsOneWidget);
    expect(find.text('Sleep vs. mood'), findsOneWidget);
    expect(find.text('Energy vs. mood'), findsOneWidget);
    expect(find.text('30d'), findsOneWidget);
  });

  testWidgets('filter banner shows when filter is active', (tester) async {
    final c = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    c.read(entryFilterProvider.notifier).setText('run');
    await pump(tester, container: c);
    expect(find.byKey(const ValueKey('active_filter_banner')), findsOneWidget);
  });
}
