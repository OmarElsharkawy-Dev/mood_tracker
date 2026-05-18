import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(() => tzdata.initializeTimeZones());

  test('init() is idempotent', () async {
    final plugin = _FakePlugin();
    final svc = FlutterLocalNotificationsService(plugin);
    await svc.init();
    await svc.init();
    expect(plugin.initializeCallCount, lessThanOrEqualTo(2));
  });

  test(
    'scheduleDailyReminder calls zonedSchedule with channel id and time component',
    () async {
      final plugin = _FakePlugin();
      final svc = FlutterLocalNotificationsService(plugin);
      await svc.init();
      await svc.scheduleDailyReminder(
        hour: 21,
        minute: 0,
        title: 'T',
        body: 'B',
      );
      expect(plugin.lastZonedSchedule, isNotNull);
      expect(plugin.lastZonedSchedule!.id, 0);
      expect(plugin.lastZonedSchedule!.title, 'T');
      expect(
        plugin.lastZonedSchedule!.matchDateTimeComponents,
        DateTimeComponents.time,
      );
      expect(
        plugin.lastZonedSchedule!.notificationDetails.android?.channelId,
        'daily_reminder',
      );
    },
  );

  test('cancelAll forwards to plugin', () async {
    final plugin = _FakePlugin();
    final svc = FlutterLocalNotificationsService(plugin);
    await svc.init();
    await svc.cancelAll();
    expect(plugin.cancelAllCallCount, 1);
  });
}

// ---------------------------------------------------------------------------
// Fake plugin — implements the concrete class via noSuchMethod.
// In 21.x, zonedSchedule uses ALL named parameters (no positional args).
// ---------------------------------------------------------------------------
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  int initializeCallCount = 0;
  int cancelAllCallCount = 0;
  _ZonedScheduleCall? lastZonedSchedule;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #initialize) {
      initializeCallCount++;
      return Future<bool?>.value(true);
    }
    if (name == #cancelAll) {
      cancelAllCallCount++;
      return Future<void>.value();
    }
    if (name == #zonedSchedule) {
      // 21.x: all args are named.
      final named = invocation.namedArguments;
      lastZonedSchedule = _ZonedScheduleCall(
        id: named[#id] as int,
        title: named[#title] as String?,
        body: named[#body] as String?,
        notificationDetails: named[#notificationDetails] as NotificationDetails,
        matchDateTimeComponents:
            named[#matchDateTimeComponents] as DateTimeComponents?,
      );
      return Future<void>.value();
    }
    // Default for resolvePlatformSpecificImplementation and other calls.
    return null;
  }
}

class _ZonedScheduleCall {
  _ZonedScheduleCall({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationDetails,
    required this.matchDateTimeComponents,
  });
  final int id;
  final String? title;
  final String? body;
  final NotificationDetails notificationDetails;
  final DateTimeComponents? matchDateTimeComponents;
}
