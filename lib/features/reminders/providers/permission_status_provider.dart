import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_service.dart';
import '../data/notification_service_provider.dart';

final permissionStatusProvider =
    FutureProvider<NotificationPermissionStatus>((ref) async {
  final svc = ref.watch(notificationServiceProvider);
  return svc.currentStatus();
});
