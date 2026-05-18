import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../core/di/service_locator.dart';
import '../features/reminders/data/notification_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await registerServices();
  await GetIt.I<NotificationService>().init();
}
