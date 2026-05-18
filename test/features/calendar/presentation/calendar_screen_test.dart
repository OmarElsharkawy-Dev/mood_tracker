import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_day_sheet.dart';
import 'package:mood_tracker/features/calendar/providers/calendar_entries_provider.dart';
import 'package:mood_tracker/features/calendar/providers/selected_month_controller.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _StubRepo implements MoodEntryRepository {
  _StubRepo(this._entries);
  final List<MoodEntry> _entries;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) =>
      Stream.value(_entries);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_entries, null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

MoodEntry _entry({required String id, required DateTime at}) => MoodEntry(
      id: id,
      occurredAt: at,
      mood: Mood.good,
      intensity: 5,
      note: 'sample',
      tags: const <Tag>[],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders month title and navigation actions', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo(const [])),
    ]);
    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));
    addTearDown(container.dispose);

    await container.read(calendarEntriesProvider.future);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('May 2026'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('tapping a day with entries opens CalendarDaySheet',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo([
        _entry(id: 'a', at: DateTime(2026, 5, 10, 14)),
      ])),
    ]);
    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));
    addTearDown(container.dispose);

    await container.read(calendarEntriesProvider.future);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDaySheet), findsOneWidget);
  });
}
