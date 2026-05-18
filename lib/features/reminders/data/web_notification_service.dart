import 'notification_service.dart';

/// No-op implementation for the web build. Browsers can't run the
/// `flutter_local_notifications` plugin, so reminders are disabled there.
class WebNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<NotificationPermissionStatus> currentStatus() async =>
      NotificationPermissionStatus.denied;

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.permanentlyDenied;

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
