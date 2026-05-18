abstract class NotificationService {
  /// Idempotent. Initializes platform notification channel + tz database.
  Future<void> init();

  /// Returns the current permission state.
  Future<NotificationPermissionStatus> currentStatus();

  /// Requests OS permission. Returns the post-prompt status.
  Future<NotificationPermissionStatus> requestPermission();

  /// Schedules a daily-repeating notification at the given local time.
  /// Replaces any previously scheduled reminder.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  /// Cancels every scheduled notification. Safe to call when nothing is scheduled.
  Future<void> cancelAll();
}

enum NotificationPermissionStatus { granted, denied, permanentlyDenied }
