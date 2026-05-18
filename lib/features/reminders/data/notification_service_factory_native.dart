import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'flutter_local_notifications_service.dart';
import 'notification_service.dart';

NotificationService createNotificationService() {
  return FlutterLocalNotificationsService(FlutterLocalNotificationsPlugin());
}
