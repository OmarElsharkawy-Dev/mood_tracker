import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_month.dart';
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

MoodEntry _entry(
        {required String id, required DateTime at, Mood mood = Mood.good}) =>
    MoodEntry(
      id: id,
      occurredAt: at,
      mood: mood,
      intensity: 5,
      note: null,
      tags: const <Tag>[],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders 42 day cells in a month grid', (tester) async {
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

    // Let the stream emit first.
    await container.read(calendarEntriesProvider.future);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CalendarMonth(month: YearMonth(2026, 5))),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDayCell), findsNWidgets(42));
  });

  testWidgets('shows ×3 badge for a day with 3 entries', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo([
        _entry(id: 'a', at: DateTime(2026, 5, 10, 9)),
        _entry(id: 'b', at: DateTime(2026, 5, 10, 14)),
        _entry(id: 'c', at: DateTime(2026, 5, 10, 21)),
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
        home: const Scaffold(body: CalendarMonth(month: YearMonth(2026, 5))),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('×3'), findsOneWidget);
  });
}
