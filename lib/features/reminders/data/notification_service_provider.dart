import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
    (_) => getIt<NotificationService>());
