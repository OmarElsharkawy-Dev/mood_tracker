import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:mood_tracker/features/reminders/data/notification_service_provider.dart';
import 'package:mood_tracker/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GrantingService implements NotificationService {
  ({int hour, int minute})? scheduled;
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
  }) async {
    scheduled = (hour: hour, minute: minute);
  }

  @override
  Future<void> cancelAll() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders title + enabled switch + time tile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final svc = _GrantingService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
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
    expect(find.text('Reminders'), findsWidgets);
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
  });

  testWidgets('toggling switch to ON triggers scheduling', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final svc = _GrantingService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
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
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(svc.scheduled, (hour: 21, minute: 0));
  });
}
