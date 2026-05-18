import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/reminders/data/notification_service.dart';
import '../db/app_database.dart';
import '../prefs/app_prefs.dart';

final getIt = GetIt.instance;

Future<void> registerServices() async {
  final sp = await SharedPreferences.getInstance();
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  getIt
    ..registerSingleton<SharedPreferences>(sp)
    ..registerSingleton<AppPrefs>(AppPrefs(sp))
    ..registerSingleton<AppDatabase>(AppDatabase())
    ..registerSingleton<NotificationService>(
      FlutterLocalNotificationsService(notificationsPlugin),
    );
}
