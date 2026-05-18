import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/infrastructure_providers.dart';
import '../data/notification_service.dart';
import '../data/notification_service_provider.dart';
import '../domain/reminder_schedule.dart';

class ReminderController extends AsyncNotifier<ReminderSchedule> {
  @override
  Future<ReminderSchedule> build() async {
    final prefs = ref.read(appPrefsProvider);
    final enabled = prefs.reminderEnabled;
    final raw = prefs.reminderTime;
    final time = ReminderSchedule.parseTime(raw) ??
        ReminderSchedule.disabledDefault.time;
    return ReminderSchedule(enabled: enabled, time: time);
  }

  Future<void> setEnabled(bool value,
      {String title = 'Mood Tracker',
      String body = 'How are you feeling right now?'}) async {
    final current = await future;
    final svc = ref.read(notificationServiceProvider);
    final prefs = ref.read(appPrefsProvider);

    if (value) {
      final perm = await svc.requestPermission();
      if (perm != NotificationPermissionStatus.granted) {
        state = AsyncData(current.copyWith(enabled: false));
        return;
      }
      await svc.scheduleDailyReminder(
        hour: current.time.hour,
        minute: current.time.minute,
        title: title,
        body: body,
      );
      await prefs.setReminderEnabled(true);
      state = AsyncData(current.copyWith(enabled: true));
    } else {
      await svc.cancelAll();
      await prefs.setReminderEnabled(false);
      state = AsyncData(current.copyWith(enabled: false));
    }
  }

  Future<void> setTime({
    required int hour,
    required int minute,
    String title = 'Mood Tracker',
    String body = 'How are you feeling right now?',
  }) async {
    final current = await future;
    final newTime = (hour: hour, minute: minute);
    final prefs = ref.read(appPrefsProvider);
    final svc = ref.read(notificationServiceProvider);

    final updated = current.copyWith(time: newTime);
    await prefs.setReminderTime(updated.prefsString);

    if (current.enabled) {
      await svc.scheduleDailyReminder(
        hour: hour, minute: minute, title: title, body: body,
      );
    }
    state = AsyncData(updated);
  }
}

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, ReminderSchedule>(
        ReminderController.new);
