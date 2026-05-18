import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/reminders/data/notification_service.dart';
import '../../features/reminders/data/notification_service_factory.dart';
import '../db/app_database.dart';
import '../prefs/app_prefs.dart';

final getIt = GetIt.instance;

Future<void> registerServices() async {
  final sp = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<SharedPreferences>(sp)
    ..registerSingleton<AppPrefs>(AppPrefs(sp))
    ..registerSingleton<AppDatabase>(AppDatabase())
    ..registerSingleton<NotificationService>(createNotificationService());
}
