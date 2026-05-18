import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:mood_tracker/features/reminders/data/notification_service_provider.dart';
import 'package:mood_tracker/features/reminders/providers/reminder_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeService implements NotificationService {
  NotificationPermissionStatus next = NotificationPermissionStatus.granted;
  ({int hour, int minute})? scheduledTime;
  int cancelCalls = 0;

  @override
  Future<void> init() async {}
  @override
  Future<NotificationPermissionStatus> currentStatus() async => next;
  @override
  Future<NotificationPermissionStatus> requestPermission() async => next;
  @override
  Future<void> scheduleDailyReminder({
    required int hour, required int minute,
    required String title, required String body,
  }) async {
    scheduledTime = (hour: hour, minute: minute);
  }
  @override
  Future<void> cancelAll() async {
    cancelCalls++;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('initial state reflects defaults when prefs empty', () async {
    final svc = _FakeService();
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, false);
    expect(state.time.hour, 21);
    expect(state.time.minute, 0);
  });

  test('setEnabled(true) requests permission, schedules, persists', () async {
    final svc = _FakeService();
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setEnabled(true);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, true);
    expect(svc.scheduledTime, (hour: 21, minute: 0));
    expect(AppPrefs(sp).reminderEnabled, true);
  });

  test('setEnabled(true) with denied permission leaves state OFF', () async {
    final svc = _FakeService()..next = NotificationPermissionStatus.denied;
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setEnabled(true);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, false);
    expect(svc.scheduledTime, isNull);
  });

  test('setEnabled(false) cancels and persists', () async {
    SharedPreferences.setMockInitialValues({
      'app.reminderEnabled': true,
      'app.reminderTime': '08:30',
    });
    final svc = _FakeService();
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setEnabled(false);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, false);
    expect(svc.cancelCalls, greaterThanOrEqualTo(1));
    expect(AppPrefs(sp).reminderEnabled, false);
  });

  test('setTime updates schedule when enabled, just persists when disabled', () async {
    final svc = _FakeService();
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setTime(hour: 8, minute: 30);
    expect(svc.scheduledTime, isNull);
    expect(AppPrefs(sp).reminderTime, '08:30');

    await c.read(reminderControllerProvider.notifier).setEnabled(true);
    await c.read(reminderControllerProvider.notifier).setTime(hour: 9, minute: 0);
    expect(svc.scheduledTime, (hour: 9, minute: 0));
  });
}
