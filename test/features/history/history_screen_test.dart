import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/history/presentation/screens/history_screen.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
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
  testWidgets('shows empty state when no entries', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged yet.'), findsOneWidget);
  });

  testWidgets('shows no-matches empty state when filter is active and list is empty',
      (tester) async {
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    container.read(entryFilterProvider.notifier).setText('nonexistent');
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Nothing matches the current filter.'), findsOneWidget);
    expect(find.text('Clear'), findsWidgets); // banner + empty-state action
  });
}
