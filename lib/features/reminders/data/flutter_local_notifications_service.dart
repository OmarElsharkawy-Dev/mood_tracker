import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

class FlutterLocalNotificationsService implements NotificationService {
  FlutterLocalNotificationsService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const int _reminderNotificationId = 0;
  static const String _androidChannelId = 'daily_reminder';
  static const String _androidChannelName = 'Daily reminder';

  @override
  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> currentStatus() async {
    final s = await Permission.notification.status;
    return _map(s);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    final s = await Permission.notification.request();
    return _map(s);
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: _reminderNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  NotificationPermissionStatus _map(PermissionStatus s) {
    if (s.isGranted) return NotificationPermissionStatus.granted;
    if (s.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    }
    return NotificationPermissionStatus.denied;
  }
}
