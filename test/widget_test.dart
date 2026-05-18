import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/data/backup_service_provider.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/presentation/screens/backup_screen.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:mood_tracker/features/reminders/data/notification_service_provider.dart';
import 'package:mood_tracker/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:mood_tracker/features/statistics/presentation/screens/insights_screen.dart';
import 'package:mood_tracker/features/today/presentation/screens/today_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Today screen renders against the wired-up provider graph',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TodayScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling right now?'), findsOneWidget);
  });

  testWidgets('Insights screen renders against empty repo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InsightsScreen(),
      ),
    ));
    await tester.pump();
    expect(find.text('Mood trend'), findsOneWidget);
    expect(find.text('Energy vs. mood'), findsOneWidget);
  });

  testWidgets('Reminders screen renders against empty prefs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final svc = _FakeReminderService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
        appPrefsProvider.overrideWithValue(AppPrefs(sp)),
        notificationServiceProvider.overrideWithValue(svc),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RemindersScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Daily reminder'), findsOneWidget);
  });

  testWidgets('Backup screen renders Export/Import buttons', (tester) async {
    final svc = _FakeBackupService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
        backupServiceProvider.overrideWithValue(svc),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    ));
    await tester.pump();
    expect(find.text('Export to file'), findsOneWidget);
    expect(find.text('Import from file'), findsOneWidget);
  });
}

class _FakeReminderService implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<NotificationPermissionStatus> currentStatus() async =>
      NotificationPermissionStatus.granted;
  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;
  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> cancelAll() async {}
}

class _FakeBackupService implements BackupService {
  @override
  Future<(String?, Failure?)> exportAndShare() async => ('out.json', null);
  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async => (0, null);
}
