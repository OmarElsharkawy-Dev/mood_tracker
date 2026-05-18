import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../core/di/service_locator.dart';
import '../core/prefs/app_prefs.dart';
import '../features/backup/data/backup_service_provider.dart';
import '../features/reminders/data/notification_service.dart';
import '../features/reminders/domain/reminder_schedule.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await registerServices();
  await primeAppVersion();
  await GetIt.I<NotificationService>().init();

  // Re-arm any persisted reminder schedule.
  final prefs = GetIt.I<AppPrefs>();
  if (prefs.reminderEnabled) {
    final time = ReminderSchedule.parseTime(prefs.reminderTime);
    final svc = GetIt.I<NotificationService>();
    final status = await svc.currentStatus();
    if (time != null && status == NotificationPermissionStatus.granted) {
      await svc.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
        title: 'Mood Tracker',
        body: 'How are you feeling right now?',
      );
    }
  }
}
